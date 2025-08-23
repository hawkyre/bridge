defmodule BridgeWeb.PageController do
  @moduledoc """
  Handles the landing page and waitlist registration.
  """

  use BridgeWeb, :controller

  alias Bridge.Landing.Waitlist

  def home(conn, _params) do
    render(conn, :home)
  end

  def register_email(conn, %{"email" => email}) do
    case Waitlist.add(email) do
      {:ok, _subscription} ->
        conn
        |> put_flash(:info, "🎉 Welcome to the revolution! You're on the list for early access.")
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{errors: [email: {_, [constraint: :unique, constraint_name: _]}]}} ->
        conn
        |> put_flash(:info, "🎉 Welcome to the revolution! You're on the list for early access.")
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "❌ Oops! Please enter a valid email address.")
        |> redirect(to: ~p"/")
    end
  end
end
