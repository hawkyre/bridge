# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bridge is an open-source language learning platform built with Elixir/Phoenix that aims to create comprehensive, AI-generated language courses refined by community teachers. The platform supports multiple languages and provides dynamic content including grammar lessons, vocabulary cards, and exercises.

## Development Commands

### Docker-based Development (Recommended)
- `make up` - Start the application and database containers
- `make re` - Restart the bridge application container
- `make logs` - Follow application logs
- `make console` - Access IEx console in container
- `make db` - Access PostgreSQL console

### Testing
- `make tests` - Run all tests in container
- `make test-file FILE=path/to/test_file.exs` - Run specific test file

### Mix Commands (if running locally)
- `mix setup` - Install dependencies and set up database
- `mix phx.server` - Start Phoenix server
- `mix test` - Run tests
- `mix ecto.reset` - Reset database
- `mix credo` - Run code analysis
- `mix dialyxir` - Run static analysis
- `mix sobelow` - Run security analysis

## Architecture

### Core Structure
- **BridgeWeb** - Phoenix web layer with controllers, components, and routing
- **Bridge.Courses** - Main business logic context for course management
- **Bridge.Repo** - Ecto repository for database operations
- **Bridge.Format** - Utilities for data formatting (slugs, language codes, keys)

### Key Entities
- **Course** - Core entity representing a language course with metadata and relationships
- **Lesson** - Grammar lessons within courses, tagged and organized
- **Card** - Vocabulary flashcards with flexible field structure via templates
- **VocabularyList** - Collections of vocabulary cards
- **Template/Mapping** - System for flexible card field definitions

### Database
- Uses PostgreSQL with binary UUID primary keys
- Ecto schemas use `TypedEctoSchema` for better type safety
- Supports multiple language codes for internationalization

### Phoenix Patterns
- LiveView for interactive components
- Core Components for reusable UI elements
- Standard Phoenix controller/router structure
- Tailwind CSS for styling with esbuild for JS bundling

## Key Development Notes

- All models use binary UUID primary keys (`binary_id: true`)
- Language courses support multiple instruction languages
- Course visibility can be toggled for draft/published states
- Cards use a flexible template system for varying field structures
- The codebase includes comprehensive test coverage with ExMachina factories