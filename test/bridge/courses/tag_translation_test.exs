defmodule Bridge.Courses.TagTranslationTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.TagTranslation
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      tag = insert(:tag)

      valid_attrs = %{
        language_code: "es",
        name: "Verbos",
        tag_id: tag.id
      }

      changeset = TagTranslation.create_changeset(valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :language_code) == "es"
      assert get_change(changeset, :name) == "Verbos"
      assert get_change(changeset, :tag_id) == tag.id
    end

    test "validates unique constraint on tag_id and language_code" do
      tag = insert(:tag)

      attrs = %{
        language_code: "es",
        name: "Verbos",
        tag_id: tag.id
      }

      assert {:ok, _} = TagTranslation.create_changeset(attrs) |> Repo.insert()

      assert {:error, changeset} =
               TagTranslation.create_changeset(attrs) |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).tag_id
    end

    test "validates foreign key constraint for tag_id" do
      attrs = %{
        language_code: "es",
        name: "Verbos",
        tag_id: Ecto.UUID.generate()
      }

      changeset = TagTranslation.create_changeset(attrs)
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).tag_id
    end
  end
end
