# S3Sync

s3_syncはローカルストレージとaws/s3のバケットの同期ツールです



## Installation

set environmental variable

     export AWS_ACCESS_KEY_ID=''

     export AWS_SECRET_ACCESS_KEY=''

     export AWS_END_POINT=''

     export AWS_BKUP_DIR=''

Add this line to your application's Gemfile:

    gem 's3_sync',                :git => 'git@github.com:oguratakayuki/s3_scripts.git', :branch => 'master'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3_sync

## Usage

     buncle exec s3_sync copy BUCKET_NAME_COPY_FROM BUCKET_NAME_COPY_TO             # copy s3 bucket

     s3_sync download BUCKET_NAME_TO_DOWNLOAD                                       # download aws/s3 data to localstrage

     s3_sync help [COMMAND]                                                         # Describe available commands or one specific command

     s3_sync interactive                                                            # use interactive interface for upload,download,copy,remove s3 data
     
     s3_sync remove BUCKET_NAME_TO_REMOVE                                           # remove s3 bucket

     s3_sync upload BUCKET_NAME_TO_UPLOAD TIMESTAMP [--nb NEW_BUCKET_NAME_TO_COPY]  # upload localstrage data to s3




## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
