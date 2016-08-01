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
