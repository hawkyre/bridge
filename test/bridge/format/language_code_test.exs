defmodule Bridge.Format.LanguageCodeTest do
  use Bridge.DataCase, async: true

  alias Bridge.Format.LanguageCode
  import Ecto.Changeset

  describe "validate/2" do
    test "accepts valid language codes with default field" do
      valid_codes = [
        "en",
        "es",
        "fr",
        "de",
        "pt",
        "zh",
        "ja",
        "ko"
      ]

      for code <- valid_codes do
        changeset =
          cast({%{}, %{language_code: :string}}, %{language_code: code}, [:language_code])

        result = LanguageCode.validate(changeset)

        assert result.valid?,
               "Expected '#{code}' to be valid but got errors: #{inspect(result.errors)}"
      end
    end

    test "accepts valid language codes with region" do
      valid_codes = [
        "en-us",
        "en-gb",
        "es-es",
        "es-mx",
        "pt-br",
        "zh-cn",
        "fr-ca"
      ]

      for code <- valid_codes do
        changeset =
          cast({%{}, %{language_code: :string}}, %{language_code: code}, [:language_code])

        result = LanguageCode.validate(changeset)

        assert result.valid?,
               "Expected '#{code}' to be valid but got errors: #{inspect(result.errors)}"
      end
    end

    test "accepts valid language codes with custom field" do
      valid_codes = ["en", "es-mx", "fr-ca"]

      for code <- valid_codes do
        changeset = cast({%{}, %{custom_lang: :string}}, %{custom_lang: code}, [:custom_lang])
        result = LanguageCode.validate(changeset, :custom_lang)

        assert result.valid?,
               "Expected '#{code}' to be valid for custom field but got errors: #{inspect(result.errors)}"
      end
    end

    test "rejects invalid language codes" do
      invalid_cases = [
        "e",
        "eng",
        "english",
        "EN",
        "En",
        "en-US",
        "en_us",
        "en.us",
        "en us",
        "e1",
        "en-u1",
        "e@",
        "en-u$",
        "en-usa",
        "en-u",
        "en-us-ca"
      ]

      for code <- invalid_cases do
        changeset =
          cast({%{}, %{language_code: :string}}, %{language_code: code}, [:language_code])

        result = LanguageCode.validate(changeset)

        refute result.valid?, "Expected '#{code}' to be invalid"
      end
    end
  end
end
