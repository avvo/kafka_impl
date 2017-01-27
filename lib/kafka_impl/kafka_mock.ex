defmodule KafkaImpl.KafkaMock do
  @behaviour KafkaImpl

  alias KafkaImpl.KafkaMock.Store

  defdelegate start_link, to: Store

  ## Actual Kafka interface

  def metadata(_opts \\ []) do
    topics = Store.get(:topics, [])

    %{
      topic_metadatas: topics
    }
  end

  def create_no_name_worker(_server_module \\ nil, _brokers, _consumer_group) do
    {:ok, :fake_pid}
  end

  def latest_offset(_topic, _partition, _name \\ KafkaEx.Server) do
    [
      %KafkaEx.Protocol.Offset.Response{
        partition_offsets: [
          %{
            offset: [0]
          }
        ]
      }
    ]
  end

  def earliest_offset(_topic, _partition, _name \\ KafkaEx.Server) do
    [
      %KafkaEx.Protocol.Offset.Response{
        partition_offsets: [
          %{
            offset: [-100]
          }
        ]
      }
    ]
  end

  def fetch(topic, partition, opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)

    records = Store.get(:messages, [])
    |> Enum.filter(fn {^topic, ^partition, _, msg_offset} -> msg_offset >= offset; _ -> false end)

    next_offset = records |> Enum.reduce(nil, fn {_,_,_,msg_offset}, acc ->
      cond do
        acc == nil -> msg_offset
        acc > msg_offset -> acc
        true -> msg_offset
      end
    end)

    messages = records |> Enum.map(fn {_,_,msg,_} -> msg end)

    [%KafkaEx.Protocol.Fetch.Response{
        topic: topic,
        partitions: [
          %{partition: partition, message_set: messages, last_offset: next_offset}
        ]
    }]
  end

  def produce(%{topic: topic, partition: partition, messages: [%{value: message}]}, _opts \\ []) do
    Store.update(self(), fn state ->
      key = {:produce, topic, partition}
      existing_messages = state |> Map.get(key, [])
      state |> Map.put(key, [message | existing_messages])
    end)
  end

  def offset_commit(_worker, %{consumer_group: consumer_group, topic: topic, partition: partition, offset: offset}) do
    Store.update(self(), fn state ->
      state |> Map.put({:offset_commit, consumer_group, topic, partition}, offset)
    end)

    %KafkaEx.Protocol.OffsetCommit.Response{topic: topic, partitions: [offset]}
  end

  def offset(_topic, _partition, time, _name \\ KafkaEx.Server) do
    offset = Store.get({:offset_at, time}, 0)
    [
      %KafkaEx.Protocol.Offset.Response{
        partition_offsets: [
          %{
            offset: [offset]
          }
        ]
      }
    ]
  end
end
