defmodule Bridge.Fixtures do
  @moduledoc """
  Test fixtures for creating test data using Faker.

  This module provides functions to create realistic test data for all
  schemas in the Bridge application, making tests more maintainable
  and providing better test coverage with varied data.
  """

  alias Bridge.Repo

  alias Bridge.Courses.{
    Course,
    Lesson,
    LessonTag,
    LessonTagInLesson,
    TagTranslation,
    CardTemplate,
    Card,
    TemplateMapping,
    VocabularyList,
    VocabularyListCard
  }

  @doc """
  Creates a course with realistic fake data.

  ## Examples

      iex> course = Fixtures.course_fixture()
      iex> course.title
      "Advanced Spanish Grammar"

      iex> course = Fixtures.course_fixture(%{title: "Custom Title"})
      iex> course.title
      "Custom Title"
  """
  def course_fixture(attrs \\ %{}) do
    language_pairs = [
      # Spanish taught in English
      {"es", "en"},
      # French taught in English
      {"fr", "en"},
      # German taught in English
      {"de", "en"},
      # Portuguese taught in English
      {"pt", "en"},
      # Italian taught in English
      {"it", "en"},
      # Japanese taught in English
      {"ja", "en"},
      # Korean taught in English
      {"ko", "en"},
      # Chinese taught in English
      {"zh", "en"},
      # Arabic taught in English
      {"ar", "en"},
      # Russian taught in English
      {"ru", "en"}
    ]

    {taught_lang, instruction_lang} = Enum.random(language_pairs)
    language_name = language_name_for_code(taught_lang)

    course_levels = ["Beginner", "Intermediate", "Advanced", "Expert"]
    level = Enum.random(course_levels)

    course_hash = Ecto.UUID.generate() |> String.slice(0, 8)

    title = "#{level} #{language_name} #{course_hash}"
    slug = title |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-")

    attrs =
      Map.merge(
        %{
          title: title,
          description: Faker.Lorem.sentence(10..25),
          slug: slug,
          taught_language_code: taught_lang,
          instruction_language_code: instruction_lang,
          visible: Enum.random([true, false])
        },
        Enum.into(attrs, %{})
      )

    %Course{}
    |> Course.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a lesson with realistic fake data.
  """
  def lesson_fixture(course \\ nil, attrs \\ %{}) do
    course = course || course_fixture()

    topic = Ecto.UUID.generate() |> String.slice(0, 13)
    order = attrs[:order] || Enum.random(1..50)

    level = 1..6 |> Enum.random() |> Integer.to_string()

    title =
      topic
      |> String.replace("-", " ")
      |> String.split()
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    slug =
      if Map.has_key?(attrs, :slug) do
        attrs[:slug]
      else
        "#{topic}-#{order}"
      end

    # Generate realistic markdown content
    markdown_content = generate_lesson_markdown(title, topic)

    attrs =
      %{
        order: order,
        level: level,
        title: "Lesson #{order}: #{title}",
        description: Faker.Lorem.sentence(8..20),
        slug: slug,
        markdown_content: markdown_content,
        visible: Enum.random([true, false]),
        course_id: course.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %Lesson{}
    |> Lesson.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a lesson tag with realistic fake data.
  """
  def lesson_tag_fixture(course \\ nil, attrs \\ %{}) do
    course = course || course_fixture()

    tag_keys = [
      "verbs",
      "nouns",
      "adjectives",
      "adverbs",
      "pronouns",
      "prepositions",
      "articles",
      "conjunctions",
      "tenses",
      "grammar",
      "vocabulary",
      "phonetics",
      "syntax",
      "morphology",
      "semantics",
      "pragmatics",
      "conversation",
      "writing",
      "reading",
      "listening",
      "speaking",
      "culture",
      "history",
      "literature"
    ]

    key = attrs[:key] || Enum.random(tag_keys)

    attrs =
      %{
        key: key,
        course_id: course.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %LessonTag{}
    |> LessonTag.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a lesson tag in lesson association.
  """
  def lesson_tag_in_lesson_fixture(lesson \\ nil, lesson_tag \\ nil, attrs \\ %{}) do
    lesson = lesson || lesson_fixture()
    lesson_tag = lesson_tag || lesson_tag_fixture()

    attrs =
      %{
        lesson_id: lesson.id,
        lesson_tag_id: lesson_tag.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %LessonTagInLesson{}
    |> LessonTagInLesson.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a tag translation with realistic fake data.
  """
  def tag_translation_fixture(lesson_tag \\ nil, attrs \\ %{}) do
    lesson_tag = lesson_tag || lesson_tag_fixture()

    language_codes = ["en", "es", "fr", "de", "pt", "it", "ja", "ko", "zh", "ar", "ru"]
    language_code = attrs[:language_code] || Enum.random(language_codes)

    # Generate translation based on the tag key and language
    name = translate_tag_name(lesson_tag.key, language_code)

    attrs =
      %{
        language_code: language_code,
        name: name,
        lesson_tag_id: lesson_tag.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %TagTranslation{}
    |> TagTranslation.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a card template with realistic fake data.
  """
  def card_template_fixture(attrs \\ %{}) do
    template_types = [
      {"Translation Card",
       [
         %{"key" => "word", "type" => "short_text", "required" => true},
         %{"key" => "translation", "type" => "short_text", "required" => true},
         %{"key" => "pronunciation", "type" => "short_text", "required" => false},
         %{"key" => "example", "type" => "long_text", "required" => false}
       ]},
      {"Audio Vocabulary Card",
       [
         %{"key" => "word", "type" => "short_text", "required" => true},
         %{"key" => "audio_url", "type" => "audio_url", "required" => true},
         %{"key" => "translation", "type" => "short_text", "required" => true},
         %{"key" => "context", "type" => "long_text", "required" => false}
       ]},
      {"Image Vocabulary Card",
       [
         %{"key" => "word", "type" => "short_text", "required" => true},
         %{"key" => "image_url", "type" => "image_url", "required" => true},
         %{"key" => "description", "type" => "long_text", "required" => false}
       ]},
      {"Multiple Choice Card",
       [
         %{"key" => "question", "type" => "long_text", "required" => true},
         %{"key" => "choices", "type" => "multiple_choice", "required" => true},
         %{"key" => "explanation", "type" => "long_text", "required" => false}
       ]},
      {"Grammar Example Card",
       [
         %{"key" => "rule", "type" => "short_text", "required" => true},
         %{"key" => "examples", "type" => "examples", "required" => true},
         %{"key" => "notes", "type" => "long_text", "required" => false}
       ]}
    ]

    {default_name, default_fields} = Enum.random(template_types)

    # Override defaults with any provided attributes
    name = Map.get(attrs, :name, default_name)
    fields = Map.get(attrs, :fields, default_fields)

    final_attrs = %{
      name: name,
      fields: fields
    }

    %CardTemplate{}
    |> CardTemplate.changeset(final_attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a card with realistic fake data.
  """
  def card_fixture(course \\ nil, card_template \\ nil, attrs \\ %{}) do
    course = course || course_fixture()
    card_template = card_template || card_template_fixture()

    # Generate fields based on the card template
    fields = generate_card_fields(card_template)

    attrs =
      %{
        fields: fields,
        course_id: course.id,
        card_template_id: card_template.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a template mapping with realistic fake data.
  """
  def template_mapping_fixture(card_template \\ nil, attrs \\ %{}) do
    card_template = card_template || card_template_fixture()

    use_cases = ["flashcard", "study_mode", "quiz", "review", "practice"]
    use_case = attrs[:use_case] || Enum.random(use_cases)

    # Generate mapping based on use case and template fields
    mapping = generate_template_mapping(use_case, card_template.fields)

    attrs =
      %{
        use_case: use_case,
        mapping: mapping,
        card_template_id: card_template.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %TemplateMapping{}
    |> TemplateMapping.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a vocabulary list with realistic fake data.
  """
  def vocabulary_list_fixture(course \\ nil, attrs \\ %{}) do
    course = course || course_fixture()

    list_topics = [
      "basic-vocabulary",
      "advanced-words",
      "business-terms",
      "travel-phrases",
      "food-drinks",
      "family-relationships",
      "clothing-accessories",
      "body-parts",
      "animals-nature",
      "technology-internet",
      "sports-activities",
      "music-arts",
      "education-school",
      "health-medical",
      "transportation",
      "emotions-feelings"
    ]

    topic = Enum.random(list_topics)

    name =
      topic
      |> String.replace("-", " ")
      |> String.split()
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    slug =
      if Map.has_key?(attrs, :slug) do
        attrs[:slug]
      else
        "#{topic}-#{Enum.random(1..999)}"
      end

    attrs =
      %{
        name: name,
        slug: slug,
        course_id: course.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %VocabularyList{}
    |> VocabularyList.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a vocabulary list card association.
  """
  def vocabulary_list_card_fixture(vocabulary_list \\ nil, card \\ nil, attrs \\ %{}) do
    vocabulary_list = vocabulary_list || vocabulary_list_fixture()
    card = card || card_fixture()

    attrs =
      %{
        vocabulary_list_id: vocabulary_list.id,
        card_id: card.id
      }
      |> Map.merge(Enum.into(attrs, %{}))

    %VocabularyListCard{}
    |> VocabularyListCard.changeset(attrs)
    |> Repo.insert!()
  end

  # Private helper functions

  defp language_name_for_code("es"), do: "Spanish"
  defp language_name_for_code("fr"), do: "French"
  defp language_name_for_code("de"), do: "German"
  defp language_name_for_code("pt"), do: "Portuguese"
  defp language_name_for_code("it"), do: "Italian"
  defp language_name_for_code("ja"), do: "Japanese"
  defp language_name_for_code("ko"), do: "Korean"
  defp language_name_for_code("zh"), do: "Chinese"
  defp language_name_for_code("ar"), do: "Arabic"
  defp language_name_for_code("ru"), do: "Russian"
  defp language_name_for_code(_), do: "Language"

  defp generate_lesson_markdown(title, topic) do
    """
    # #{title}

    ## Introduction

    #{Faker.Lorem.paragraph(2..4)}

    ## Key Concepts

    #{generate_key_concepts(topic)}

    ## Examples

    #{generate_examples(topic)}

    ## Practice

    #{Faker.Lorem.paragraph(1..2)}

    ## Summary

    #{Faker.Lorem.sentence(5..10)}
    """
  end

  defp generate_key_concepts(topic) do
    concepts =
      case topic do
        "verbs" -> ["action words", "present tense", "past tense", "future tense"]
        "nouns" -> ["people", "places", "things", "abstract concepts"]
        "adjectives" -> ["descriptive words", "comparative forms", "superlative forms"]
        _ -> ["concept 1", "concept 2", "concept 3"]
      end

    concepts
    |> Enum.map(&"- **#{String.capitalize(&1)}**: #{Faker.Lorem.sentence(3..8)}")
    |> Enum.join("\n")
  end

  defp generate_examples(topic) do
    case topic do
      "verbs" ->
        """
        1. **Walk** - I walk to school every day.
        2. **Eat** - She eats breakfast at 7 AM.
        3. **Study** - We study Spanish together.
        """

      "greetings" ->
        """
        1. **Hello** - A formal greeting
        2. **Hi** - An informal greeting
        3. **Good morning** - Used before noon
        """

      _ ->
        """
        1. #{Faker.Lorem.sentence(3..6)}
        2. #{Faker.Lorem.sentence(4..8)}
        3. #{Faker.Lorem.sentence(3..7)}
        """
    end
  end

  defp translate_tag_name(key, language_code) do
    translations = %{
      "verbs" => %{"en" => "Verbs", "es" => "Verbos", "fr" => "Verbes", "de" => "Verben"},
      "nouns" => %{"en" => "Nouns", "es" => "Sustantivos", "fr" => "Noms", "de" => "Substantive"},
      "adjectives" => %{
        "en" => "Adjectives",
        "es" => "Adjetivos",
        "fr" => "Adjectifs",
        "de" => "Adjektive"
      },
      "grammar" => %{
        "en" => "Grammar",
        "es" => "Gramática",
        "fr" => "Grammaire",
        "de" => "Grammatik"
      },
      "vocabulary" => %{
        "en" => "Vocabulary",
        "es" => "Vocabulario",
        "fr" => "Vocabulaire",
        "de" => "Wortschatz"
      }
    }

    get_in(translations, [key, language_code]) || String.capitalize(key)
  end

  defp generate_card_fields(card_template) do
    Enum.reduce(card_template.fields, %{}, fn field, acc ->
      field_key = field["key"]
      field_type = field["type"]

      value =
        case field_type do
          "short_text" -> generate_short_text(field_key)
          "long_text" -> generate_long_text(field_key)
          "audio_url" -> "https://example.com/audio/#{Faker.Internet.slug()}.mp3"
          "image_url" -> "https://example.com/images/#{Faker.Internet.slug()}.jpg"
          "single_choice" -> Enum.random(["A", "B", "C", "D"])
          "multiple_choice" -> generate_multiple_choice()
          "examples" -> generate_examples_list()
        end

      Map.put(acc, field_key, value)
    end)
  end

  defp generate_short_text("word"), do: Faker.Lorem.word()
  defp generate_short_text("translation"), do: Faker.Lorem.word()
  defp generate_short_text("pronunciation"), do: "/#{Faker.Lorem.word()}/"
  defp generate_short_text("rule"), do: Faker.Lorem.sentence(3..6)
  defp generate_short_text(_), do: Faker.Lorem.words(1..3) |> Enum.join(" ")

  defp generate_long_text("example"), do: Faker.Lorem.sentence(5..12)
  defp generate_long_text("context"), do: Faker.Lorem.sentence(8..15)
  defp generate_long_text("description"), do: Faker.Lorem.sentence(6..10)
  defp generate_long_text("explanation"), do: Faker.Lorem.sentence(10..20)
  defp generate_long_text("notes"), do: Faker.Lorem.sentence(7..14)
  defp generate_long_text("question"), do: "#{Faker.Lorem.sentence(5..10)}?"
  defp generate_long_text(_), do: Faker.Lorem.sentence(4..8)

  defp generate_multiple_choice do
    options = Enum.map(1..4, fn _ -> Faker.Lorem.words(1..3) |> Enum.join(" ") end)
    %{"options" => options, "correct" => Enum.random(0..3)}
  end

  defp generate_examples_list do
    Enum.map(1..3, fn _ -> Faker.Lorem.sentence(4..8) end)
  end

  defp generate_template_mapping(use_case, template_fields) do
    case use_case do
      "flashcard" ->
        [
          %{"key" => "front", "value" => "{{word}}"},
          %{"key" => "back", "value" => "{{translation}}"}
        ]

      "study_mode" ->
        [
          %{"key" => "term", "value" => "{{word}}"},
          %{"key" => "definition", "value" => "{{translation}} - {{example}}"}
        ]

      "quiz" ->
        [
          %{"key" => "question", "value" => "What does '{{word}}' mean?"},
          %{"key" => "answer", "value" => "{{translation}}"}
        ]

      _ ->
        # Default mapping based on available fields
        template_fields
        |> Enum.take(2)
        |> Enum.map(fn field ->
          %{"key" => field["key"], "value" => "{{#{field["key"]}}}"}
        end)
    end
  end

  # Simple insert functions for testing (less randomized than the main fixtures)

  @doc """
  Creates a simple translation card template for testing.
  """
  def insert_card_template do
    %CardTemplate{}
    |> CardTemplate.changeset(%{
      name: "Translation Card",
      fields: [
        %{"key" => "word", "type" => "short_text", "required" => true},
        %{"key" => "translation", "type" => "short_text", "required" => true}
      ]
    })
    |> Repo.insert!()
  end

  @doc """
  Creates a simple vocabulary list for testing.
  """
  def insert_vocabulary_list(course, attrs \\ %{}) do
    default_attrs = %{
      name: "Basic Spanish Words",
      slug: "basic-spanish-words",
      course_id: course.id
    }

    attrs = Map.merge(default_attrs, attrs)

    %VocabularyList{}
    |> VocabularyList.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Creates a simple card for testing.
  """
  def insert_card(course, card_template, fields) do
    %Card{}
    |> Card.changeset(%{
      fields: fields,
      course_id: course.id,
      card_template_id: card_template.id
    })
    |> Repo.insert!()
  end
end
