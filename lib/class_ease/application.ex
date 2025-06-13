defmodule ClassEase.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ClassEaseWeb.Telemetry,
      ClassEase.Repo,
      {DNSCluster, query: Application.get_env(:class_ease, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ClassEase.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ClassEase.Finch},
      # Start a worker by calling: ClassEase.Worker.start_link(arg)
      # {ClassEase.Worker, arg},
      # Start to serve requests, typically the last entry
      ClassEaseWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ClassEase.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ClassEaseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
