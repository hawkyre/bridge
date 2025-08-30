defmodule Bridge.Courses do
  @moduledoc """
  The Courses context.

  This module provides the public API for managing courses, lessons, vocabulary cards,
  and all related course content. It handles the business logic for language learning
  course management with support for multiple languages and flexible content structure.
  """

  import Ecto.Query, warn: false
  alias Bridge.Repo

  alias Bridge.Courses.Course

  @doc """
  Returns the list of courses.

  ## Examples

      iex> list_courses()
      [%Course{}, ...]

  """
  @spec list_courses :: [Course.t()]
  def list_courses do
    Repo.all(Course)
  end

  @doc """
  Returns the list of visible courses.

  ## Examples

      iex> list_visible_courses()
      [%Course{}, ...]

  """
  def list_visible_courses do
    Course
    |> where([c], c.visible == true)
    |> Repo.all()
  end

  @doc """
  Gets a single course.

  Raises `Ecto.NoResultsError` if the Course does not exist.

  ## Examples

      iex> get_course!(123)
      %Course{}

      iex> get_course!(456)
      ** (Ecto.NoResultsError)

  """
  def get_course!(id), do: Repo.get!(Course, id)

  @doc """
  Gets a course by slug.

  ## Examples

      iex> get_course_by_slug("spanish-basics")
      %Course{}

      iex> get_course_by_slug("nonexistent")
      nil

  """
  def get_course_by_slug(slug) do
    Repo.get_by(Course, slug: slug)
  end

  @doc """
  Creates a course.

  ## Examples

      iex> create_course(%{field: value})
      {:ok, %Course{}}

      iex> create_course(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_course(attrs \\ %{}) do
    %Course{}
    |> Course.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a course.

  ## Examples

      iex> update_course(course, %{field: new_value})
      {:ok, %Course{}}

      iex> update_course(course, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_course(%Course{} = course, attrs) do
    course
    |> Course.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a course.

  ## Examples

      iex> delete_course(course)
      {:ok, %Course{}}

      iex> delete_course(course)
      {:error, %Ecto.Changeset{}}

  """
  def delete_course(%Course{} = course) do
    Repo.delete(course)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course changes.

  ## Examples

      iex> change_course(course)
      %Ecto.Changeset{data: %Course{}}

  """
  def change_course(%Course{} = course, attrs \\ %{}) do
    Course.changeset(course, attrs)
  end
end
