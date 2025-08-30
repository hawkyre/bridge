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
  end
end
