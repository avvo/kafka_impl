defmodule KafkaImpl.UtilTest do
  use ExUnit.Case, async: true

  doctest KafkaImpl.Util

  alias KafkaImpl.Util

  describe ".extract_offset()" do
    test "unwraps the offset embedded in the response" do
      example_response = [%KafkaEx.Protocol.Offset.Response{
        partition_offsets: [%{
           error_code: 0,
           offset: [1008],
           partition: 0
        }],
        topic: "test"
      }]

      assert Util.extract_offset(example_response) == {:ok, 1008}
    end
  end

  describe "extract messages" do
    test "unwraps fetched messages" do
      messages = [
        %KafkaEx.Protocol.Fetch.Message{
          attributes: 0,
          crc: 3546726102,
          key: nil,
          offset: 1005,
          value: "test message 1000"
        },
        %KafkaEx.Protocol.Fetch.Message{
          attributes: 0,
          crc: 4251893211,
          key: nil,
          offset: 1006,
          value: "hi"
        },
        %KafkaEx.Protocol.Fetch.Message{
          attributes: 0,
          crc: 4253201296,
          key: nil,
          offset: 1007,
          value: "boo"
        }
      ]

      raw_data = [
        %KafkaEx.Protocol.Fetch.Response{
          partitions: [%{
            error_code:     0,
            hw_mark_offset: 1008,
            last_offset:    1007,
            message_set:    messages,
            partition:      0
          }],
          topic: "test"
        }
      ]

      assert Util.extract_messages(raw_data) == {:ok, messages}
    end
  end

  test "brokers_parse" do
    assert {:ok, [{"foo", 10}, {"bar", 20}]} == Util.brokers_parse("foo:10,bar:20")
  end
end
