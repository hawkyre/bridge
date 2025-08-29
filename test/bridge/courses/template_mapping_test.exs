defmodule Bridge.Courses.TemplateMappingTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{TemplateMapping, CardTemplate}

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      card_template = insert(:card_template)

      valid_attrs = %{
        use_case: "flashcard",
        mapping: [
          %{"key" => "front", "value" => "{{word}}"},
          %{"key" => "back", "value" => "{{translation}} - {{example}}"}
        ],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :use_case) == "flashcard"
      assert length(get_change(changeset, :mapping)) == 2
      assert get_change(changeset, :card_template_id) == card_template.id
    end

    test "invalid changeset with missing required fields" do
      changeset = TemplateMapping.changeset(%TemplateMapping{}, %{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).use_case
      assert "can't be blank" in errors_on(changeset).mapping
      assert "can't be blank" in errors_on(changeset).card_template_id
    end

    test "invalid changeset with missing use_case" do
      card_template = insert(:card_template)

      attrs = %{
        mapping: [%{"key" => "front", "value" => "{{word}}"}],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).use_case
    end

    test "invalid changeset with missing mapping" do
      card_template = insert(:card_template)

      attrs = %{
        use_case: "flashcard",
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).mapping
    end

    test "invalid changeset with missing card_template_id" do
      attrs = %{
        use_case: "flashcard",
        mapping: [%{"key" => "front", "value" => "{{word}}"}]
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).card_template_id
    end

    test "validates use_case length constraint" do
      card_template = insert(:card_template)
      long_use_case = String.duplicate("a", 51)

      attrs = %{
        use_case: long_use_case,
        mapping: [%{"key" => "front", "value" => "{{word}}"}],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)

      refute changeset.valid?
      assert "should be at most 50 character(s)" in errors_on(changeset).use_case
    end

    test "validates foreign key constraint for card_template_id" do
      attrs = %{
        use_case: "flashcard",
        mapping: [%{"key" => "front", "value" => "{{word}}"}],
        card_template_id: Ecto.UUID.generate()
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).card_template_id
    end

    test "accepts maximum length use_case" do
      card_template = insert(:card_template)
      max_use_case = String.duplicate("a", 50)

      attrs = %{
        use_case: max_use_case,
        mapping: [%{"key" => "front", "value" => "{{word}}"}],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.changeset(%TemplateMapping{}, attrs)

      assert changeset.valid?
    end
  end

  describe "validate_mapping_structure/1" do
    test "accepts valid mapping structure" do
      mapping = [
        %{"key" => "front", "value" => "{{word}}"},
        %{"key" => "back", "value" => "{{translation}}"},
        %{"key" => "example", "value" => "Example: {{example_sentence}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end

    test "accepts empty mapping list" do
      changeset =
        %TemplateMapping{}
        |> change(%{mapping: []})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end

    test "accepts mapping keys with underscores and numbers" do
      mapping = [
        %{"key" => "front_side", "value" => "{{word}}"},
        %{"key" => "back_side_1", "value" => "{{translation}}"},
        %{"key" => "example_123", "value" => "{{example}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end

    test "accepts complex template strings" do
      mapping = [
        %{
          "key" => "complex",
          "value" => "Word: {{word}}, Translation: {{translation}}, Example: {{example}}"
        }
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end

    test "rejects mapping that is not a list" do
      changeset =
        %TemplateMapping{}
        |> change(%{mapping: %{"invalid" => "structure"}})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "must be a list of mapping definitions" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid structure - missing key" do
      mapping = [
        %{"value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid structure - missing value" do
      mapping = [
        %{"key" => "front"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid key format - starts with number" do
      mapping = [
        %{"key" => "1invalid", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid key format - contains spaces" do
      mapping = [
        %{"key" => "invalid key", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid key format - contains hyphens" do
      mapping = [
        %{"key" => "invalid-key", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with invalid key format - uppercase letters" do
      mapping = [
        %{"key" => "InvalidKey", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with non-string key" do
      mapping = [
        %{"key" => 123, "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with non-string value" do
      mapping = [
        %{"key" => "front", "value" => 123}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "rejects mapping with extra unexpected keys" do
      mapping = [
        %{"key" => "front", "value" => "{{word}}", "extra" => "field"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "accepts nil mapping (handled by required validation)" do
      changeset =
        %TemplateMapping{}
        |> change(%{mapping: nil})
        |> TemplateMapping.validate_mapping_structure()

      # No error added by validate_mapping_structure, but will fail required validation
      refute "invalid mapping structure" in (errors_on(changeset)[:mapping] || [])
      refute "must be a list of mapping definitions" in (errors_on(changeset)[:mapping] || [])
    end

    test "handles mixed valid and invalid mapping definitions" do
      mapping = [
        # valid
        %{"key" => "valid", "value" => "{{word}}"},
        # invalid
        %{"key" => "invalid-key", "value" => "{{translation}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      refute changeset.valid?
      assert "invalid mapping structure" in errors_on(changeset).mapping
    end

    test "accepts single character keys" do
      mapping = [
        %{"key" => "a", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end

    test "accepts keys starting with underscore" do
      mapping = [
        %{"key" => "_private", "value" => "{{word}}"}
      ]

      changeset =
        %TemplateMapping{}
        |> change(%{mapping: mapping})
        |> TemplateMapping.validate_mapping_structure()

      assert changeset.valid?
    end
  end

  # Test helpers
  defp card_template_fixture do
    %CardTemplate{}
    |> CardTemplate.changeset(%{
      name: "Translation Card",
      fields: [
        %{"key" => "word", "type" => "short_text", "required" => true},
        %{"key" => "translation", "type" => "short_text", "required" => true},
        %{"key" => "example", "type" => "long_text", "required" => false}
      ]
    })
    |> Repo.insert!()
  end
end
