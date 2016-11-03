defmodule KafkaImpl.KafkaMock.TestHelper do
  alias KafkaImpl.KafkaMock.Store

  def set_topics(requesting_pid, new_topics) do
    Store.update(requesting_pid, fn state ->
      state |> Map.put(:topics, new_topics |> Enum.map(&format_for_kafka_ex/1))
    end)
  end

  def set_offset_at(requesting_pid, datetime = %DateTime{}, offset) do
    erltime = datetime |> DateTime.to_naive |> NaiveDateTime.to_erl

    Store.update(requesting_pid, fn state ->
      state |> Map.put({:offset_at, erltime}, offset)
    end)
  end

  def send_message(requesting_pid, msg) do
    send_messages(requesting_pid, [msg])
  end

  def send_messages(requesting_pid, messages) do
    Store.update(requesting_pid, fn state ->
      state |> Map.put(:messages, messages)
    end)
  end

  def last_committed_offset_for(requesting_pid, consumer_group, topic, partition) do
    last_committed_offset_for(requesting_pid, consumer_group, topic, partition, 100)
  end
  def last_committed_offset_for(_requesting_pid, _consumer_group, _topic, _partition, 0), do: nil
  def last_committed_offset_for(requesting_pid, consumer_group, topic, partition, tries_remaining) do
    case Store.get({:offset_commit, consumer_group, topic, partition}, nil, requesting_pid) do
      nil ->
        :timer.sleep(1)
        last_committed_offset_for(requesting_pid, consumer_group, topic, partition, tries_remaining - 1)
      x -> x
    end
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
