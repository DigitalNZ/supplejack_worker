# frozen_string_literal: true
if ENV['AWS_KEY'] && ENV['AWS_SECRET']
  s3 = Aws::S3::Resource.new(region: 'ap-southeast-2', access_key_id: ENV['AWS_KEY'], secret_access_key: ENV['AWS_SECRET'])
else
  Rails.logger.debug 'The AWS_KEY and AWS_SECRET ENV Variables have not been set'
end
