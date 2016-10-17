defmodule KafkaImpl.KafkaMock do
  @behaviour KafkaImpl

  def start_link, do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def set_topics(requesting_pid, new_topics) do
    update(requesting_pid, fn state ->
      state |> Map.put(:topics, new_topics |> Enum.map(&format_for_kafka_ex/1))
    end)
  end

  def send_message(requesting_pid, msg) do
    send_messages(requesting_pid, [msg])
  end

  def send_messages(requesting_pid, messages) do
    update(requesting_pid, fn state ->
      state |> Map.put(:messages, messages)
    end)
  end

  ## Actual Kafka interface

  def metadata(_opts \\ []) do
    topics = get(:topics, [])

    %{
      topic_metadatas: topics
    }
  end

  def create_no_name_worker(_brokers, _consumer_group) do
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

    records = get(:messages, [])
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

  def produce(_request, _opts), do: :ok

  def offset_commit(_,%{topic: topic, offset: offset}) do
    %KafkaEx.Protocol.OffsetCommit.Response{topic: topic, partitions: [offset]}
  end

  # PRIVATE FUNCS FOR MOCK AGENT

  defp get(key, default) do
    pid = self
    case Process.whereis(__MODULE__) do
      nil -> default
      _ ->
        Agent.get(__MODULE__, fn state ->
          state |> Map.get(pid, %{}) |> Map.get(key, default)
        end)
    end
  end

  defp update(pid, func) do
    Agent.update(__MODULE__, fn state ->
      state |> Map.update(pid, func.(%{}), func)
    end)
  end

  defp format_for_kafka_ex({topic_name, number_of_partitions}) do
    %KafkaEx.Protocol.Metadata.TopicMetadata{
      error_code: 0,
      partition_metadatas: Enum.map(1..number_of_partitions, fn n ->
        %KafkaEx.Protocol.Metadata.PartitionMetadata{
          error_code: 0,
          isrs: [0],
          leader: 0,
          partition_id: n,
          replicas: [0]
        }
      end),
      topic: topic_name
    }
  end
  defp format_for_kafka_ex(topic_name) when is_binary(topic_name) do
    format_for_kafka_ex({topic_name, 1})
  end
end
