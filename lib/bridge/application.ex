defmodule Bridge.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BridgeWeb.Telemetry,
      Bridge.Repo,
      {DNSCluster, query: Application.get_env(:bridge, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bridge.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Bridge.Finch},
      # Start a worker by calling: Bridge.Worker.start_link(arg)
      # {Bridge.Worker, arg},
      # Start to serve requests, typically the last entry
      BridgeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bridge.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BridgeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
