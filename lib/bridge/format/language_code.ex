defmodule Bridge.Format.LanguageCode do
  @moduledoc """
  Module for validating language codes.
  """

  import Ecto.Changeset

  @doc """
  Validates a language code.
  """
  @spec validate(Ecto.Changeset.t(), atom) :: Ecto.Changeset.t()
  def validate(changeset, field \\ :language_code) do
    validate_format(changeset, field, ~r/^[a-z]{2}(-[a-z]{2})?$/,
      message: "must be a valid language code"
    )
  end
end
