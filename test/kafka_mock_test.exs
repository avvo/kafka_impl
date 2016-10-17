defmodule KafkaImpl.KafkaMockTest do
  use ExUnit.Case, async: true

  alias KafkaImpl.KafkaMock

  setup do
    :ok = case KafkaMock.start_link do
      {:ok, _mock} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  describe "metadata" do
    test "can set and retrieve topics" do
      assert [] == KafkaMock.metadata.topic_metadatas
      KafkaMock.set_topics(self, ["foo", "bar"])
      assert ["foo", "bar"] == KafkaMock.metadata.topic_metadatas |>
        Enum.map(& Map.get(&1, :topic))
    end
  end

  test "create_no_name_worker" do
    assert {:ok, :fake_pid} == KafkaMock.create_no_name_worker([{"localhost", 9092}], "group")
  end

  test "latest_offset" do
    assert [%KafkaEx.Protocol.Offset.Response{partition_offsets: [%{offset: [0]}]}] == KafkaMock.latest_offset("foo", 0)
  end

  describe "fetch" do
    test "can set and retrieve messaages" do
      topic = "foo"
      offset = 100
      partition = 0
      message = "the message"

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [], last_offset: nil}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)

      KafkaMock.send_message(self, {topic, partition, message, offset})

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [message], last_offset: offset}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)
    end

    test "can receive multiple messages" do
      topic = "foo"
      offset = 100
      partition = 0
      message1 = "the message"
      message2 = "second message"

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [], last_offset: nil}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)

      KafkaMock.send_messages(self, [
        {topic, partition, message1, offset},
        {topic, partition, message2, offset+1}
      ])

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [message1, message2], last_offset: offset+1}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)
    end
  end

  test "offset_commit" do
    topic = "foo"
    offset = 100
    assert %KafkaEx.Protocol.OffsetCommit.Response{topic: topic, partitions: [offset]} ==
      KafkaMock.offset_commit(:some_worker_pid, %{topic: topic, offset: offset})
  end
end
