defmodule Bridge.Format.Key do
  @moduledoc """
  Module for validating keys.
  """

  import Ecto.Changeset

  @doc """
  Validates that the key is a valid key.

  Valid key examples:
  - "word"
  - "audio_url"
  - "a1_dutch"
  """
  @spec validate(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def validate(changeset) do
    validate_format(changeset, :key, ~r/^[a-z][a-z0-9]*(_[a-z0-9]+)*$/,
      message:
        "must only contain lowercase letters, numbers, and underscores, and start with a letter"
    )
  end

  @doc """
  Returns the regex for the key.

  Accepts a :string or :regex atom. If :string is passed, the regex is returned as a string to be used in other regexes dynamically.
  """
  @spec regex(:regex | :string) :: Regex.t() | String.t()
  def regex(format \\ :regex)

  def regex(:string) do
    regex(:regex) |> Regex.source()
  end

  def regex(:regex) do
    ~r/[a-z][a-z0-9]*(_[a-z0-9]+)*/
  end
end
