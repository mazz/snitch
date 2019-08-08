defmodule SnitchWeb.WebhookController do
  use SnitchWeb, :controller

  alias Snitch.Channels
  alias Snitch.Channels.Channel

  def mux(conn, params) do
    if String.match?(params["type"], ~r/^video\.live_stream/) do
      mux_resource = params["data"]
      mux_live_stream_id = mux_resource["id"]
      channel = Channels.find_by_mux_live_stream_id(mux_live_stream_id)

      if channel do
        case Channels.update_from_mux_webhook(channel, params) do
          {:ok, _channel} ->
            json(conn, %{message: "channel updated"})

          {:error, %Ecto.Changeset{} = changeset} ->
            IO.inspect(changeset)

            conn
            |> put_status(500)
            |> json(%{message: "error updating channel", error: changeset})
        end
      else
        json(conn, %{message: "No channel found with that live stream id"})
      end
    else
      json(conn, %{message: "Ignoring non-live stream webhook"})
    end
  end

  def mux_webhook1(conn, params) do
    secret = "tvji2paub0ubtlitmdvmspmaji17v3p5"
    signature_header = List.first(get_req_header(conn, "mux-signature"))
    raw_body = List.first(conn.private[:raw_body])
    IO.inspect(raw_body)
    IO.inspect(signature_header)
    case Mux.Webhooks.verify_header(raw_body, signature_header, secret, 3000) do
      :ok ->
        text(conn, "From Elixir: valid")
      {:error, message} ->
        text(conn, "From Elixir: Error: #{message}")
    end
  end
end
