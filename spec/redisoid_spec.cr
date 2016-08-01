require "./spec_helper"

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
    client.set("bla1", "a")
    client.get("bla1").should eq "a"

    sleep(TIMEOUT + 1.0)

    client.get("bla1").should eq "a"
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
end
