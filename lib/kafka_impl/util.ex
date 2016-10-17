defmodule KafkaImpl.Util do
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
