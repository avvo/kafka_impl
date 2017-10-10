defmodule KafkaImpl.Util do
  def extract_offset([%KafkaEx.Protocol.Offset.Response{partition_offsets: [%{offset: [offset]}]}]), do: {:ok, offset}
  def extract_offset([%KafkaEx.Protocol.Offset.Response{partition_offsets: [%{offset: []}]}]), do: :no_offset
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

  def kafka_brokers do
    case System.get_env("KAFKA_HOSTS") do
      nil -> {:error, "You must define KAFKA_HOSTS."}
      hosts -> brokers_parse(hosts)
    end
  end

  def brokers_parse(brokers_string) do
    brokers_string
    |> String.split(",")
    |> Enum.map(fn pair -> String.split(pair, ":") |> List.to_tuple end)
    |> Enum.map(fn {host, port} -> {host, String.to_integer(port)} end)
    |> (fn brokers -> {:ok, brokers} end).()
  end

  @doc """
  Return the name of the KafkaEx worker for the Kafka version being used.

  ## Example

      iex> KafkaImpl.Util.kafka_ex_worker("0.8.2")
      KafkaEx.Server0P8P2
  """
  def kafka_ex_worker(), do: kafka_ex_worker("0.8.2")
  def kafka_ex_worker("0.8.0"), do: KafkaEx.Server0P8P0
  def kafka_ex_worker("0.8.2"), do: KafkaEx.Server0P8P2
  def kafka_ex_worker("0.9.0"), do: KafkaEx.Server0P9P0
end
