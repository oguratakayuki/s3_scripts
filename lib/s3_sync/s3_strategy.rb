# -*- encoding: utf-8 -*-

#require 's3_sync/aclmanager'
#require 's3_sync/file_manager'

module S3Sync
  class S3Strategy
    class InvalidParameter < StandardError; end
    class DataNotFound < StandardError; end
    class DataAlreadyExists < StandardError; end
    class InvalidDataIdentification < StandardError; end
    def check
      instance_variables.each{|method| puts "#{method} : #{instance_variable_get(method.to_sym).to_s}" }
    end
    protected
    def setup_bkup_path(bucket_name, timestamp, setting)
      ftimestamp_dir_name = timestamp
      unique_bkup_base_dir = File.join([setting['AWS_BKUP_DIR'], bucket_name, ftimestamp_dir_name], '')
      @unique_bkup_acl_setting_dir = unique_bkup_base_dir
      @unique_bkup_data_dir = File.join([@unique_bkup_acl_setting_dir, 'data'], '')
    end
    protected
    def copy
      @to_manager.create_base
      start_time = Time.now
      create_dir_count = 0
      create_file_count = 0
      @from_manager.each_item_with_key do |from_item, path|
        if from_item.is_dir?
          @to_manager.create_dir(from_item.key)
          puts "create dir: #{from_item.key}"
          create_dir_count += 1
        else
          to_item = @to_manager.create_item_by_key(from_item.key)
          to_item.write(from_item)
          puts "create file: #{from_item.file_absolute_key}"
          create_file_count += 1
        end
      end
      end_time = Time.now
      puts "it costs #{(end_time-start_time).round} second"
      puts "#{create_dir_count} directories are created"
      puts "#{create_file_count} files are created"
      puts "copy完了しました"
    end
  end

  class DownloadStrategy < S3Strategy
    def self.initialize_with_cli(setting)
      #コピー元バケットの取得・存在確認
      bucket_name_candidate_list = S3Aggregator.bucket_name_list(setting)
      puts 'バケット名を入力してください'
      puts "候補:\n#{bucket_name_candidate_list.join("\n")}"
      print '>>'
      bucket_name = STDIN.gets.strip
      self.new(bucket_name,setting)
    end
    def initialize(bucket_name, setting)
      raise S3Strategy::InvalidParameter, 'bucket_nameを指定してください' if bucket_name == '' or setting == nil
      #コピー元バケットの取得・存在確認
      @from_manager = S3Aggregator.new(bucket_name, setting)
      #コピー元ディレクトリの確認
      raise S3Sync::S3Strategy::DataNotFound, 'バケットが存在しません' unless @from_manager.existence
      #コピー先ディレクトリの設定・確認・作成
      setup_bkup_path(bucket_name, Time.now.strftime("%Y%m%d%H%M%S"), setting)
      aclm = AclAggregator.get_instance(@unique_bkup_acl_setting_dir)
      @to_manager = FileAggregator.new(@unique_bkup_data_dir, aclm)
      raise DataAlreadyExists, 'コピー先が既に存在します' if @to_manager.existence
    end
    def execute
      copy
    end
  end

  class UploadStrategy < S3Strategy
    def self.initialize_with_cli(setting)
      candidate_bucket_list = Dir.glob("#{setting['AWS_BKUP_DIR']}/*").map{|dir| dir.match(%r!.*/(.*)$!)[1]}
      puts 'コピー元のバケット名を入力してください'
      puts "候補:\n#{candidate_bucket_list.join("\n")}"
      print '>>'
      bucket_name = STDIN.gets.strip
      raise DataNotFound, 'バケット名が不正です' unless candidate_bucket_list.include?(bucket_name)
      candidate_directory_path = File.join([setting['AWS_BKUP_DIR'], bucket_name],'*')
      candidate_directory_list = Dir.glob(candidate_directory_path).map{|dir| dir.match(%r!.*/(.*)$!)[1]}
      puts 'タイムスタンプを入力してください'
      puts "候補:"
      puts candidate_directory_list.each_slice(10){|timestamp_list|  timestamp_list.each{|timestamp| print "#{timestamp}\t"}.tap{|t| puts "\n"}}
      print ">>"
      timestamp = STDIN.gets.strip
      raise DataNotFound, 'タイムスタンプが不正です' unless candidate_directory_list.include?(timestamp)
      print "コピー先バケット名を#{bucket_name}から変更しますか?(Y/n)>>"
      bucket_name_change = STDIN.gets.strip
      if bucket_name_change == 'Y'
        print '新しいバケット名を入力してください>>'
        bucket_name_to = STDIN.gets.strip
        raise InvalidParameter, 'バケット名が不正です' if bucket_name_to == ''
      elsif  bucket_name_change == 'n'
        bucket_name_to =  bucket_name
      else
        raise InvalidParameter, '入力値が不正です'
      end
      self.new(bucket_name, bucket_name_to, timestamp, setting)
    end
    def initialize(bucket_name, bucket_name_to, timestamp, setting)
      #セットアップ
      raise InvalidParameter, 'bucket_name,bucket_name_to,timestampを指定してください' if bucket_name == '' or bucket_name == '' or timestamp == ''
      setup_bkup_path(bucket_name, timestamp, setting)
      #aclのセットアップ
      aclm = AclAggregator.get_instance(@unique_bkup_acl_setting_dir)
      @from_manager = FileAggregator.new(@unique_bkup_data_dir, aclm)
      #コピー元ディレクトリの確認
      raise DataNotFound,  'コピー元がありません' unless @from_manager.existence
      @to_manager = S3Aggregator.new(bucket_name_to, setting)
      #コピー先ディレクトリの確認
      raise DataAlreadyExists, 'コピー先が既に存在します' if @to_manager.existence
    end
    def execute
      copy
    end
  end

  class CopyStrategy < S3Strategy
    def self.initialize_with_cli(setting)
      candidate_bucket_list = S3Aggregator.bucket_name_list(setting)
      puts 'コピー元のバケット名を入力してください'
      puts "候補:\n#{candidate_bucket_list.join("\n")}"
      print ">>"
      bucket_name_from = STDIN.gets.strip
      raise DataNotFound, 'バケット名が不正です' unless candidate_bucket_list.include?(bucket_name_from)
      print 'コピー先のバケット名を入力してください>>'
      print '>>'
      bucket_name_to = STDIN.gets.strip
      raise InvalidParameter, 'バケット名が不正です' if bucket_name_to == ''
      self.new(bucket_name_from, bucket_name_to, setting)
    end
    def initialize(bucket_name_from, bucket_name_to, setting)
      raise S3Strategy::InvalidParameter, 'bucket_name_from,bucket_name_toを指定してください' if bucket_name_from == '' or bucket_name_to == ''
      #セットアップ
      @from_manager = S3Aggregator.new(bucket_name_from, setting)
      #コピー元ディレクトリの確認
      raise DataNotFound, 'バケットが存在しません.処理を中断します' unless @from_manager.existence
      @to_manager = S3Aggregator.new(bucket_name_to, setting)
      #コピー先ディレクトリの確認
      raise DataAlreadyExists,  '既にバケットが存在します.処理を中断します' if @to_manager.existence
    end
    def execute
      copy
    end
  end

  class RemoveStrategy < S3Strategy
    def self.initialize_with_cli(setting)
      candidate_bucket_list = S3Aggregator.bucket_name_list(setting)
      puts '削除対象のバケット名を入力してください'
      puts "候補:\n#{candidate_bucket_list.join("\n")}"
      print '>>'
      bucket_name = STDIN.gets.strip
      raise DataNotFound, 'バケット名が不正です' unless candidate_bucket_list.include?(bucket_name)
      self.new(bucket_name, setting)
    end
    def initialize(bucket_name, setting)
      @bucket_name = bucket_name
      raise S3Strategy::InvalidParameter, 'bucket_nameを指定してください' if bucket_name == nil
      @from_manager = S3Aggregator.new(bucket_name, setting)
      raise DataNotFound, 'バケットが存在しません.処理を中断します' unless @from_manager.existence
    end
    def execute
      @from_manager.delete
      puts "#{@bucket_name}を削除しました"
    end
  end
end
