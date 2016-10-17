defmodule KafkaImpl.KafkaEx do
  @behaviour KafkaImpl
  defdelegate metadata(opts \\ []), to: KafkaEx
  defdelegate latest_offset(topic, partition, name \\ KafkaEx.Server), to: KafkaEx
  defdelegate offset_commit(worker_name, offset_commit_request), to: KafkaEx
  defdelegate earliest_offset(topic, partition, name \\ KafkaEx.Server), to: KafkaEx
  defdelegate fetch(topic, partition, opts \\ []), to: KafkaEx
  defdelegate produce(req, opts \\ []), to: KafkaEx

  def create_no_name_worker(brokers, consumer_group) do
    GenServer.start_link(KafkaEx.Server, [
      [uris: brokers, consumer_group: consumer_group],
      :no_name
    ])
  end
end
