defmodule KafkaImpl.KafkaMockTest do
  use ExUnit.Case, async: true

  alias KafkaImpl.KafkaMock
  alias KafkaImpl.KafkaMock.TestHelper
  alias KafkaEx.Protocol.Fetch.Message, as: FetchMessage

  defmodule TestProcess do
    use GenServer

    def start_link(func \\ (fn -> nil end)) do
      GenServer.start_link(__MODULE__, func)
    end

    def init(func) do
      func.()
      {:ok, func}
    end

    def handle_info({:spawn_child, func}, state) do
      {:ok, _} = start_link(func)
      {:noreply, state}
    end
  end

  defp new_link() do
    {:ok, pid} = TestProcess.start_link()
    pid
  end

  setup do
    KafkaMock.start_link

    :ok
  end

  describe "metadata" do
    test "can set and retrieve topics" do
      assert [] == KafkaMock.metadata.topic_metadatas
      TestHelper.set_topics(["foo", "bar"])
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
      offset = 0
      partition = 0
      message = %FetchMessage{value: "the message", offset: offset}

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [], last_offset: nil}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)

      TestHelper.send_messages(topic, partition, [
        message
      ])

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [message], last_offset: offset}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)
    end

    test "can receive multiple messages" do
      topic = "foo"
      offset = 0
      partition = 0
      message1 = %FetchMessage{value: "the message", offset: offset}
      message2 = %FetchMessage{value: "second message", offset: offset+1}

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: [], last_offset: nil}
        ]
      }] == KafkaMock.fetch(topic, partition, offset: offset)

      TestHelper.send_messages(topic, partition, [ message1, message2 ])

      expected_offset = offset + 1

      assert [%KafkaEx.Protocol.Fetch.Response{
        topic: ^topic,
        partitions: [
          %{
            partition: ^partition,
            message_set: [^message1, ^message2],
            last_offset: ^expected_offset
          }
        ]
      }] = KafkaMock.fetch(topic, partition, offset: offset)
    end
  end

  test "offset_commit" do
    topic = "foo"
    offset = 0
    assert %KafkaEx.Protocol.OffsetCommit.Response{topic: topic, partitions: [offset]} ==
      KafkaMock.offset_commit(:some_worker_pid, %{topic: topic, offset: offset, partition: 0,
        consumer_group: "kafka_impl"})
  end

  test "produce and read_messages" do
    topic = "fooz"
    partition = 1
    message = "okay do it"
    %KafkaEx.Protocol.Produce.Request{
      topic:         topic,
      partition:     partition,
      required_acks: 1,
      messages:      [%KafkaEx.Protocol.Produce.Message{
        value: message
      }]
    } |> KafkaMock.produce

    assert [^message] = TestHelper.read_messages topic, partition
  end

  test "process tree inheritance" do
    topic = "fooz"
    partition = 1
    message = "okay do it"
    request = %KafkaEx.Protocol.Produce.Request{
      topic:         topic,
      partition:     partition,
      required_acks: 1,
      messages:      [%KafkaEx.Protocol.Produce.Message{
        value: message
      }]
    }

    test_pid = self()
    pid = new_link()
    send pid, {:spawn_child, fn ->
      KafkaMock.produce(request)
      send test_pid, :produced
    end}

    :ok = receive do
      :produced -> :ok
    after
      1000 -> raise "no message produced after 1s"
    end

    assert [^message] = TestHelper.read_messages topic, partition
  end
end
