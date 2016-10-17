defmodule KafkaImpl do
  @impl Application.fetch_env!(:kafka_impl, :impl)

  @callback metadata(Keyword.t) :: KafkaEx.Protocol.Metadata.Response.t
  defdelegate metadata(opts \\ []), to: @impl

  @callback create_no_name_worker(KafkaEx.uri(), String.t) :: Supervisor.on_start_child
  defdelegate create_no_name_worker(brokers, consumer_group), to: @impl

  @callback latest_offset(binary, integer, atom|pid) :: [KafkaEx.Protocol.Offset.Response.t] | :topic_not_found
  defdelegate latest_offset(topic, partition, name \\ KafkaEx.Server), to: @impl

  @callback offset_commit(pid() | atom, KafkaEx.Protocol.OffsetCommit.Request.t) :: KafkaEx.Protocol.OffsetCommit.Response.t
  defdelegate offset_commit(worker_name, offset_commit_request), to: @impl

  @callback earliest_offset(binary, integer, atom|pid) :: [KafkaEx.Protocol.Offset.Response.t] | :topic_not_found
  defdelegate earliest_offset(topic, partition, name \\ KafkaEx.Server), to: @impl

  @callback fetch(binary, number, Keyword.t) :: [KafkaEx.Protocol.Fetch.Response.t] | :topic_not_found
  defdelegate fetch(topic, partition, opts \\ []), to: @impl

  @callback produce(KafkaEx.Protocol.Produce.Request.t, Keyword.t) :: nil | :ok | {:ok, integer} | {:error, :closed} | {:error, :inet.posix} | {:error, any} | iodata | :leader_not_available
  defdelegate produce(request, opts \\ []), to: @impl

  def extract_offset([%KafkaEx.Protocol.Offset.Response{partition_offsets: [%{offset: [offset]}]}]), do: {:ok, offset}
  def extract_offset(error), do: {:error, "Can't extract offset: #{inspect error}"}

  def extract_messages([%{partitions: partitions}]) do
    messages = partitions
    |> Enum.map(&(&1[:message_set]))
    |> Enum.reduce([], fn messages, acc ->
      acc ++ messages
    end)

    {:ok, messages}
  end
  def extract_messages(_), do: {:error, "Can't extract messages"}
end
