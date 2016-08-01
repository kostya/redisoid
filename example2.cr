require "./src/redisoid"

client = Redisoid.new(host: "localhost", port: 6379, pool: 150)

client.del("queue")

100.times do
  spawn do
    loop do
      client.lpush("queue", "abc")
      sleep rand(0.01)
    end
  end
end

sleep 5.0
p client.llen("queue")
client.del("queue")
