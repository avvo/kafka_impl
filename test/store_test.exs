defmodule KafkaImpl.KafkaMock.StoreTest do
  use ExUnit.Case

  alias KafkaImpl.KafkaMock.Store

  defmodule TestProcess do
    use GenServer

    def start_link(func \\ (fn -> nil end)) do
      GenServer.start_link(__MODULE__, func)
    end

    def init(func) do
      func.()
      {:ok, func}
    end

    def handle_info({:spawn_child, func}, state) do
      {:ok, _} = start_link(func)
      {:noreply, state}
    end
  end

  defp new_link() do
    {:ok, pid} = TestProcess.start_link()
    pid
  end

  test "get_storage_pid for child pid" do
    registered_pids = [
      new_link(),
      storage_pid = new_link(),
      new_link(),
    ]

    test_pid = self()
    send storage_pid, {:spawn_child, fn -> send test_pid, {:child_pid, self()} end}

    child = receive do
      {:child_pid, child} -> child
    after
      1000 -> raise "did not receive child pid after 1s"
    end

    assert {:ok, storage_pid} == Store.get_storage_pid(child, registered_pids)
  end

  test "get_storage_pid for self" do
    registered_pids = [
      new_link(),
      storage_pid = new_link(),
      new_link(),
    ]

    send storage_pid, {:spawn_child, self()}

    assert {:ok, storage_pid} == Store.get_storage_pid(storage_pid, registered_pids)
  end

  test "registering a pid is used for storage" do
    Store.start_link

    parent = new_link()
    test_pid = self()

    send parent, {:spawn_child, fn ->
      Store.update(fn state ->
        Map.put(state, :foo, "bar")
      end)
      send test_pid, :proceed
    end}

    receive do
      :proceed -> :ok
    after
      100 -> raise "didn't get the message to proceed"
    end

    assert "bar" == Store.get(:foo, nil)
  end

  test "get looks up the parent for storage" do
    Store.start_link

    parent = new_link()

    Store.update(fn state ->
      Map.put(state, :foo, "bar")
    end)

    send parent, {:spawn_child, fn ->
      assert "bar" == Store.get(:foo, nil)
    end}
  end

  test "both update and get in children" do
    Store.start_link

    parent1 = new_link()
    test_pid = self()

    send parent1, {:spawn_child, fn ->
      Store.update(fn state ->
        Map.put(state, :foo, "bar")
      end)
      send test_pid, :proceed
    end}

    receive do
      :proceed -> :ok
    after
      100 -> raise "didn't get the message to proceed"
    end

    parent2 = new_link()

    send parent2, {:spawn_child, fn ->
      assert "bar" == Store.get(:foo, nil)
    end}
  end
end
