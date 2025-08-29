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

    test "invalid changeset with missing name" do
      attrs = %{
        fields: [
          %{"key" => "word", "type" => "short_text", "required" => true}
        ]
      }

      changeset = CardTemplate.changeset(%CardTemplate{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset with missing fields" do
      attrs = %{name: "Test Template"}

      changeset = CardTemplate.changeset(%CardTemplate{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).fields
    end

    test "validates name length constraint" do
      long_name = String.duplicate("a", 101)

      attrs = %{
        name: long_name,
        fields: [%{"key" => "test", "type" => "short_text", "required" => true}]
      }

      changeset = CardTemplate.changeset(%CardTemplate{}, attrs)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "accepts name at maximum length" do
      max_name = String.duplicate("a", 100)

      attrs = %{
        name: max_name,
        fields: [%{"key" => "test", "type" => "short_text", "required" => true}]
      }

      changeset = CardTemplate.changeset(%CardTemplate{}, attrs)

      assert changeset.valid?
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

    test "accepts empty field list" do
      changeset =
        %CardTemplate{}
        |> CardTemplate.changeset(%{name: "Test", fields: []})

      assert changeset.valid?
    end

    test "accepts field keys with underscores and numbers" do
      fields = [
        %{"key" => "field_1", "type" => "short_text", "required" => true},
        %{"key" => "field_2_test", "type" => "short_text", "required" => false},
        %{"key" => "test123", "type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> CardTemplate.changeset(%{name: "Test", fields: fields})

      assert changeset.valid?
    end

    test "rejects fields that are not a list" do
      changeset =
        %CardTemplate{}
        |> change(%{fields: %{"invalid" => "structure"}})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "must be a list of field definitions" in errors_on(changeset).fields
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

    test "rejects fields with invalid key format - starts with number" do
      fields = [
        %{"key" => "1invalid", "type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid key format - contains spaces" do
      fields = [
        %{"key" => "invalid key", "type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid key format - contains hyphens" do
      fields = [
        %{"key" => "invalid-key", "type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid key format - uppercase letters" do
      fields = [
        %{"key" => "InvalidKey", "type" => "short_text", "required" => true}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with non-boolean required value" do
      fields = [
        %{"key" => "word", "type" => "short_text", "required" => "true"}
      ]

      changeset =
        %CardTemplate{}
        |> change(%{fields: fields})
        |> CardTemplate.validate_template_fields()

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with non-string key" do
      fields = [
        %{"key" => 123, "type" => "short_text", "required" => true}
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

    test "accepts nil fields (handled by required validation)" do
      changeset =
        %CardTemplate{}
        |> change(%{fields: nil})
        |> CardTemplate.validate_template_fields()

      # No error added by validate_template_fields, but will fail required validation
      refute "invalid field structure" in (errors_on(changeset)[:fields] || [])
      refute "must be a list of field definitions" in (errors_on(changeset)[:fields] || [])
    end
  end

  describe "field_types/0" do
    test "returns the list of allowed field types" do
      expected_types =
        ~w(short_text long_text audio_url image_url single_choice multiple_choice examples)

      assert CardTemplate.field_types() == expected_types
    end
  end
end
