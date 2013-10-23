# -*- encoding: utf-8 -*-
# #! /usr/bin/ruby
require 'yaml'

module S3Sync
  class AclManager
    private_class_method :new
    @@instance = nil
    def finalize
      Proc.new do
        save if @changed == true
      end
    end
    def to_s
      instance_variables.each{|method| puts "AclManager\t#{method} : #{instance_variable_get(method.to_sym).to_s}" unless method == '@data' }
    end

    def self.get_instance(unique_bkup_dir)
      @@instance = new(unique_bkup_dir) unless @@instance
      #private_class_method :new
      @@instance
    end
    def initialize(unique_bkup_dir)
      ObjectSpace.define_finalizer(self, self.finalize)
      @unique_bkup_dir = unique_bkup_dir
      @acl_file_path = File.join(@unique_bkup_dir, 'acl_settings')
      @data = {}
      @is_new = !File.exists?(@acl_file_path)
      unless @is_new
        self.load
      end
      @changed = false
    end
    def check_settings
      if Dir.exists?(@unique_bkup_dir) == false
        puts 'aclファイルの保存パスをsetting.ymlのbkup_dirで指定してください'
        abort
      end
    end
    def add(key,permission)
      @data[key] = permission
      @changed = true
    end
    def get(key)
      @data[key]
    end
    def has_key?(key)
      @data.has_key?(key)
    end
    def has_permission?(key)
      #user,permission
    end
    def save
      File.open(@acl_file_path,'w+') do |file|
        Marshal.dump(@data,file)
      end
    end
    def load
      unless File.exists?(@acl_file_path)
        puts @acl_file_path
        puts 'aclファイルがありません: YYYYmmddHHMMSS'
        abort
      end
      File.open(@acl_file_path) do |file|
        @data = Marshal.load(file)
      end
    end
  end
end
