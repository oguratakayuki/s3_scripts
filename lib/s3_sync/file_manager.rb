# coding: utf-8

module S3Sync
  class FileManager
    attr_reader :existance
    def to_s
      instance_variables.each{|method| puts "FileManager\t#{method} : #{instance_variable_get(method.to_sym).to_s}" }
    end
    def initialize(base_path, aclm=nil)
      @base_path = base_path
      @item_list = Hash.new()
      @existance = Dir.exist?(@base_path)
      @aclm = aclm

      if @existance
        Dir.chdir(@base_path) do
          Dir.glob('**/*') do |file_key|
           @item_list[file_key] = FileItem.new(@base_path, file_key, aclm)
          end
        end
      end
    end
    def create_base
      abort "既に#{@base_path}は存在します" if @existance
      FileUtils.mkdir_p(@base_path)
      @existance = true
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
        abort "#{absolute_dir_path}は既に存在します"
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

  class S3Manager
    attr_reader :existance
    def to_s
      instance_variables.each{|method| puts "S3Manager\t#{method} : #{instance_variable_get(method.to_sym).to_s}" }
    end

    def initialize(bucket_name, setting)
      @s3 = AWS::S3.new(
        :access_key_id     => setting['AWS_ACCESS_KEY_ID'],
        :secret_access_key => setting['AWS_SECRET_ACCESS_KEY'],
        :s3_endpoint       => setting['AWS_END_POINT']
      )
      @bucket_name = bucket_name
      @item_list = Hash.new()
      @existance =  @s3.buckets[@bucket_name].client.list_buckets.first.to_ary[1].select{|temp| temp[:name] == @bucket_name}.count == 0 ? false : true 
      if @existance
        @bucket = @s3.buckets[@bucket_name]
        @bucket.objects.each do |s3obj|
          @item_list[s3obj.key] = S3Item.new(s3obj.key, s3obj)
        end
      end
    end

    def create_base
      abort "既に#{@bucket_name}は存在します"if @existance
      @bucket = @s3.buckets.create(@bucket_name)
      @existance = true
    end
    def delete
      if @existance
        @bucket.clear!
        @bucket.delete
        @existance = false
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
