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
    sleep 0.1
    client1.publish("sub_test", "bla")

    ch.receive.should eq "bla"
  end
end
