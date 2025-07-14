defmodule GreenhouseTycoonWeb.GreenhouseLive do
  use GreenhouseTycoonWeb, :live_view
  
  alias GreenhouseTycoon.API

  @impl true
  def mount(%{"id" => greenhouse_id}, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time greenhouse updates
      Phoenix.PubSub.subscribe(GreenhouseTycoon.PubSub, "greenhouse_updates")
      # Refresh data every 2 seconds as fallback
      :timer.send_interval(2000, self(), :refresh)
    end

    socket = 
      socket
      |> assign(:greenhouse_id, greenhouse_id)
      |> assign(:page_title, "Greenhouse #{greenhouse_id}")
      |> assign(:temp_temperature, nil)
      |> assign(:temp_humidity, nil)
      |> assign(:temp_light, nil)
      |> assign(:debounce_timer_temperature, nil)
      |> assign(:debounce_timer_humidity, nil)
      |> assign(:debounce_timer_light, nil)
      |> load_greenhouse_data()

    {:ok, socket}
  end

  @impl true
  def handle_info(:refresh, socket) do
    {:noreply, load_greenhouse_data(socket)}
  end

  @impl true
  def handle_info({:greenhouse_created, read_model}, socket) do
    # Only update if this is the greenhouse we're viewing
    if read_model.greenhouse_id == socket.assigns.greenhouse_id do
      {:noreply, load_greenhouse_data(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:greenhouse_updated, read_model, _event_type}, socket) do
    # Only update if this is the greenhouse we're viewing
    if read_model.greenhouse_id == socket.assigns.greenhouse_id do
      {:noreply, load_greenhouse_data(socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:auto_save_temperature, temperature}, socket) do
    require Logger
    Logger.info("Auto-saving temperature: #{temperature}")
    
    case API.set_desired_temperature(socket.assigns.greenhouse_id, temperature) do
      :ok ->
        socket = 
          socket
          |> put_flash(:info, "Temperature set to #{temperature}°C")
          |> assign(:temp_temperature, nil)
          |> assign(:debounce_timer_temperature, nil)
          |> load_greenhouse_data()
        {:noreply, socket}
      
      {:error, reason} ->
        socket = 
          socket
          |> put_flash(:error, "Failed to set temperature: #{inspect(reason)}")
          |> assign(:debounce_timer_temperature, nil)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:auto_save_humidity, humidity}, socket) do
    require Logger
    Logger.info("Auto-saving humidity: #{humidity}")
    
    case API.set_desired_humidity(socket.assigns.greenhouse_id, humidity) do
      :ok ->
        socket = 
          socket
          |> put_flash(:info, "Humidity set to #{humidity}%")
          |> assign(:temp_humidity, nil)
          |> assign(:debounce_timer_humidity, nil)
          |> load_greenhouse_data()
        {:noreply, socket}
      
      {:error, reason} ->
        socket = 
          socket
          |> put_flash(:error, "Failed to set humidity: #{inspect(reason)}")
          |> assign(:debounce_timer_humidity, nil)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:auto_save_light, light}, socket) do
    require Logger
    Logger.info("Auto-saving light: #{light}")
    
    case API.set_desired_light(socket.assigns.greenhouse_id, light) do
      :ok ->
        socket = 
          socket
          |> put_flash(:info, "Light set to #{light}%")
          |> assign(:temp_light, nil)
          |> assign(:debounce_timer_light, nil)
          |> load_greenhouse_data()
        {:noreply, socket}
      
      {:error, reason} ->
        socket = 
          socket
          |> put_flash(:error, "Failed to set light: #{inspect(reason)}")
          |> assign(:debounce_timer_light, nil)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_temperature_slider", params, socket) do
    require Logger
    Logger.info("Temperature slider event received: #{inspect(params)}")
    
    case params do
      %{"value" => temp_str} ->
        case Float.parse(temp_str) do
          {temperature, _} ->
            Logger.info("Setting temp_temperature to: #{temperature}")
            
            # Cancel existing timer if any
            if socket.assigns.debounce_timer_temperature do
              Process.cancel_timer(socket.assigns.debounce_timer_temperature)
            end
            
            # Set up new debounced timer (1 second delay)
            timer = Process.send_after(self(), {:auto_save_temperature, temperature}, 1000)
            
            socket = 
              socket
              |> assign(:temp_temperature, temperature)
              |> assign(:debounce_timer_temperature, timer)
            
            {:noreply, socket}
          
          :error ->
            Logger.error("Failed to parse temperature: #{temp_str}")
            {:noreply, socket}
        end
      
      _ ->
        Logger.error("Unexpected params structure: #{inspect(params)}")
        {:noreply, socket}
    end
  end


  @impl true
  def handle_event("update_humidity_slider", params, socket) do
    require Logger
    Logger.info("Humidity slider event received: #{inspect(params)}")
    
    case params do
      %{"value" => humidity_str} ->
        case Float.parse(humidity_str) do
          {humidity, _} ->
            Logger.info("Setting temp_humidity to: #{humidity}")
            
            # Cancel existing timer if any
            if socket.assigns.debounce_timer_humidity do
              Process.cancel_timer(socket.assigns.debounce_timer_humidity)
            end
            
            # Set up new debounced timer (1 second delay)
            timer = Process.send_after(self(), {:auto_save_humidity, humidity}, 1000)
            
            socket = 
              socket
              |> assign(:temp_humidity, humidity)
              |> assign(:debounce_timer_humidity, timer)
            
            {:noreply, socket}
          
          :error ->
            Logger.error("Failed to parse humidity: #{humidity_str}")
            {:noreply, socket}
        end
      
      _ ->
        Logger.error("Unexpected params structure: #{inspect(params)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_light_slider", params, socket) do
    require Logger
    Logger.info("Light slider event received: #{inspect(params)}")
    
    case params do
      %{"value" => light_str} ->
        case Float.parse(light_str) do
          {light, _} ->
            Logger.info("Setting temp_light to: #{light}")
            
            # Cancel existing timer if any
            if socket.assigns.debounce_timer_light do
              Process.cancel_timer(socket.assigns.debounce_timer_light)
            end
            
            # Set up new debounced timer (1 second delay)
            timer = Process.send_after(self(), {:auto_save_light, light}, 1000)
            
            socket = 
              socket
              |> assign(:temp_light, light)
              |> assign(:debounce_timer_light, timer)
            
            {:noreply, socket}
          
          :error ->
            Logger.error("Failed to parse light: #{light_str}")
            {:noreply, socket}
        end
      
      _ ->
        Logger.error("Unexpected params structure: #{inspect(params)}")
        {:noreply, socket}
    end
  end



  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-200">
      <!-- Header -->
      <div class="bg-white dark:bg-gray-800 shadow transition-colors duration-200">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between items-center h-16">
            <div class="flex items-center">
              <.link navigate={~p"/"} class="text-green-600 hover:text-green-700 dark:text-green-400 dark:hover:text-green-300 mr-4 transition-colors duration-200">
                <.icon name="hero-arrow-left" class="h-6 w-6" />
              </.link>
              <.icon name="hero-home-modern" class="h-8 w-8 text-green-600 dark:text-green-400 mr-3" />
              <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                Greenhouse <%= @greenhouse_id %>
              </h1>
            </div>
            <div class="flex items-center space-x-2">
              <span class={[
                "inline-flex items-center px-3 py-1 rounded-full text-sm font-medium",
                status_color_class(@greenhouse.status)
              ]}>
                <%= @greenhouse.status %>
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <!-- Environmental Controls -->
        <div class="bg-white dark:bg-gray-800 shadow rounded-lg transition-colors duration-200">
          <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
            <h2 class="text-lg font-medium text-gray-900 dark:text-gray-100">Environmental Control</h2>
          </div>
          <div class="p-6">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
              <!-- Temperature Control -->
              <div class="text-center">
                <div class="mx-auto w-16 h-16 bg-red-100 dark:bg-red-800 rounded-full flex items-center justify-center mb-4">
                  <.icon name="hero-fire" class="h-8 w-8 text-red-600 dark:text-red-200" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-3">Temperature</h3>
                
                <!-- Current Reading -->
                <div class="mb-4">
                  <div class="text-3xl font-bold text-red-600 dark:text-red-400">
                    <%= format_integer(@greenhouse.current_temperature) %>°C
                  </div>
                  <div class="text-sm text-gray-500 dark:text-gray-400">Current</div>
                </div>
                
                <!-- Target Setting -->
                <div class="space-y-4">
                  <div class="px-3">
                    <form phx-change="update_temperature_slider">
                      <input 
                        type="range" 
                        name="value"
                        min="0" 
                        max="50" 
                        step="0.5" 
                        value={@temp_temperature || @greenhouse.desired_temperature || 20}
                        class="w-full h-2 bg-red-200 rounded-lg appearance-none cursor-pointer slider-red"
                      />
                    </form>
                    <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                      <span>0°C</span>
                      <span>50°C</span>
                    </div>
                  </div>
                  <div class="text-center">
                    <div class="text-lg font-semibold text-red-600 dark:text-red-400">
                      Target: <%= format_integer(@temp_temperature || @greenhouse.desired_temperature || 20) %>°C
                    </div>
                  </div>
                </div>
              </div>

              <!-- Humidity Control -->
              <div class="text-center">
                <div class="mx-auto w-16 h-16 bg-blue-100 dark:bg-blue-800 rounded-full flex items-center justify-center mb-4">
                  <.icon name="hero-cloud" class="h-8 w-8 text-blue-600 dark:text-blue-200" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-3">Humidity</h3>
                
                <!-- Current Reading -->
                <div class="mb-4">
                  <div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
                    <%= format_integer(@greenhouse.current_humidity) %>%
                  </div>
                  <div class="text-sm text-gray-500 dark:text-gray-400">Current</div>
                </div>
                
                <!-- Target Setting -->
                <div class="space-y-4">
                  <div class="px-3">
                    <form phx-change="update_humidity_slider">
                      <input 
                        type="range" 
                        name="value"
                        min="0" 
                        max="100" 
                        step="1" 
                        value={@temp_humidity || @greenhouse.desired_humidity || 50}
                        class="w-full h-2 bg-blue-200 rounded-lg appearance-none cursor-pointer slider-blue"
                      />
                    </form>
                    <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                      <span>0%</span>
                      <span>100%</span>
                    </div>
                  </div>
                  <div class="text-center">
                    <div class="text-lg font-semibold text-blue-600 dark:text-blue-400">
                      Target: <%= format_integer(@temp_humidity || @greenhouse.desired_humidity || 50) %>%
                    </div>
                  </div>
                </div>
              </div>

              <!-- Light Control -->
              <div class="text-center">
                <div class="mx-auto w-16 h-16 bg-yellow-100 dark:bg-yellow-800 rounded-full flex items-center justify-center mb-4">
                  <.icon name="hero-sun" class="h-8 w-8 text-yellow-600 dark:text-yellow-200" />
                </div>
                <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-3">Light</h3>
                
                <!-- Current Reading -->
                <div class="mb-4">
                  <div class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">
                    <%= format_integer(@greenhouse.current_light) %>%
                  </div>
                  <div class="text-sm text-gray-500 dark:text-gray-400">Current</div>
                </div>
                
                <!-- Target Setting -->
                <div class="space-y-4">
                  <div class="px-3">
                    <form phx-change="update_light_slider">
                      <input 
                        type="range" 
                        name="value"
                        min="0" 
                        max="100" 
                        step="1" 
                        value={@temp_light || @greenhouse.desired_light || 50}
                        class="w-full h-2 bg-yellow-200 rounded-lg appearance-none cursor-pointer slider-yellow"
                      />
                    </form>
                    <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                      <span>0%</span>
                      <span>100%</span>
                    </div>
                  </div>
                  <div class="text-center">
                    <div class="text-lg font-semibold text-yellow-600 dark:text-yellow-400">
                      Target: <%= format_integer(@temp_light || @greenhouse.desired_light || 50) %>%
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Recent Events -->
        <div class="mt-8">
          <div class="bg-white dark:bg-gray-800 shadow rounded-lg transition-colors duration-200">
            <div class="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
              <h2 class="text-lg font-medium text-gray-900 dark:text-gray-100">Recent Events</h2>
            </div>
            <div class="p-6">
              <%= if length(@greenhouse.events) > 0 do %>
                <div class="space-y-2">
                  <%= for event <- Enum.take(@greenhouse.events, 10) do %>
                    <div class="flex items-center space-x-3 py-2 px-3 bg-gray-50 dark:bg-gray-700 rounded transition-colors duration-200">
                      <div class="flex-shrink-0">
                        <div class={[
                          "w-2 h-2 rounded-full",
                          event_type_color(event.event_type)
                        ]}></div>
                      </div>
                      <div class="flex-1 min-w-0 flex items-center space-x-3">
                        <span class="text-sm font-medium text-gray-900 dark:text-gray-100 whitespace-nowrap">
                          <%= format_event_type(event.event_type) %>
                        </span>
                        <span class="text-sm text-gray-600 dark:text-gray-300">
                          <%= format_event_data(event) %>
                        </span>
                      </div>
                      <div class="flex-shrink-0">
                        <span class="text-xs text-gray-400 dark:text-gray-500 whitespace-nowrap">
                          <%= format_timestamp(event.created) %>
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <p class="text-gray-500 dark:text-gray-400 text-center py-8">No events recorded yet</p>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp load_greenhouse_data(socket) do
    greenhouse_id = socket.assigns.greenhouse_id
    
    case API.get_greenhouse_state(greenhouse_id) do
      {:ok, state} ->
        # Get recent events for display
        events = API.get_greenhouse_events(greenhouse_id, 20) || []
        require Logger
        Logger.info("GreenhouseLive: Loaded #{length(events)} events for greenhouse #{greenhouse_id}: #{inspect(events)}")
        
        greenhouse = %{
          id: greenhouse_id,
          current_temperature: state.current_temperature,
          current_humidity: state.current_humidity,
          current_light: state.current_light,
          desired_temperature: state.desired_temperature,
          desired_humidity: state.desired_humidity,
          desired_light: state.desired_light,
          status: determine_status(state),
          events: events,
          last_updated: state.last_updated
        }
        
        assign(socket, :greenhouse, greenhouse)
      
      {:error, _} ->
        greenhouse = %{
          id: greenhouse_id,
          current_temperature: 0,
          current_humidity: 0,
          current_light: 0,
          desired_temperature: nil,
          desired_humidity: nil,
          desired_light: nil,
          status: :unknown,
          events: [],
          last_updated: nil
        }
        
        assign(socket, :greenhouse, greenhouse)
    end
  end


  defp determine_status(state) do
    cond do
      state.current_temperature == 0 and state.current_humidity == 0 and state.current_light == 0 ->
        :inactive
      
      needs_attention?(state) ->
        :warning
      
      true ->
        :active
    end
  end

  defp needs_attention?(state) do
    (state.desired_temperature && abs(state.current_temperature - state.desired_temperature) > 5) ||
    (state.desired_humidity && abs(state.current_humidity - state.desired_humidity) > 20) ||
    (state.desired_light && abs(state.current_light - state.desired_light) > 30)
  end

  defp status_color_class(:active), do: "bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100"
  defp status_color_class(:warning), do: "bg-yellow-100 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-100"
  defp status_color_class(:inactive), do: "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200"
  defp status_color_class(_), do: "bg-red-100 text-red-800 dark:bg-red-800 dark:text-red-100"

  # Helper function to format numeric values as integers
  defp format_integer(value) when is_number(value), do: trunc(value)
  defp format_integer(value), do: value



  defp event_type_color("initialized:v1"), do: "bg-green-400"
  defp event_type_color("temperature_measured:v1"), do: "bg-red-400"
  defp event_type_color("humidity_measured:v1"), do: "bg-blue-400"
  defp event_type_color("light_measured:v1"), do: "bg-yellow-400"
  defp event_type_color("desired_temperature_set:v1"), do: "bg-red-600"
  defp event_type_color("desired_humidity_set:v1"), do: "bg-blue-600"
  defp event_type_color("desired_light_set:v1"), do: "bg-yellow-600"
  defp event_type_color(_), do: "bg-gray-400"

  defp format_event_type("initialized:v1"), do: "Greenhouse Initialized"
  defp format_event_type("temperature_measured:v1"), do: "Temperature Measured"
  defp format_event_type("humidity_measured:v1"), do: "Humidity Measured"
  defp format_event_type("light_measured:v1"), do: "Light Measured"
  defp format_event_type("desired_temperature_set:v1"), do: "Desired Temperature Set"
  defp format_event_type("desired_humidity_set:v1"), do: "Desired Humidity Set"
  defp format_event_type("desired_light_set:v1"), do: "Desired Light Set"
  defp format_event_type(type), do: type

  defp format_event_data(event) do
    data = event.data || %{}
    
    case event.event_type do
      "temperature_measured:v1" -> 
        temp = Map.get(data, :temperature) || "?"
        "#{format_integer(temp)}°C"
      "humidity_measured:v1" -> 
        humidity = Map.get(data, :humidity) || "?"
        "#{format_integer(humidity)}%"
      "light_measured:v1" -> 
        light = Map.get(data, :light) || "?"
        "#{format_integer(light)}%"
      "desired_temperature_set:v1" -> 
        temp = Map.get(data, :target_temperature) || "?"
        "Target: #{format_integer(temp)}°C"
      "desired_humidity_set:v1" -> 
        humidity = Map.get(data, :target_humidity) || "?"
        "Target: #{format_integer(humidity)}%"
      "desired_light_set:v1" -> 
        light = Map.get(data, :target_light) || "?"
        "Target: #{format_integer(light)}%"
      "initialized:v1" -> 
        name = Map.get(data, :name) || "Unknown"
        location = Map.get(data, :location) || "Unknown"
        "#{name} at #{location}"
      _ -> 
        "Data: #{inspect(data, limit: 3)}"
    end
  end

  defp format_timestamp(%DateTime{} = timestamp) do
    timestamp
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%m/%d %H:%M:%S")
  end

  defp format_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> 
        dt
        |> DateTime.shift_zone!("Etc/UTC")
        |> Calendar.strftime("%m/%d %H:%M:%S")
      
      _ -> 
        timestamp
    end
  end

  defp format_timestamp(timestamp), do: inspect(timestamp)

  @impl true
  def handle_event(event, params, socket) do
    require Logger
    Logger.info("Unhandled event: #{event} with params: #{inspect(params)}")
    {:noreply, socket}
  end
end
