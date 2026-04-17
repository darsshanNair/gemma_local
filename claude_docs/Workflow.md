# Development Workflow

This document describes reusable development workflow patterns for Claude Code projects. These practices ensure consistent Git usage and collaboration.

## Git Branch Strategy

- **feature/** – New features, enhancements (e.g., `feature/add-user-auth`)
- **fix/** – Bug fixes (e.g., `fix/login-crash`)
- **patch/** – Small corrections, dependencies, config changes (e.g., `patch/update-readme`)

## Process

1. Create appropriate branch before starting changes
2. Make changes on that branch  
3. Test changes
4. Commit with descriptive messages
5. Push branch for review/merge

## Claude Code Usage

- Use `fvm` prefix for Flutter commands (e.g., `fvm flutter pub get`)
- Follow dependency injection pattern established with GetIt
- Reference `CLAUDE.md` for project structure and conventions