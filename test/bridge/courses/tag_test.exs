defmodule Bridge.Courses.TagTest do
  use Bridge.DataCase, async: true

  alias Bridge.Courses.{Tag, Course}
  import Bridge.Factory

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      valid_attrs = %{
        key: "verbs"
      }

      changeset = Tag.changeset(%Tag{}, valid_attrs)

      assert changeset.valid?
      assert get_change(changeset, :key) == "verbs"
    end

    test "validates unique constraint on key" do
      attrs = %{key: "verbs"}

      assert {:ok, _} = Tag.changeset(%Tag{}, attrs) |> Repo.insert()
      assert {:error, changeset} = Tag.changeset(%Tag{}, attrs) |> Repo.insert()

      assert "has already been taken" in errors_on(changeset).key
    end
  end
end
