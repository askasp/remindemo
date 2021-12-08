defmodule RemindemoWeb.PageLive do
  use RemindemoWeb, :live_view
  @presence_topic "presence"
  @counter_topic "counter"

  def mount(_, params, socket) do
		shared_counter_value = GenServer.call(Remindemo.SharedCounter, :get)
    {:ok,
     assign(socket,
       reader_count: init_presence(socket),
       personal_counter: 0,
       semi_shared_counter: 0,
       shared_counter: shared_counter_value
     )}
  end

  # Presence logic
  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, socket) do
    reader_count = socket.assigns.reader_count + map_size(joins) - map_size(leaves)
    {:noreply, assign(socket, :reader_count, reader_count)}
  end

  # Messages from browser
  def handle_event("increment_personal_counter", _, socket),
    do: {:noreply, assign(socket, personal_counter: socket.assigns.personal_counter + 1)}

  def handle_event("decrement_personal_counter", _, socket),
    do: {:noreply, assign(socket, personal_counter: socket.assigns.personal_counter - 1)}

  def handle_event("increment_semi_shared_counter", _, socket) do
    Phoenix.PubSub.broadcast(Remindemo.PubSub, @counter_topic, :increment_semi_shared)
    {:noreply, socket}
  end

  def handle_event("decrement_semi_shared_counter", _, socket) do
    Phoenix.PubSub.broadcast(Remindemo.PubSub, @counter_topic, :decrement_semi_shared)
    {:noreply, socket}
  end

  def handle_event("increment_shared_counter", _, socket) do
    IO.puts " im here"
    GenServer.cast(Remindemo.SharedCounter, :increment)
    {:noreply, socket}
  end

  def handle_event("decrement_shared_counter", _, socket) do
    IO.puts " im here"
    GenServer.cast(Remindemo.SharedCounter, :decrement)
    {:noreply, socket}
  end

  def handle_event("decrement_semi_shared_counter", _, socket),
    do: {:noreply, assign(socket, semi_shared_counter: socket.assigns.semi_shared_counter - 1)}

  # Messages from backend
  def handle_info(:increment_semi_shared, socket),
    do: {:noreply, assign(socket, semi_shared_counter: socket.assigns.semi_shared_counter + 1)}

  def handle_info(:decrement_semi_shared, socket),
    do: {:noreply, assign(socket, semi_shared_counter: socket.assigns.semi_shared_counter - 1)}

  def handle_info({:shared_counter_value, value}, socket),
    do: {:noreply, assign(socket, shared_counter: value)}

  def render(assigns) do
    ~H"""
    <h1> Remin Counters </h1>

    <div style="display: flex; ">
    <h2> People viewing this site: </h2>
    <h2 style="margin-left: 30px" > <%= @reader_count %> </h2>
    </div>

    <h2 style="margin-top:100px"> You can increment, stored seperately in each actor  </h2>
    <div style="display: flex; justify-content: space-around">
    <button phx-click="decrement_personal_counter" style="background-color: #2094f3" > - </button>
    <h3> <%= @personal_counter %> </h3>
    <button phx-click="increment_personal_counter"  style="background-color: #2094f3" > + </button>
    </div>
    <h2 style="margin-top:100px"> All can increment, stored separately in each actor </h2>
    <div style="display: flex; justify-content: space-around">
    <button phx-click="decrement_semi_shared_counter" style="background-color: #2094f3" > - </button>
    <h3> <%= @semi_shared_counter %> </h3>
    <button phx-click="increment_semi_shared_counter" style="background-color: #2094f3" > + </button>
    </div>


    <h2 style="margin-top:100px"> All can increment, stored in shared actor </h2>
    <div style="display: flex; justify-content: space-around">
    <button phx-click="decrement_shared_counter" style="background-color: #2094f3"> - </button>
    <h3> <%= @shared_counter %> </h3>
    <button phx-click="increment_shared_counter" style="background-color: #2094f3" > + </button>

    </div>


    <div style="margin-top:100px"> </div>
    <div style="display: flex; justify-content: space-around">
    <button phx-click="this_message_does_not_exist" style="background-color: #ff5724; border:0px; width:300px; height:60px; font-weight:800; font-size:16px"> Crash this actor! </button>
    </div>

    """
  end

  defp init_presence(socket) do
    Remindemo.Presence.track(
      self(),
      @presence_topic,
      socket.id,
      %{}
    )

    Phoenix.PubSub.subscribe(Remindemo.PubSub, @counter_topic)

    Remindemo.Presence.list(@presence_topic)
    |> Map.keys()
    |> length
  end
end
