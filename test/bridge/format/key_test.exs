defmodule Bridge.Format.KeyTest do
  use Bridge.DataCase, async: true

  alias Bridge.Format.Key
  import Ecto.Changeset

  describe "validate/1" do
    test "accepts valid keys" do
      valid_keys = [
        "word",
        "audio_url",
        "a1_dutch",
        "test123",
        "long_key_with_multiple_underscores",
        "a",
        "z9"
      ]

      for key <- valid_keys do
        changeset = cast({%{}, %{key: :string}}, %{key: key}, [:key])
        result = Key.validate(changeset)

        assert result.valid?,
               "Expected '#{key}' to be valid but got errors: #{inspect(result.errors)}"
      end
    end

    test "rejects invalid keys" do
      invalid_cases = [
        "1word",
        "_word",
        "Word",
        "camelCase",
        "word-with-dashes",
        "word.with.dots",
        "word with spaces",
        "word@symbol",
        "word__double",
        "word_"
      ]

      for key <- invalid_cases do
        changeset = cast({%{}, %{key: :string}}, %{key: key}, [:key])
        result = Key.validate(changeset)

        refute result.valid?, "Expected '#{key}' to be invalid"
      end
    end
  end
end
