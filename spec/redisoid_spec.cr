require "./spec_helper"
require "redis"

# manualy run: redis-server --port 7777 --timeout 2
CONFIG  = {host: "localhost", port: 7777}
TIMEOUT = 2

describe Redisoid do
  it "standard client" do
    client = Redis.new(**CONFIG)
    client.set("bla1", "a")
    client.get("bla1").should eq "a"

    sleep(TIMEOUT + 1.0)

    expect_raises(Redis::DisconnectedError) do
      client.get("bla1")
    end
  end

  it "reconnect client" do
    client = Redisoid.new(**CONFIG)
    client.set("bla2", "a")
    client.get("bla2").should eq "a"

    sleep(TIMEOUT + 1.0)

    client.get("bla2").should eq "a"
  end

  it "connect with url also" do
    client = Redisoid.new(url: "localhost:7777", pool: 5)
    client.set("bla3", "a")
    client.get("bla3").should eq "a"
  end

  it "reconnect method with block" do
    client1 = Redisoid.new(**CONFIG)
    client2 = Redisoid.new(**CONFIG)
    ch = Channel(String).new
    spawn do
      client2.subscribe("sub_test") do |on|
        on.message do |_, msg|
          ch.send(msg)
        end
      end
    end
    sleep(TIMEOUT + 1.0)
    client1.publish("sub_test", "bla")

    ch.receive.should eq "bla"
  end

  it "work with pipelined" do
    client = Redisoid.new(**CONFIG)
    client.pipelined do |pipeline|
      pipeline.del("foo")
      pipeline.del("foo1")
      pipeline.del("foo2")
      pipeline.del("foo3")
      pipeline.set("foo1", "first")
      pipeline.set("foo2", "second")
      pipeline.set("foo3", "third")
    end

    client.get("foo2").should eq "second"
  end

  it "work with transaction" do
    client = Redisoid.new(**CONFIG)
    client.multi do |multi|
      multi.del("foo")
      multi.del("foo1")
      multi.del("foo2")
      multi.del("foo3")
      multi.set("foo1", "first")
      multi.set("foo2", "second")
      multi.set("foo3", "third")
    end

    client.get("foo2").should eq "second"
  end

  it "work with transaction with futures" do
    client = Redisoid.new(**CONFIG)
    future_1 = Redis::Future.new
    future_2 = Redis::Future.new
    client.multi do |multi|
      multi.set("foo1", "A")
      multi.set("foo2", "B")
      future_1 = multi.get("foo1")
      future_2 = multi.get("foo2")
    end

    future_1.value.should eq "A"
    future_2.value.should eq "B"
  end

  it "stats" do
    client = Redisoid.new(**CONFIG)
    client.stats.should eq({capacity: 10, available: 10, used: 0})
  end

  it "quite multiconcurrent execution" do
    client = Redisoid.new(**CONFIG)
    client.del("test-queue")
    res = [] of String
    checks = 0

    n1 = 50
    n2 = 200

    n1.times do |i|
      spawn do
        n2.times do |j|
          client.set("key-#{i}-#{j}", "#{i}-#{j}")
          client.rpush("test-queue", "#{i}-#{j}")
          sleep 0.0001
        end
      end
    end

    ch = Channel(Bool).new

    n1.times do
      spawn do
        loop do
          if v = client.lpop("test-queue")
            res << v
            if client.get("key-#{v}") == v
              checks += 1
              client.del("key-#{v}")
            end
          else
            sleep 0.0001
          end

          break if res.size >= n1 * n2
        end
        ch.send(true)
      end
    end

    n1.times { ch.receive }

    res.size.should eq n1 * n2
    res.uniq.size.should eq n1 * n2

    checks.should eq n1 * n2

    uniqs = [] of Int64

    res.each do |v|
      a, b = v.split('-')
      uniqs << (a.to_i64 * n2 + b.to_i64).to_i64
    end

    uniqs.sum.should eq ((n1 * n2 - 1).to_i64 * n1.to_i64 * n2.to_i64).to_i64 / 2
  end
end
