defmodule Bridge.Courses.TemplateMappingTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{TemplateMapping, CardTemplate}

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "word", "type" => "short_text"},
            %{"key" => "translation", "type" => "short_text"},
            %{"key" => "example", "type" => "examples"}
          ]
        )

      attrs = %{
        use_case: "flashcard",
        mapping: [
          %{"key" => "front", "value" => "{{word}}", "type" => "text"},
          %{"key" => "back", "value" => "{{translation}} - {{example}}", "type" => "text"}
        ],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.create_changeset(attrs)

      assert changeset.valid?
      assert get_change(changeset, :use_case) == "flashcard"
      assert length(get_change(changeset, :mapping)) == 2
      assert get_change(changeset, :card_template_id) == card_template.id
    end

    test "rejects mapping with fields without template fields" do
      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "word", "type" => "short_text"},
            %{"key" => "translation", "type" => "short_text"},
            %{"key" => "example", "type" => "examples"}
          ]
        )

      attrs = %{
        use_case: "case",
        mapping: [
          %{"key" => "valid", "value" => "{{translation}}", "type" => "text"},
          %{"key" => "invalid", "value" => "no template fields", "type" => "text"}
        ],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.create_changeset(attrs)

      refute changeset.valid?

      assert "invalid mapping structure" =~
               errors_on(changeset).mapping |> hd()
    end

    test "rejects mapping with fields with single brackets" do
      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "word", "type" => "short_text"},
            %{"key" => "translation", "type" => "short_text"},
            %{"key" => "example", "type" => "examples"}
          ]
        )

      attrs = %{
        use_case: "case",
        mapping: [
          %{"key" => "valid", "value" => "{translation}", "type" => "text"}
        ],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.create_changeset(attrs)

      refute changeset.valid?

      assert "invalid mapping structure" =~
               errors_on(changeset).mapping |> hd()
    end

    test "rejects mapping with invalid field keys" do
      card_template =
        insert(:card_template,
          fields: [
            %{"key" => "word", "type" => "short_text"},
            %{"key" => "translation", "type" => "short_text"},
            %{"key" => "example", "type" => "examples"}
          ]
        )

      attrs = %{
        use_case: "case",
        mapping: [
          %{"key" => "invalid", "value" => "{{words}}", "type" => "text"}
        ],
        card_template_id: card_template.id
      }

      changeset = TemplateMapping.create_changeset(attrs)

      refute changeset.valid?

      assert "invalid mapping structure" =~
               errors_on(changeset).mapping |> hd()
    end

    test "validates foreign key constraint for card_template_id" do
      attrs = %{
        use_case: "flashcard",
        mapping: [%{"key" => "front", "value" => "{{word}}", "type" => "text"}],
        card_template_id: Ecto.UUID.generate()
      }

      changeset = TemplateMapping.create_changeset(attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).card_template_id
    end
  end
end
