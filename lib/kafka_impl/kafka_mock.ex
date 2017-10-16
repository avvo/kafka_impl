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

  def offset_fetch(_pid, %KafkaEx.Protocol.OffsetFetch.Request{topic: topic, partition: partition}) do
    [
      %KafkaEx.Protocol.OffsetFetch.Response{
        partitions: [
          %{
            error_code: :no_error,
            metadata: "",
            offset: 1,
            partition: partition
          }
        ],
        topic: topic
      }
    ]
  end

  def fetch(topic, partition, opts \\ []) do
    offset = Keyword.get(opts, :offset, 0)

    message_set = messages_key(topic, partition)
    |> Store.get([])
    |> Enum.filter(fn %{offset: msg_offset} -> msg_offset >= offset end)

    last_offset = Enum.reduce(message_set, nil, fn %{offset: msg_offset}, acc ->
      cond do
        acc == nil -> msg_offset
        acc > msg_offset -> acc
        true -> msg_offset
      end
    end)

    [%KafkaEx.Protocol.Fetch.Response{
      topic: topic,
      partitions: [
        %{partition: partition, message_set: message_set, last_offset: last_offset}
      ]
    }]
  end

  def produce(%KafkaEx.Protocol.Produce.Request{
    topic: topic, partition: partition, messages: [
      %KafkaEx.Protocol.Produce.Message{} = message
    ]
  }, _opts \\ []) do
    Store.update(fn state ->
      key = messages_key(topic, partition)

      existing_records = Map.get(state, key, [])

      offset = Enum.reduce(existing_records, -1, fn %{offset: offset}, acc ->
        if offset > acc, do: offset, else: acc
      end) + 1

      record = %KafkaEx.Protocol.Fetch.Message{
        value: message.value,
        offset: offset
      }

      state
      |> Map.put(key, [record | existing_records])
    end)
  end

  def offset_commit(_worker, %{consumer_group: consumer_group, topic: topic, partition: partition, offset: offset}) do
    Store.update(fn state ->
      Map.put(state, {:offset_commit, consumer_group, topic, partition}, offset)
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

  defp messages_key(topic, partition) do
    {:produce, topic, partition}
  end
end
