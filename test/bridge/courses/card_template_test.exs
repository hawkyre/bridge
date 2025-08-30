defmodule Bridge.Courses.CardTemplateTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.CardTemplate
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      valid_attrs = %{
        name: "Translation Card",
        fields: [
          %{"key" => "word", "name" => "Word", "type" => "short_text", "required" => true},
          %{
            "key" => "translation",
            "name" => "Translation",
            "type" => "short_text",
            "required" => false
          },
          %{"key" => "audio", "name" => "Audio", "type" => "audio_url", "required" => false}
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
        %{"key" => "word", "name" => "Word", "type" => "short_text", "required" => true},
        %{
          "key" => "translation",
          "name" => "Translation",
          "type" => "long_text",
          "required" => false
        },
        %{
          "key" => "audio_file",
          "name" => "Audio File",
          "type" => "audio_url",
          "required" => false
        },
        %{
          "key" => "image_file",
          "name" => "Image File",
          "type" => "image_url",
          "required" => false
        },
        %{
          "key" => "image_file",
          "name" => "Image File",
          "type" => "image_url",
          "required" => false
        },
        %{
          "key" => "single_choice",
          "name" => "Single Choice",
          "type" => "single_choice",
          "required" => true,
          "metadata" => %{"choices" => ["choice1", "choice2"]}
        },
        %{
          "key" => "multiple_choice",
          "name" => "Multiple Choice",
          "type" => "multiple_choice",
          "required" => false,
          "metadata" => %{"choices" => ["choice1", "choice2"]}
        },
        %{"key" => "examples", "name" => "Examples", "type" => "examples", "required" => false}
      ]

      for field <- fields do
        changeset =
          %CardTemplate{}
          |> CardTemplate.changeset(%{name: "Test", fields: [field]})

        assert changeset.valid?, "Field #{field["name"]} is not valid"
      end
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
        %{"name" => "Word", "type" => "short_text", "required" => true}
      ]

      changeset = CardTemplate.create_changeset(params_for(:card_template, fields: fields))

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end

    test "rejects fields with invalid type" do
      fields = [
        %{"key" => "word", "name" => "Word", "type" => "invalid_type", "required" => true}
      ]

      changeset = CardTemplate.create_changeset(params_for(:card_template, fields: fields))

      refute changeset.valid?
      assert "invalid field structure" in errors_on(changeset).fields
    end
  end
end
