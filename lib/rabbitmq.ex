defmodule RabbitMQ.System do
  @doc """
  Creates the exchange, the queues and their bindings.
  If the exchange and queues already exist, does nothing.
  """
  def setup(exchange_name, queue_names) do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection) 
    AMQP.Exchange.declare(channel, exchange_name, :direct)
    Enum.map(queue_names, & AMQP.Queue.declare(channel, &1))
    Enum.map(queue_names, & AMQP.Queue.bind(channel, &1, exchange_name, routing_key: &1))
    :ok
  end
end

defmodule RabbitMQ.Producer do
  @doc """
  Sends n messages with payload 'msg' and the given routing key.
  """
  def send(exchange, routing_key, msg, n) do 
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection) 
    for n <- 1..n do
      AMQP.Basic.publish(channel, exchange, routing_key, msg)
      IO.puts("Sending: #{msg}. #{n}")
    end
    :ok
  end
end

defmodule RabbitMQ.Consumer do
  require Logger
  @doc """
  Creates a process that listens for messages on the given queue.
  When a message arrives, it writes to the log the pid, queue_name and msg.
  Example:
    iex> {:ok, pid} = Consumer.start("orders")
  """
  def start(queue_name) do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection) 
    pid = spawn(RabbitMQ.Consumer, :consumer, [channel])
    AMQP.Basic.consume(channel, queue_name, pid, no_ack: true)
    pid
  end

  @doc """
  Stops the given consumer.
  Example:
    iex> Consumer.stop("orders")
  """
  def stop(pid), do: Process.exit(pid, :kill)

  def consumer(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        Logger.info("PID: #{inspect(self())}, Queue: #{meta.routing_key} , Msg: #{payload}")
        #IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
        meta
    end
    consumer(channel)  
  end
end
