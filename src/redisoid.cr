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

  def pool_size
    @cp.size
  end

  def pool_pending
    @cp.pending
  end

  def subscribe(*channels, &callback_setup_block : Redis::Subscription ->)
    @cp.connection &.subscribe(*channels) { |s| callback_setup_block.call(s) }
  end

  def psubscribe(*channel_patterns, &callback_setup_block : Redis::Subscription ->)
    @cp.connection &.subscribe(*channel_patterns) { |s| callback_setup_block.call(s) }
  end
end
