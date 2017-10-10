defmodule KafkaImpl.KafkaEx do
  @behaviour KafkaImpl
  defdelegate metadata(opts \\ []), to: KafkaEx
  defdelegate latest_offset(topic, partition, name \\ KafkaEx.Server), to: KafkaEx
  defdelegate offset_commit(worker_name, offset_commit_request), to: KafkaEx
  defdelegate earliest_offset(topic, partition, name \\ KafkaEx.Server), to: KafkaEx
  defdelegate fetch(topic, partition, opts \\ []), to: KafkaEx
  defdelegate produce(req, opts \\ []), to: KafkaEx
  defdelegate offset(topic, partition, time, name \\ KafkaEx.Server), to: KafkaEx
  defdelegate offset_fetch(worker_name, offset_fetch_request), to: KafkaEx

  def create_no_name_worker(brokers, consumer_group) do
    create_no_name_worker("0.8.2", brokers, consumer_group)
  end
  def create_no_name_worker(server_module, brokers, consumer_group) when is_atom(server_module) do
    GenServer.start_link(server_module, [
      [uris: brokers, consumer_group: consumer_group],
      :no_name
    ])
  end
  def create_no_name_worker(server_version, brokers, consumer_group) when is_binary(server_version) do
    server_version
    |> KafkaImpl.Util.kafka_ex_worker
    |> create_no_name_worker(brokers, consumer_group)
  end
end
