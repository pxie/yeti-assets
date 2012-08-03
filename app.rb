require 'sinatra'
require 'json'
require 'mongo'
require 'uri'
require 'aws/s3'
require 'sinatra/streaming'

get '/env' do
  ENV['VMC_SERVICES']
end

get '/' do
  'hello from sinatra - get v0.8<br>fix memory leak'
end

get '/list' do
  load_vblob
  list_objs
end

get '/files/:key' do
  load_vblob
  stream do |out|
    out.puts AWS::S3::S3Object.value(params[:key], VBLOB_BUCKET_NAME)
    out.flush
  end
end

not_found do
  'This is nowhere to be found.'
end

VBLOB_BUCKET_NAME = 'assets-storage'

def get_bucket
  begin
    bucket = AWS::S3::Bucket.find(VBLOB_BUCKET_NAME)
  rescue AWS::S3::NoSuchBucket
    AWS::S3::Bucket.create(VBLOB_BUCKET_NAME)
    bucket = AWS::S3::Bucket.find(VBLOB_BUCKET_NAME)
  end
  bucket
end

def list_objs
  bucket = get_bucket

  data = []
  bucket.objects.each do |obj|
    item = {}
    item['filename'] = obj.key
    about            = obj.about
    item['md5']      = about['etag']
    item['length']   = about['content-length']
    data << item
  end
  data.to_json
end

def load_vblob
  vblob_service = load_service('blob')
  AWS::S3::Base.establish_connection!(
      :access_key_id      => vblob_service['username'],
      :secret_access_key  => vblob_service['password'],
      :port               => vblob_service['port'],
      :server             => vblob_service['host']
  ) unless vblob_service == nil
end

def load_service(service_name)
  services = JSON.parse(ENV['VMC_SERVICES'])
  service = services.find {|service| service["vendor"].downcase == service_name}
  service = service["options"] if service
end
