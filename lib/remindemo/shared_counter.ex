defmodule Remindemo.SharedCounter do
  use GenServer

  def start_link(_arg), do: GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])

  def init(:ok), do: {:ok, 0}

  def handle_call(:get, _from, counter), do: {:reply, counter, counter}
  def handle_cast(:increment, counter) do
  	Phoenix.PubSub.broadcast(Remindemo.PubSub, "counter", {:shared_counter_value, counter + 1} )
  	{:noreply, counter + 1}
  end

  def handle_cast(:decrement, counter) do
  	Phoenix.PubSub.broadcast(Remindemo.PubSub, "counter", {:shared_counter_value,  counter - 1 })
  	{:noreply, counter - 1}
  end
   
end
