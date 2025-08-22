defmodule BridgeWeb.PageController do
  use BridgeWeb, :controller
  alias Bridge.Repo
  alias Bridge.Bridge.EmailSubscription

  def home(conn, _params) do
    # Use the app layout to show the navbar
    render(conn, :home)
  end

  def register_email(conn, %{"email" => email}) do
    changeset = EmailSubscription.changeset(%EmailSubscription{}, %{email: email})

    case Repo.insert(changeset) do
      {:ok, _subscription} ->
        conn
        |> put_flash(:info, "🎉 Welcome to the revolution! You're on the list for early access.")
        |> redirect(to: ~p"/")

      {:error, %Ecto.Changeset{errors: [email: {_, [constraint: :unique, constraint_name: _]}]}} ->
        conn
        |> put_flash(:info, "💚 You're already signed up! We'll be in touch soon.")
        |> redirect(to: ~p"/")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "❌ Oops! Please enter a valid email address.")
        |> redirect(to: ~p"/")
    end
  end
end
