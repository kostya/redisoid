require "redis-reconnect"
require "pool/connection"

class Redisoid
  VERSION = "0.1"
  @cp : ConnectionPool(Redis::Reconnect)

  def initialize(@host : String = "localhost", @port : Int32 = 6379, @unixsocket : String? = nil, @password : String? = nil, @database : Int32? = nil, @pool : Int32 = 10)
    @cp = ConnectionPool(Redis::Reconnect).new(capacity: @pool) do
      Redis::Reconnect.new(host: @host, port: @port, unixsocket: @unixsocket, password: @password, database: @database)
    end
  end

  macro method_missing(call)
    @cp.connection do |cn|
      return cn.{{call}}
    end
  end
end
