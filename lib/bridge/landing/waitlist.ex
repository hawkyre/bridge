defmodule Bridge.Landing.Waitlist do
  @moduledoc """
  A module for managing the waitlist, basically adding the emails to it.
  """

  alias Bridge.Landing.WaitlistEmail
  alias Bridge.Repo

  @doc """
  Adds an email to the waitlist.
  """
  @spec add(String.t()) :: {:ok, WaitlistEmail.t()} | {:error, Ecto.Changeset.t()}
  def add(email) do
    %WaitlistEmail{email: email}
    |> WaitlistEmail.changeset(%{email: email})
    |> Repo.insert()
  end
end
