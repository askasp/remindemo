defmodule Remindemo.Presence do
  use Phoenix.Presence,
    otp_app: :remindemo,
    pubsub_server: Remindemo.PubSub
end

