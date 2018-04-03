require "redis-reconnect"
require "pool/connection"

class Redisoid
  VERSION = "0.2"

  @cp : ConnectionPool(Redis::Reconnect)

  def initialize(@host : String = "localhost",
                 @port : Int32 = 6379,
                 @unixsocket : String? = nil,
                 @password : String? = nil,
                 @database : Int32? = nil,
                 @pool : Int32 = 10,
                 @url : String? = nil)
    @cp = ConnectionPool(Redis::Reconnect).new(capacity: @pool) do
      Redis::Reconnect.new(host: @host, port: @port, unixsocket: @unixsocket, password: @password, database: @database, url: @url)
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

  def stats
    {capacity: @pool, available: pool_pending, used: pool_size}
  end

  def subscribe(*channels, &callback_setup_block : Redis::Subscription ->)
    @cp.connection &.subscribe(*channels) { |s| callback_setup_block.call(s) }
  end

  def psubscribe(*channel_patterns, &callback_setup_block : Redis::Subscription ->)
    @cp.connection &.subscribe(*channel_patterns) { |s| callback_setup_block.call(s) }
  end
end
