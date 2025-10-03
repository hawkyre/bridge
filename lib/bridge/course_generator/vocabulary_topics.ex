defmodule Bridge.CourseGenerator.VocabularyTopics do
  @moduledoc """
  AI service for generating comprehensive vocabulary topic lists for language learning courses.

  This module provides functionality to generate structured lists of vocabulary topics
  based on target language, instruction language, and proficiency level. It uses
  XML-structured prompts for clear organization while requesting JSON responses
  to ensure consistent, parseable data from AI providers.
  """

  alias Bridge.AI.Executor

  @type vocabulary_topic :: %{
          topic: String.t(),
          slug: String.t()
        }

  defstruct [:topics]

  @type t :: %__MODULE__{
          topics: [vocabulary_topic()]
        }

  @doc """
  Generates a comprehensive list of vocabulary topics for a given language and level.

  ## Parameters

    * `target_language` - The language being learned (e.g., "Spanish", "Chinese Simplified")
    * `instruction_language` - The student's native language (e.g., "English", "French")
    * `level` - The proficiency level (e.g., "A1", "B2", "HSK 1", "JLPT N5")
    * `opts` - Optional parameters for AI provider (model, temperature, etc.)

  ## Returns

    * `{:ok, [vocabulary_topic()]}` - List of vocabulary topics with structured data
    * `{:error, String.t()}` - Error message if generation fails

  ## Examples

      iex> Bridge.CourseGenerator.VocabularyTopics.get_topics("Spanish", "English", "A1")
      {:ok, [
        %{
          topic: "Food and Drinks",
          slug: "food-and-drinks"
        },
        %{
          topic: "Family Members",
          slug: "family-members"
        }
      ]}

      iex> Bridge.CourseGenerator.VocabularyTopics.get_topics("Chinese Simplified", "English", "HSK 1", model: "claude-3-haiku")
      {:ok, [%{topic: "Basic Greetings", slug: "basic-greetings"}]}
  """
  @spec get_topics(String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, [vocabulary_topic()]} | {:error, String.t()}
  def get_topics(target_language, instruction_language, level, opts \\ []) do
    with {:ok, prompt} <- build_prompt(target_language, instruction_language, level),
         {:ok, response} <- Executor.call(:anthropic, prompt, opts),
         {:ok, topics} <- parse_response(response.content) do
      {:ok, topics}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_prompt(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp build_prompt(target_language, instruction_language, level) do
    with :ok <- validate_inputs(target_language, instruction_language, level) do
      prompt = """
      <instruction>
        <role>You are an expert #{target_language} teacher with extensive experience in language pedagogy and vocabulary acquisition.</role>

        <task>
          <objective>Generate a complete, comprehensive list of vocabulary topics that a #{level} learner must learn and know about to become completely adept for #{level} level.</objective>

          <context>
            <student_language>#{instruction_language}</student_language>
            <target_language>#{target_language}</target_language>
            <proficiency_level>#{level}</proficiency_level>
          </context>

          <requirements>
            <structure>The structure must align with how a #{instruction_language}-speaking student would learn best</structure>
            <ordering>The vocabulary lists must be ordered by the best learning order for the student</ordering>
            <comprehensiveness>Include all essential vocabulary topics for #{level} level mastery</comprehensiveness>
            <relevance>Topics should be practical and immediately useful for learners at this level</relevance>
            <progression>Each topic should build upon previous knowledge when appropriate</progression>
          </requirements>
        </task>

        <output_format>
          <format>JSON</format>
          <structure>
            Array of objects with the following keys:
            - topic: the topic of the vocabulary list (string)
            - slug: An SEO friendly slug for the lesson title (string)
          </structure>

          <topic_guidelines>
            <naming>Topic names should be clear, descriptive, and learner-friendly</naming>
            <scope>Each topic should cover a cohesive semantic field or thematic area</scope>
            <examples>Food and Drinks, Family Members, Numbers and Counting, Daily Routines, Weather and Seasons</examples>
            <level_appropriateness>Topics must match the vocabulary complexity expected at #{level} level</level_appropriateness>
          </topic_guidelines>

          <slug_guidelines>
            <format>lowercase with hyphens instead of spaces</format>
            <examples>food-and-drinks, family-members, numbers-and-counting</examples>
            <requirements>URL-friendly, SEO-optimized, readable</requirements>
          </slug_guidelines>

          <constraints>
            <output>Only output the JSON array, do not output anything else</output>
            <structure>No additional text or explanations</structure>
          </constraints>
        </output_format>
      </instruction>
      """

      {:ok, prompt}
    end
  end

  @spec validate_inputs(String.t(), String.t(), String.t()) :: :ok | {:error, String.t()}
  defp validate_inputs(target_language, instruction_language, level) do
    cond do
      not is_binary(target_language) or String.trim(target_language) == "" ->
        {:error, "Target language must be a non-empty string"}

      not is_binary(instruction_language) or String.trim(instruction_language) == "" ->
        {:error, "Instruction language must be a non-empty string"}

      not is_binary(level) or String.trim(level) == "" ->
        {:error, "Level must be a non-empty string"}

      true ->
        :ok
    end
  end

  @spec parse_response(String.t()) :: {:ok, [vocabulary_topic()]} | {:error, String.t()}
  defp parse_response(json_content) do
    cleaned_content = extract_json_content(json_content)

    topics =
      cleaned_content
      |> Jason.decode!()
      |> Enum.map(&format_topic/1)

    {:ok, topics}
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

  @spec format_topic(map()) :: vocabulary_topic()
  defp format_topic(topic_data) do
    %{
      topic: String.trim(topic_data["topic"] || ""),
      slug: String.trim(topic_data["slug"] || "")
    }
  end
end
