defmodule Bridge.CourseGenerator.VocabularyList do
  @moduledoc """
  AI service for generating vocabulary lists for language learning courses.

  This module provides functionality to generate structured vocabulary lists
  based on taught language, instruction language, topic, and proficiency level.
  """

  alias Bridge.AI.Executor

  @type vocabulary_card :: %{
          type: String.t(),
          taught_language_word: String.t() | nil,
          instruction_language_word: String.t() | nil,
          word: String.t() | nil,
          explanation: String.t() | nil,
          examples: [example()]
        }

  @type example :: %{
          taught_language_example: String.t(),
          instruction_language_example: String.t()
        }

  @type vocabulary_list :: %{
          slug: String.t(),
          list: [vocabulary_card()]
        }

  @doc """
  Generates a vocabulary list for a given language, topic, and level.

  ## Parameters

    * `taught_language` - The language being learned (e.g., "Spanish", "Chinese Simplified")
    * `instruction_language` - The student's native language (e.g., "English", "French")
    * `topic` - The vocabulary theme/topic (e.g., "Food", "Travel", "Business")
    * `level` - The proficiency level (e.g., "A1", "B2", "HSK 1", "JLPT N5")
    * `opts` - Optional parameters for AI provider (model, temperature, etc.)

  ## Returns

    * `{:ok, vocabulary_list()}` - Vocabulary list with slug and card entries
    * `{:error, String.t()}` - Error message if generation fails

  ## Examples

      iex> Bridge.CourseGenerator.VocabularyList.get_list("Spanish", "English", "Jobs and Occupations", "A1")
      {:ok, %{
        slug: "food-vocabulary-a1",
        list: [
          %{
            type: "translation",
            taught_language_word: "manzana",
            instruction_language_word: "apple",
            examples: [%{
              taught_language_example: "Me gusta la manzana roja",
              instruction_language_example: "I like the red apple"
            }]
          }
        ]
      }}
  """
  @spec get_list(String.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, vocabulary_list()} | {:error, String.t()}
  def get_list(taught_language, instruction_language, topic, level, opts \\ []) do
    with {:ok, prompt} <- build_prompt(taught_language, instruction_language, topic, level),
         {:ok, response} <- Executor.call(:anthropic, prompt, opts),
         {:ok, vocab_list} <- parse_response(response.content, topic, level) do
      {:ok, vocab_list}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_prompt(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp build_prompt(taught_language, instruction_language, topic, level) do
    with :ok <- validate_inputs(taught_language, instruction_language, topic, level) do
      prompt = """
      <instruction>
        <role>You are an expert language lesson builder specializing in vocabulary acquisition and thematic learning.</role>

        <task>
          <objective>Generate a comprehensive vocabulary list for the topic "#{topic}" tailored for a #{level} learner studying #{taught_language}.</objective>

          <context>
            <student_language>#{instruction_language}</student_language>
            <taught_language>#{taught_language}</taught_language>
            <topic>#{topic}</topic>
            <proficiency_level>#{level}</proficiency_level>
          </context>

          <requirements>
            <level_alignment>All words must align with the #{level} level according to official language standards (CEFR, HSK, JLPT, etc.)</level_alignment>
            <topic_relevance>All vocabulary must be directly relevant to the topic "#{topic}"</topic_relevance>
            <template_selection>
              Choose the appropriate card template based on word difficulty and translatability:
              <translation_card>Use for beginner-level words or words with clear, simple translations in #{instruction_language}</translation_card>
              <explanation_card>Use for advanced words, cultural concepts, or terms without simple direct translations</explanation_card>
              <reasoning>Apply your best pedagogical reasoning to maximize student comprehension</reasoning>
            </template_selection>
            <examples>
              <quantity>Provide exactly one example per card</quantity>
              <quality>Examples must be meaningful, contextually appropriate, and aligned with the #{level} level</quality>
              <authenticity>Use natural, authentic language that students would encounter in real situations</authenticity>
            </examples>
          </requirements>
        </task>

        <output_format>
          <format>JSON</format>
          <structure>
            Array of card objects. Each card must conform to one of the templates below:

            <template name="translation">
              {
                "type": "translation",
                "taught_language_word": "word or phrase in #{taught_language}",
                "instruction_language_word": "translation in #{instruction_language}",
                "examples": [
                  {
                    "taught_language_example": "example sentence in #{taught_language}",
                    "instruction_language_example": "translation in #{instruction_language}"
                  }
                ]
              }
            </template>

            <template name="explanation">
              {
                "type": "explanation",
                "word": "word or phrase in #{taught_language}",
                "explanation": "detailed explanation in #{taught_language}",
                "examples": [
                  {
                    "taught_language_example": "example sentence in #{taught_language}",
                    "instruction_language_example": "translation in #{instruction_language}"
                  }
                ]
              }
            </template>
          </structure>

          <constraints>
            <output>Only output the JSON array, do not output anything else</output>
            <formatting>No additional text, explanations, or commentary</formatting>
            <validation>Ensure valid JSON syntax with proper escaping of special characters</validation>
          </constraints>
        </output_format>
      </instruction>
      """

      {:ok, prompt}
    end
  end

  @spec validate_inputs(String.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, String.t()}
  defp validate_inputs(taught_language, instruction_language, topic, level) do
    cond do
      not is_binary(taught_language) or String.trim(taught_language) == "" ->
        {:error, "Taught language must be a non-empty string"}

      not is_binary(instruction_language) or String.trim(instruction_language) == "" ->
        {:error, "Instruction language must be a non-empty string"}

      not is_binary(topic) or String.trim(topic) == "" ->
        {:error, "Topic must be a non-empty string"}

      not is_binary(level) or String.trim(level) == "" ->
        {:error, "Level must be a non-empty string"}

      true ->
        :ok
    end
  end

  @spec parse_response(String.t(), String.t(), String.t()) ::
          {:ok, vocabulary_list()} | {:error, String.t()}
  defp parse_response(json_content, topic, level) do
    cleaned_content = extract_json_content(json_content)

    cards =
      cleaned_content
      |> Jason.decode!()
      |> Enum.map(&format_card/1)

    slug = generate_slug(topic, level)

    {:ok, %{slug: slug, list: cards}}
  rescue
    Jason.DecodeError ->
      {:error, "Invalid JSON response from AI provider"}

    e ->
      {:error, "Failed to parse JSON response: #{Exception.message(e)}"}
  end

  @spec extract_json_content(String.t()) :: String.t()
  defp extract_json_content(content) do
    case Regex.run(~r/\[.*\]/s, content) do
      [json_match] -> json_match
      nil -> content
    end
  end

  @spec format_card(map()) :: vocabulary_card()
  defp format_card(%{"type" => "translation"} = card) do
    %{
      type: "translation",
      taught_language_word: String.trim(card["taught_language_word"] || ""),
      instruction_language_word: String.trim(card["instruction_language_word"] || ""),
      word: nil,
      explanation: nil,
      examples: format_examples(card["examples"] || [])
    }
  end

  defp format_card(%{"type" => "explanation"} = card) do
    %{
      type: "explanation",
      taught_language_word: nil,
      instruction_language_word: nil,
      word: String.trim(card["word"] || ""),
      explanation: String.trim(card["explanation"] || ""),
      examples: format_examples(card["examples"] || [])
    }
  end

  @spec format_examples([map()]) :: [example()]
  defp format_examples(examples) when is_list(examples) do
    Enum.map(examples, fn ex ->
      %{
        taught_language_example: String.trim(ex["taught_language_example"] || ""),
        instruction_language_example: String.trim(ex["instruction_language_example"] || "")
      }
    end)
  end

  defp format_examples(_), do: []

  @spec generate_slug(String.t(), String.t()) :: String.t()
  defp generate_slug(topic, level) do
    normalized_topic =
      topic
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9\s-]/, "")
      |> String.replace(~r/\s+/, "-")

    normalized_level =
      level
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]/, "")

    "#{normalized_topic}-#{normalized_level}"
  end
end
