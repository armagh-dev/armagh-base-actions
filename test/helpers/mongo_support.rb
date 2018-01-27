# Copyright 2018 Noragh Analytics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'mongo'
require 'singleton'
require 'socket'

class MongoSupport

  include Singleton
  
  attr_reader :client

  DATABASE_NAME = 'armagh' unless defined? DATABASE_NAME
  HOST = '127.0.0.1' unless defined? HOST
  PORT = '27017' unless defined? PORT

  CONNECTION_STRING = "#{HOST}:#{PORT}" unless defined? CONNECTION_STRING

  OUT_PATH = '/tmp/test_mongo.out' unless defined? OUT_PATH

  MAX_LAUNCH_TIME = 60

  def initialize
    @mongod_exec = `which mongod`.strip
    @mongo_exec = `which mongo`.strip
    @mongo_pid = nil
    @client = nil
    Mongo::Logger.logger.level = ::Logger::FATAL

    @hostname = Socket.gethostname

    raise 'No mongod found' if @mongod_exec.nil? || @mongod_exec.empty?
    raise 'No mongo found' if @mongo_exec.nil? || @mongo_exec.empty?
  end

  def start_mongo(arguments = nil)
    if arguments
      cmd = "#{@mongod_exec} #{arguments}"
    else
      cmd = @mongod_exec
    end

    unless running?
      File.truncate(OUT_PATH, 0) if File.file? OUT_PATH
      @mongo_pid = Process.spawn(cmd, :out => OUT_PATH)
    end

    stop = Time.now + MAX_LAUNCH_TIME

    until can_connect?
      if Time.now > stop
        $stderr.puts "Mongo could not be started in #{MAX_LAUNCH_TIME} seconds."
        $stderr.puts File.read(OUT_PATH)
      elsif !running?
        $stderr.puts 'Mongo is no longer running.'
        $stderr.puts File.read(OUT_PATH)
        exit 1
      end

      sleep 0.5
    end

    @client ||= Mongo::Client.new([ CONNECTION_STRING ], :database => DATABASE_NAME)

    @mongo_pid
  end

  def can_connect?
    c = Mongo::Client.new([ CONNECTION_STRING ], :database => DATABASE_NAME)
    c.cluster.servers.each do |server|
      server.with_connection do |conn|
        return true if conn.ping
      end
    end
    false
  end

  def running?
    running = false
    running = `ps -p #{@mongo_pid} -o command=`.strip == @mongod_exec if @mongo_pid
    running
  end

  def get_mongo_output
    if File.file? OUT_PATH
      File.read OUT_PATH
    else
      ''
    end
  end

  def delete_config(type)
    @client['config'].find('type' => type).delete_one
  end

  def set_config(type, config)
    @client['config'].find('type' => type).replace_one(config.merge({'type' => type}), {upsert: true})
  end

  def get_status
    @client['status'].find('_id' => @hostname).limit(1).first
  end

  def get_mongo_documents(collection)
    @client[collection].find
  end

  def update_document(collection, id, values)
    @client[collection].find('_id' => id).find_one_and_update('$set' => values)
  end

  def stop_mongo
    return if @mongo_pid.nil?

    Process.kill(:SIGTERM, @mongo_pid)
    Process.wait(@mongo_pid)
    @client = nil
  end

  def clean_database
    `mongo #{DATABASE_NAME} --eval "db.dropDatabase();"`
    sleep 1
  end

  def initiate_replica_set
    `mongo --eval "rs.initiate();"`
    sleep 1
  end

  def clean_replica_set
    `mongo local --eval "db.dropDatabase();"`
    sleep 1
  end
end
