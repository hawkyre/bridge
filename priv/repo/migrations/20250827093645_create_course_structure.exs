defmodule Bridge.Repo.Migrations.CreateCourseStructure do
  use Ecto.Migration

  def change do
    create table(:courses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, size: 100, null: false
      add :description, :string, size: 2000, null: false
      add :slug, :string, size: 70, null: false
      add :taught_language_code, :string, size: 5, null: false
      add :instruction_language_code, :string, size: 5, null: false
      add :visible, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:courses, [:slug])
    create index(:courses, [:taught_language_code])
    create index(:courses, [:instruction_language_code])
    create index(:courses, [:visible])

    create table(:tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, size: 40, null: false

      timestamps()
    end

    create unique_index(:tags, [:key])

    create table(:tag_translations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tag_id, references(:tags, type: :binary_id), null: false
      add :language_code, :string, size: 5, null: false
      add :name, :string, size: 100, null: false

      timestamps()
    end

    create unique_index(:tag_translations, [:tag_id, :language_code])
    create index(:tag_translations, [:language_code])

    create table(:lessons, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :course_id, references(:courses, type: :binary_id), null: false
      add :order, :integer, null: false
      add :level, :string, size: 30, null: false
      add :title, :string, size: 100, null: false
      add :description, :string, size: 2000, null: false
      add :slug, :string, size: 50, null: false
      add :markdown_content, :text, null: false
      add :visible, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:lessons, [:course_id, :slug])
    create index(:lessons, [:course_id])
    create index(:lessons, [:visible])
    create index(:lessons, [:level])
    create index(:lessons, [:order])

    create table(:lesson_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :lesson_id, references(:lessons, type: :binary_id), null: false
      add :tag_id, references(:tags, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:lesson_tags, [:lesson_id, :tag_id])
    create index(:lesson_tags, [:tag_id])

    create table(:card_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 100, null: false
      add :fields, {:array, :map}, null: false

      timestamps()
    end

    create index(:card_templates, [:name])

    create table(:template_mappings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :card_template_id, references(:card_templates, type: :binary_id), null: false
      add :use_case, :string, size: 50, null: false
      add :mapping, {:array, :map}, null: false

      timestamps()
    end

    create index(:template_mappings, [:card_template_id])
    create index(:template_mappings, [:use_case])

    # Vocabulary lists
    create table(:vocabulary_lists, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :course_id, references(:courses, type: :binary_id), null: false
      add :name, :string, size: 200, null: false
      add :slug, :string, size: 50, null: false

      timestamps()
    end

    create unique_index(:vocabulary_lists, [:slug])
    create index(:vocabulary_lists, [:course_id])

    # Vocabulary cards
    create table(:cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :course_id, references(:courses, type: :binary_id), null: false
      add :card_template_id, references(:card_templates, type: :binary_id), null: false
      add :fields, :map, null: false

      timestamps()
    end

    create index(:cards, [:course_id])
    create index(:cards, [:card_template_id])

    create table(:vocabulary_list_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :card_id, references(:cards, type: :binary_id), null: false
      add :vocabulary_list_id, references(:vocabulary_lists, type: :binary_id), null: false

      timestamps()
    end

    create unique_index(:vocabulary_list_cards, [:card_id, :vocabulary_list_id])
    create index(:vocabulary_list_cards, [:vocabulary_list_id])
  end
end
