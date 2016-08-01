require "./src/redisoid"

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
