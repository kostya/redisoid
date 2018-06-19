# THIS PROJECT DEPRECATED, RECONNECTION LOGIC AND POOLING NOW IMPLEMENTED IN stefanwille/crystal-redis

# redisoid

Redis client for Crystal with auto-reconnection and pool (wrapper for stefanwille/crystal-redis, kostya/redis-reconnect, ysbaddaden/pool). Ready to use in production.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  redisoid:
    github: kostya/redisoid
```


## Usage


```crystal
require "redisoid"

client = Redisoid.new(host: "localhost", port: 6379, pool: 50)
client.set("bla", "abc")
p client.get("bla")
```

## Use it in high concurency code

```crystal
require "redisoid"

client = Redisoid.new(host: "localhost", port: 6379, pool: 250)

client.del("queue")

count = 0

100.times do
  spawn do
    loop do
      client.lpush("queue", "abc")
      sleep 0.01
    end
  end

  spawn do
    loop do
      if res = client.lpop("queue")
        count += 1 if res.size == 3
      else
        sleep 0.01
      end
    end
  end
end

sleep 5.0

p count
p client.pool_size
p client.pool_pending

client.del("queue")

```

```
42259
200
204
```
