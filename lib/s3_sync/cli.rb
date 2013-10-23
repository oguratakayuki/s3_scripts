# -*- encoding: utf-8 -*-
#! /usr/bin/env ruby
#
#require 'rubygems'
require 'thor'
require 's3_sync/s3_strategy'
require 's3_sync/file_manager'
require 's3_sync/acl_manager'
require 'aws-sdk'

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
    desc "download BUCKET_NAME", ""
    def download bucket_name
      setting = get_setting
      strategy = DownloadStrategy.new(bucket_name, setting)
      strategy.execute
    end
    desc "list LOCAL_OR_S3 [--b BUCKET_NAME]"
    method_options b: :string
    def list(local_or_s3)
      setting = get_setting
      if local_or_s3 == 'local'
        bucket_name = options[:b]
        bucket_list_data = FileManager.list(setting['AWS_BKUP_DIR'], bucket_name)
        p bucket_list_data
      else
        @from_manager = S3Manager.new(bucket_name, setting)
      end
    end
    desc "upload BUCKET_NAME TIMESTAMP [--nb NEW_BUCKET_NAME]", ""
    method_options nb: :string
    def upload(bucket_name, timestamp)
      setting = get_setting
      bucket_name_to = options[:nb] ?  options[:nb] : bucket_name
      strategy = UploadStrategy.new(bucket_name, bucket_name_to, timestamp, setting)
      strategy.execute
    end

    desc "copy FROM_BUCKET_NAME TO_BUCKET_NAME", ""
    def copy(bucket_name_from, bucket_name_to)
      setting = get_setting
      strategy = CopyStrategy.new(bucket_name_from, bucket_name_to, setting)
      strategy.execute
    end

    desc "remove BUCKET_NAME", ""
    def remove(bucket_name)
      setting = get_setting
      strategy = RemoveStrategy.new(bucket_name, setting)
      strategy.execute
    end

    desc "interactive", ""
    def interactive
      setting = get_setting
      #bkupディレクトリ確認
      abort "bkup用ディレクトリの#{setting['AWS_BKUP_DIR']}がありません" if Dir.exists?(setting['AWS_BKUP_DIR']) == false
      puts "以下からアクションを選択してください"
      puts "1:s3バケットをローカルストレージにダウンロード"
      puts "2:ローカルストレージからs3バケットを作成"
      puts "3:s3バケットの移動、コピー"
      puts "4:s3バケット削除"
      print '>>'
      action_id = STDIN.gets.strip.to_i
      abort '入力値が不正です'unless [1,2,3,4].member?(action_id)
      if action_id == 1
        #コピー元バケットの取得・存在確認
        print 'バケット名を入力してください>>'
        bucket_name = STDIN.gets.strip
      elsif action_id == 2
        #コピー元ディレクトリの確認
        print 'コピー元のバケット名を入力してください>>'
        bucket_name = STDIN.gets.strip
        candidate_directory_path = File.join([setting['AWS_BKUP_DIR'], bucket_name],'*')
        candidate_directory_list = Dir.glob(candidate_directory_path).map{|dir| dir.match(%r!.*/(.*)$!)[1]}
        puts 'タイムスタンプを入力してください'
        puts "候補: #{candidate_directory_list.join(' ')}"
        print ">>"
        timestamp = STDIN.gets.strip
        print "コピー先バケット名を#{bucket_name}から変更しますか?(Y/n)>>"
        bucket_name_change = STDIN.gets.strip
        if bucket_name_change == 'Y'
          print '新しいバケット名を入力してください>>'
          bucket_name_to = STDIN.gets.strip
          abort 'バケット名が不正です' unless bucket_name_to
        elsif  bucket_name_change == 'n'
          bucket_name_to =  bucket_name
        else
          abort '入力値が不正です'
        end
      elsif action_id == 3
        print 'コピー元のバケット名を入力してください>>'
        bucket_name_from = STDIN.gets.strip
        print 'コピー先のバケット名を入力してください>>'
        bucket_name_to = STDIN.gets.strip
      elsif action_id == 4
        print '削除対象のバケット名を入力してください>>'
        bucket_name = STDIN.gets.strip
      end
      strategy =
        case action_id
          when 1
            DownloadStrategy.new(bucket_name, setting)
          when 2
            UploadStrategy.new(bucket_name, bucket_name_to, timestamp, setting)
          when 3
            CopyStrategy.new(bucket_name_from, bucket_name_to, setting)
          when 4
            RemoveStrategy.new(bucket_name, setting)
          else
            abort
          end
      strategy.execute
    end
  end
end

