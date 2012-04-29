require 'sinatra'
require 'json'
require 'mongo'
require 'uri'

get '/env' do
  ENV['VMC_SERVICES']
end

get '/' do
  'hello from sinatra'
end

get '/crash' do
  Process.kill("KILL", Process.pid)
end

get '/list' do
  coll = get_mongo_db['fs.files']
  coll.find.to_a.to_json
end

get '/files/:key' do
  db = get_mongo_db
  grid = Mongo::Grid.new(db)
  coll = get_mongo_db['fs.files']
  id = coll.find('filename' => params[:key]).to_a.first['_id']
  file = grid.get(id)
  file.read
end

not_found do
  'This is nowhere to be found.'
end

def get_mongo_db
  conn = Mongo::Connection.new('127.0.0.1', 4567)
  db = conn['testdb']
end


