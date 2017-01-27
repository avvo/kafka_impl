defmodule KafkaImpl do
  @impl Application.fetch_env!(:kafka_impl, :impl)

  @callback metadata(Keyword.t) :: KafkaEx.Protocol.Metadata.Response.t
  defdelegate metadata(opts \\ []), to: @impl

  @callback create_no_name_worker(KafkaEx.uri(), String.t) :: Supervisor.on_start_child
  defdelegate create_no_name_worker(brokers, consumer_group), to: @impl

  @callback create_no_name_worker(String.t | atom, KafkaEx.uri(), String.t) :: Supervisor.on_start_child
  defdelegate create_no_name_worker(server_module, brokers, consumer_group), to: @impl

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

  @spec offset(binary, number, :calendar.datetime|atom, atom|pid) :: [KafkaEx.Protocol.Offset.Response.t] | :topic_not_found
  defdelegate offset(topic, partition, time, name \\ KafkaEx.Server), to: @impl

  @callback offset_fetch(atom, KafkaEx.Protocol.OffsetFetch.Request.t) :: [KafkaEx.Protocol.OffsetFetch.Response.t] | :topic_not_found
  defdelegate offset_fetch(worker_name, offset_fetch_request), to: @impl
end
