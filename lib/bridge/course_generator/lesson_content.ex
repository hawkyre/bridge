defmodule Bridge.CourseGenerator.LessonContent do
  @moduledoc """
  AI service for generating comprehensive language lesson content in Markdown format.

  This module generates detailed lesson content based on a specific topic, target language,
  instruction language, and proficiency level. It uses structured prompts to ensure high-quality,
  pedagogically sound lessons with proper formatting and structure.
  """

  alias Bridge.AI.Executor

  @type lesson_response :: %{
          content: String.t()
        }

  @doc """
  Generates a markdown-formatted lesson for a specific topic.

  ## Parameters

    * `target_language` - The language being taught (e.g., "Spanish", "Chinese Simplified")
    * `instruction_language` - The language used for instruction (e.g., "English", "French")
    * `topic` - The specific lesson topic to cover
    * `level` - The proficiency level (e.g., "A1", "B2", "HSK 1", "JLPT N5")
    * `opts` - Optional parameters for AI provider (model, temperature, etc.)

  ## Returns

    * `{:ok, String.t()}` - The lesson content in Markdown format
    * `{:error, String.t()}` - Error message if generation fails

  ## Examples

      iex> Bridge.CourseGenerator.LessonContent.generate("Spanish", "English", "Present Tense of Regular Verbs", "A1")
      {:ok, "# Present Tense of Regular Verbs\\n\\n## Introduction..."}

  """
  @spec generate(String.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def generate(target_language, instruction_language, topic, level, opts \\ []) do
    with {:ok, prompt} <- build_prompt(target_language, instruction_language, topic, level),
         {:ok, response} <- Executor.call(:anthropic, prompt, opts),
         {:ok, lesson_content} <- parse_response(response.content) do
      {:ok, lesson_content}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec build_prompt(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  defp build_prompt(target_language, instruction_language, topic, level) do
    with :ok <- validate_inputs(target_language, instruction_language, topic, level) do
      prompt = """
      <instruction>
        <role>You are an expert language lesson builder with extensive experience in language pedagogy and instructional design.</role>

        <task>
          <objective>Create a comprehensive, engaging #{target_language} lesson in Markdown format about the specified topic.</objective>

          <context>
            <student_language>#{instruction_language}</student_language>
            <target_language>#{target_language}</target_language>
            <proficiency_level>#{level}</proficiency_level>
            <topic>#{topic}</topic>
            <topic_refinement>Refine the topic to be more comprehensive if needed. Use it as a starting point, but ensure the lesson only covers content appropriate for the #{level} level.</topic_refinement>
          </context>

          <requirements>
            <language>All lesson content must be written in #{instruction_language}</language>
            <formatting>Use Markdown formatting for proper structure and readability</formatting>
            <pedagogical_quality>Apply best practices in language teaching to ensure effective learning</pedagogical_quality>
            <level_appropriateness>Content must be suitable for #{level} level learners</level_appropriateness>
          </requirements>
        </task>

        <lesson_structure>
          <section name="Introduction">
            <element>Begin with a brief, relatable scenario or question that connects the lesson topic to students' real-world experience</element>
            <element>Present lesson-specific goals in a clear list format, explaining what students will be able to do by the end</element>
            <element>Provide a quick roadmap of what will be covered</element>
          </section>

          <section name="Lesson Content">
            <element>Break each topic into digestible 2-3 minute reading segments to maintain attention</element>
            <element>Explain concepts in simple, structured language, ensuring core ideas are transmitted as directly as possible</element>
            <element>Use analogies, authentic example sentences, mini-texts showing language in context, and real-world scenarios to engage students</element>
            <element>Include brief "pause and think" prompts or reflection questions within content sections to help students absorb information</element>
            <element>Use formatting (headers, bullet points, highlight boxes) to create visual breathing space</element>
            <element>Maintain this format for each objective/topic, keeping sections concise to avoid overwhelming students</element>
            <element>If an objective is too ample to fit in a single section, divide it into multiple sections so that it still makes sense</element>
          </section>

          <section name="Summary">
            <element>Summarize main content points in bullet format for easy scanning</element>
            <element>Explicitly connect back to the stated learning objectives, confirming what was covered</element>
          </section>

          <guidelines>
            <flexibility>Take this structure as a base and adapt it to the needs of the topic</flexibility>
            <pragmatism>You don't need to create every single element if it doesn't make sense for the specific topic</pragmatism>
          </guidelines>
        </lesson_structure>

        <output_format>
          <format>JSON</format>
          <structure>
            A single JSON object with one key:
            - content: the complete lesson in Markdown format (string)
          </structure>

          <constraints>
            <output>Only output the JSON object, do not output anything else</output>
            <no_preamble>Do not add introductory text like "Of course! Here's your lesson" or similar</no_preamble>
            <direct>Jump straight to the core of the task: writing the best possible lesson</direct>
          </constraints>
        </output_format>
      </instruction>
      """

      {:ok, prompt}
    end
  end

  @spec validate_inputs(String.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, String.t()}
  defp validate_inputs(target_language, instruction_language, topic, level) do
    cond do
      not is_binary(target_language) or String.trim(target_language) == "" ->
        {:error, "Target language must be a non-empty string"}

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

  @spec parse_response(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp parse_response(json_content) do
    cleaned_content = extract_json_content(json_content)

    case Jason.decode(cleaned_content) do
      {:ok, %{"content" => content}} when is_binary(content) ->
        {:ok, content}

      {:ok, _} ->
        {:error, "Invalid response format: missing or invalid 'content' key"}

      {:error, %Jason.DecodeError{}} ->
        {:error, "Invalid JSON response from AI provider"}
    end
  rescue
    e ->
      {:error, "Failed to parse response: #{Exception.message(e)}"}
  end

  @spec extract_json_content(String.t()) :: String.t()
  defp extract_json_content(content) do
    case Regex.run(~r/\{.*\}/s, content) do
      [json_match] -> json_match
      nil -> content
    end
  end
end
