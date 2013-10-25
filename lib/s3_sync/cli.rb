# -*- encoding: utf-8 -*-
#! /usr/bin/env ruby

module S3Sync
  module AwsSetting
    def get_setting
      setting = {}
      setting.tap do |h|
        %w(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_END_POINT AWS_BKUP_DIR).each do |key|
          abort "環境変数#{key}が設定されていません" unless ENV[key]
          h[key] = ENV[key]
        end
      end
    end
  end
  class CLI < Thor
    include S3Sync::AwsSetting
    desc "assert strategy", ''
    def assert strategy
      begin
      setting = get_setting
      strategy = CopyStrategy.new('ogura-test','ogura-test2', setting)
      rescue S3Strategy::DataNotFound, S3Strategy::DataAlreadyExists, S3Strategy::InvalidParameter=>e
        puts e.class.to_s
        puts e.message
        exit
      end
    end
    desc "download BUCKET_NAME", ""
    def download bucket_name
      begin
        setting = get_setting
        strategy = DownloadStrategy.new(bucket_name, setting)
        strategy.execute
      rescue S3Strategy::DataNotFound, S3Strategy::InvalidDataIdentification, AclManager::FileNotFound =>e
        puts e.message
        exit
      end
    end
    desc "list LOCAL_OR_S3 [-b BUCKET_NAME]", ""
    method_options b: :string
    def list(local_or_s3)
      setting = get_setting
      if local_or_s3 == 'local'
        bucket_name = options[:b]
        bucket_list_data = FileAggregator.list(setting['AWS_BKUP_DIR'], bucket_name)
        bucket_list_data.each do |key,value|
          puts "local buckets:#{key}"
          puts "timestamp:"
          value.each_slice(10){|timestamp_list|  timestamp_list.each{|timestamp| print "#{timestamp}\t"}.tap{|t| puts "\n"}}
        end
      elsif local_or_s3 == 's3'
        bucket_name_list = S3Aggregator.bucket_name_list(setting)
        puts "s3 buckets:"
        puts bucket_name_list
      else
        abort 'please choose s3 or local'
      end
    end
    desc "upload BUCKET_NAME TIMESTAMP [--nb NEW_BUCKET_NAME]", ""
    method_options nb: :string
    def upload(bucket_name, timestamp)
      begin
        setting = get_setting
        bucket_name_to = options[:nb] ?  options[:nb] : bucket_name
        strategy = UploadStrategy.new(bucket_name, bucket_name_to, timestamp, setting)
        strategy.execute
      rescue S3Strategy::InvalidParameter, S3Strategy::DataNotFound, S3Strategy::DataAlreadyExists, AclManager::FileNotFound => e
        puts e.message
        exit
      end
    end

    desc "copy FROM_BUCKET_NAME TO_BUCKET_NAME", ""
    def copy(bucket_name_from, bucket_name_to)
      begin
        setting = get_setting
        strategy = CopyStrategy.new(bucket_name_from, bucket_name_to, setting)
        strategy.execute
      rescue S3Strategy::InvalidParameter, S3Strategy::DataNotFound, S3Strategy::DataAlreadyExists => e
        puts e.message
        exit
      end
    end

    desc "remove BUCKET_NAME", ""
    def remove(bucket_name)
      begin
        setting = get_setting
        strategy = RemoveStrategy.new(bucket_name, setting)
        strategy.execute
      rescue S3Strategy::InvalidParameter, S3Strategy::DataNotFound => e
        puts e.message
        exit
      end
    end

    desc "interactive", ""
    def interactive
      setting = get_setting
      #bkupディレクトリ確認
      abort "bkup用ディレクトリの#{setting['AWS_BKUP_DIR']}がありません" if Dir.exists?(setting['AWS_BKUP_DIR']) == false
      puts "以下からアクションを選択してください"
      puts "1:s3バケットをローカルストレージにダウンロード"
      puts "2:ローカルストレージからs3バケットを作成"
      puts "3:s3バケットのコピー"
      puts "4:s3バケット削除"
      print '>>'
      action_id = STDIN.gets.strip.to_i
      abort '入力値が不正です' unless [1,2,3,4].member?(action_id)
      begin
        if action_id == 1
          strategy = DownloadStrategy.initialize_with_cli(setting)
        elsif action_id == 2
          strategy = UploadStrategy.initialize_with_cli(setting)
        elsif action_id == 3
          strategy = CopyStrategy.initialize_with_cli(setting)
        elsif action_id == 4
          strategy = RemoveStrategy.initialize_with_cli(setting)
        else
          abort '入力値が不正です'
        end
        strategy.execute
      rescue S3Strategy::InvalidParameter, S3Strategy::DataNotFound, S3Strategy::DataAlreadyExists => e
        puts e.message
        exit
      end
    end
  end
end

