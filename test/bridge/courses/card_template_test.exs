defmodule Bridge.Courses.CardTemplateTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.CardTemplate
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      valid_attrs = %{
        name: "Translation Card",
        fields: [
          %{"key" => "word", "type" => "short_text", "required" => true},
          %{"key" => "translation", "type" => "short_text", "required" => false},
          %{"key" => "audio", "type" => "audio_url", "required" => false}
        ]
      }

      changeset = CardTemplate.changeset(%CardTemplate{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :name) == "Translation Card"
      assert length(get_change(changeset, :fields)) == 3
    end

    test "invalid changeset with missing required fields" do
      changeset = CardTemplate.changeset(%CardTemplate{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).fields
    end
  end

  describe "validate_template_fields/1" do
    test "accepts valid field definitions" do
      fields = [
        %{"key" => "word", "type" => "short_text", "required" => true},
        %{"key" => "translation", "type" => "long_text", "required" => false},
        %{"key" => "audio_file", "type" => "audio_url", "required" => false},
        %{"key" => "image_file", "type" => "image_url", "required" => false},
        %{"key" => "choice", "type" => "single_choice", "required" => true},
        %{"key" => "choices", "type" => "multiple_choice", "required" => false},
        %{"key" => "examples_list", "type" => "examples", "required" => false}
      ]

      changeset =
        %CardTemplate{}
        |> CardTemplate.changeset(%{name: "Test", fields: fields})

      assert changeset.valid?
    end

    test "rejects empty field list" do
      changeset =
        %CardTemplate{}
        |> CardTemplate.changeset(%{name: "Test", fields: []})

      refute changeset.valid?
      assert "must have at least one field" in errors_on(changeset).fields
    end

    test "rejects fields with invalid structure - missing key" do
      fields = [
        %{"type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid structure - missing type" do
      fields = [
        %{"key" => "word", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid structure - missing required" do
      fields = [
        %{"key" => "word", "type" => "short_text"}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid type" do
      fields = [
        %{"key" => "word", "type" => "invalid_type", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with extra unexpected keys" do
      fields = [
        %{"key" => "word", "type" => "short_text", "required" => true, "extra" => "field"}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end
  end
end
