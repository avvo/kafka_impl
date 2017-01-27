defmodule KafkaImpl.KafkaMock.Store do
  def start_link, do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def get(key, default) do
    get(key, default, self())
  end
  def get(key, default, pid) do
    case Process.whereis(__MODULE__) do
      nil -> default
      _ ->
        Agent.get(__MODULE__, fn state ->
          state |> Map.get(pid, %{}) |> Map.get(key, default)
        end)
    end
  end

  def update(pid, func) do
    Agent.update(__MODULE__, fn state ->
      state |> Map.update(pid, func.(%{}), func)
    end)
  end
end
