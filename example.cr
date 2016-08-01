require "./src/redisoid"

client = Redisoid.new(host: "localhost", port: 6379, pool: 50)
client.set("bla", "abc")
p client.get("bla")
