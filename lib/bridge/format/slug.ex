defmodule Bridge.Format.Slug do
  @moduledoc """
  Module for validating slugs.
  """

  import Ecto.Changeset

  @doc """
  Formats a slug.

  Valid slug examples:
  - "spanish"
  - "spanish-2-beginners"
  - "a1-dutch"
  """
  @spec validate(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate(changeset) do
    validate_format(changeset, :slug, ~r/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/,
      message:
        "must only contain lowercase letters, numbers, and hyphens, and start with a letter"
    )
  end
end
