# coding: utf-8

module S3Sync
  class FileAggregator
    class DirectoryAlreadyExists < StandardError; end
    attr_reader :existence
    def self.list(base_path, bucket_name)
      existence = Dir.exist?(base_path)
      if existence
        ret = {}
        Dir.chdir(base_path) do
          if bucket_name
            bucket_name_list = [bucket_name]
          else
            bucket_name_list = self.bucket_name_list(base_path)
          end
          bucket_name_list.each do |bucket_name|
            if Dir.exist?(File.join([base_path, bucket_name],''))
              bucket_timestamp_list = Dir.glob("#{bucket_name}/*").map{|t| t.match(%r!.*/(.*)$!)[1] }
              ret[bucket_name] = bucket_timestamp_list
            end
          end
        end
        ret
      end
    end
    def self.bucket_name_list(base_path)
      bucket_name_list = []
      existence = Dir.exist?(base_path)
      if existence
        Dir.chdir(base_path) do
          bucket_name_list = Dir.glob('*')
        end
      end
      bucket_name_list
    end
    def to_s
      instance_variables.each{|method| puts "FileAggregator\t#{method} : #{instance_variable_get(method.to_sym).to_s}" }
    end
    def initialize(base_path, aclm=nil)
      @base_path = base_path
      @item_list = Hash.new()
      @existence = Dir.exist?(@base_path)
      @aclm = aclm

      if @existence
        Dir.chdir(@base_path) do
          Dir.glob('**/*') do |file_key|
           @item_list[file_key] = FileItem.new(@base_path, file_key, aclm)
          end
        end
      end
    end
    def create_base
      raise DirectoryAlreadyExists, "既に#{@base_path}は存在します" if @existence
      FileUtils.mkdir_p(@base_path)
      @existence = true
    end
    def each_item_with_key
      @item_list.each do |path,fileitem|
        yield fileitem, path
      end
    end
    def get_by_key(key)
      @item_list[key]
    end
    def create_item_by_key(file_key)
      @item_list[file_key] = FileItem.new(@base_path, file_key, @aclm)
      @item_list[file_key]
    end
    def create_dir(dir_path)
      absolute_dir_path = File.join([@base_path, dir_path],'')
      if Dir.exist?(absolute_dir_path)
        raise DirectoryAlreadyExists, "#{absolute_dir_path}は既に存在します"
      end
      Dir.mkdir(absolute_dir_path)
    end
  end

  class FileItem
    attr_reader :key, :file_absolute_key
    def initialize(base_path, file_key, aclm=nil)
      @file_absolute_key = File.join(base_path, file_key)
      @key = file_key
      @aclm = aclm
    end
    def read
      File.open(@file_absolute_key, "rb") {|f| f.read }
    end
    def write(item)
      File.open(@file_absolute_key, "wb") {|f| f.write item.read}
      write_acl(item.read_acl) if @aclm
    end
    def read_acl
      @aclm.get(@key)
    end
    def write_acl(acl)
      @aclm.add(@key, acl)
    end
    def is_dir?
      File.directory?(@file_absolute_key)
    end
    def is_file?
      File.file?(@file_absolute_key)
    end
  end

  class S3Aggregator
    attr_reader :existence
    def to_s
      instance_variables.each{|method| puts "S3Aggregator\t#{method} : #{instance_variable_get(method.to_sym).to_s}" }
    end
    def self.bucket_name_list(setting)
      s3 = AWS::S3.new(
        :access_key_id     => setting['AWS_ACCESS_KEY_ID'],
        :secret_access_key => setting['AWS_SECRET_ACCESS_KEY'],
        :s3_endpoint       => setting['AWS_END_POINT']
      )
      ret = s3.buckets.client.list_buckets.first.to_ary[1].map{|temp| temp[:name]}
    end

    def initialize(bucket_name, setting)
      @s3 = AWS::S3.new(
        :access_key_id     => setting['AWS_ACCESS_KEY_ID'],
        :secret_access_key => setting['AWS_SECRET_ACCESS_KEY'],
        :s3_endpoint       => setting['AWS_END_POINT']
      )
      @bucket_name = bucket_name
      @item_list = Hash.new()
      @existence =  @s3.buckets[@bucket_name].client.list_buckets.first.to_ary[1].select{|temp| temp[:name] == @bucket_name}.count == 0 ? false : true
      if @existence
        @bucket = @s3.buckets[@bucket_name]
        @bucket.objects.each do |s3obj|
          @item_list[s3obj.key] = S3Item.new(s3obj.key, s3obj)
        end
      end
    end
    def create_base
      raise DirectoryAlreadyExists, "既に#{@bucket_name}は存在します" if @existence
      @bucket = @s3.buckets.create(@bucket_name)
      @existence = true
    end
    def delete
      if @existence
        @bucket.clear!
        @bucket.delete
        @existence = false
      end
    end
    def get_by_key(key)
      @item_list[key]
    end

    def create_item_by_key(key)
      s3obj = @bucket.objects[key]
      @item_list[key] = S3Item.new(s3obj.key, s3obj)
      @item_list[key]
    end

    def create_dir(key)
      @bucket.objects[File.join(key,'')].write('')
    end

    def each_item_with_key
      @item_list.each do |path,item|
        yield item, path
      end
    end
  end
  class S3Item
    attr_reader :key, :file_absolute_key
    def initialize(key, s3obj)
      @key = key
      @file_absolute_key = key
      @obj = s3obj
    end
    def read
      @obj.read
    end
    def write(item)
      @obj.write(item.read)
      write_acl(item.read_acl)
    end
    def read_acl
      @obj.acl.to_xml
    end
    def write_acl(acl)
      @obj.acl = acl
    end
    def is_dir?
      @key.match(%r!.*/$!)
    end
    def is_file?
      !@key.match(%r!.*/$!)
    end
  end
end

