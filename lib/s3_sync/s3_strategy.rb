# -*- encoding: utf-8 -*-

#require 's3_sync/aclmanager'
#require 's3_sync/file_manager'

module S3Sync
  class S3Strategy
    def check
      instance_variables.each{|method| puts "#{method} : #{instance_variable_get(method.to_sym).to_s}" }
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
    def initialize(bucket_name, setting)
      @is_ready = false
      #コピー元バケットの取得・存在確認
      @from_manager = S3Manager.new(bucket_name, setting)
      #コピー元ディレクトリの確認
      abort 'バケットが存在しません'unless @from_manager.existance
      #コピー先ディレクトリの設定・確認・作成
      ftimestamp_dir_name = Time.now.strftime("%Y%m%d%H%M%S")
      unique_bkup_base_dir = File.join([setting['AWS_BKUP_DIR'], bucket_name, ftimestamp_dir_name], '')
      unique_bkup_acl_setting_dir = unique_bkup_base_dir
      unique_bkup_data_dir = File.join([unique_bkup_acl_setting_dir, 'data'], '')
      aclm = AclManager.get_instance(unique_bkup_acl_setting_dir)
      @to_manager = FileManager.new(unique_bkup_data_dir, aclm)
      abort 'コピー先が既に存在します' if @to_manager.existance
      @is_ready = true
    end
    def execute
      abort '実行できません。設定を確認してください' unless @is_ready
      copy
    end
  end

  class UploadStrategy < S3Strategy
    def initialize(bucket_name, bucket_name_to, timestamp, setting)
      @is_ready = false
      #セットアップ
      abort 'bucket_name,timestampを指定してください' if bucket_name == nil or timestamp == nil
      ftimestamp_dir_name = timestamp
      unique_bkup_base_dir = File.join([setting['AWS_BKUP_DIR'], bucket_name, ftimestamp_dir_name], '')
      unique_bkup_acl_setting_dir = unique_bkup_base_dir
      unique_bkup_data_dir = File.join([unique_bkup_acl_setting_dir, 'data'], '')
      #aclのセットアップ
      aclm = AclManager.get_instance(unique_bkup_acl_setting_dir)
      @from_manager = FileManager.new(unique_bkup_data_dir, aclm)
      #コピー元ディレクトリの確認
      abort 'コピー元がありません' unless @from_manager.existance
      @to_manager = S3Manager.new(bucket_name_to, setting)
      #コピー先ディレクトリの確認
      abort 'コピー先が既に存在します' if @to_manager.existance
      @is_ready = true
    end
    def execute
      abort '実行できません。設定を確認してください' unless @is_ready
      copy
    end
  end

  class CopyStrategy < S3Strategy
    def initialize(bucket_name_from, bucket_name_to, setting)
      @is_ready = false
      abort 'bucket_name_from,bucket_name_toを指定してください' if bucket_name_from == nil or bucket_name_to == nil
      #セットアップ
      @from_manager = S3Manager.new(bucket_name_from, setting)
      #コピー元ディレクトリの確認
      abort 'バケットが存在しません.処理を中断します' unless @from_manager.existance
      @to_manager = S3Manager.new(bucket_name_to, setting)
      #コピー先ディレクトリの確認
      abort '既にバケットが存在します.処理を中断します' if @to_manager.existance
      @is_ready = true
    end
    def execute
      abort '実行できません。設定を確認してください' unless @is_ready
      copy
    end
  end

  class RemoveStrategy < S3Strategy
    def initialize(bucket_name, setting)
      @bucket_name = bucket_name
      @is_ready = false
      abort 'bucket_nameを指定してください' if bucket_name == nil
      @from_manager = S3Manager.new(bucket_name, setting)
      abort 'バケットが存在しません.処理を中断します' unless @from_manager.existance
      @is_ready = true
    end
    def execute
      abort '実行できません。設定を確認してください' unless @is_ready
      @from_manager.delete
      puts "#{@bucket_name}を削除しました"
    end
  end
end
