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

client = Redisoid.new(host: "localhost", port: 6379, pool: 150)

client.del("queue")

c = 0

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
        c += res.size
      else
        sleep 0.01
      end
    end
  end
end

sleep 5.0
p c
client.del("queue")
```
