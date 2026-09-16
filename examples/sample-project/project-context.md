# Project Context — Sample Project

## Project

**Name:** Sample API
**Purpose:** Demonstrate the AI Project Harness in a realistic project
**Status:** Active

## Technology

**Language(s):** Python 3.12
**Framework(s):** FastAPI
**Database:** PostgreSQL 16
**Package Manager:** uv
**Runtime:** Python 3.12+

## Architecture

REST API backend with:
- FastAPI for HTTP routing and OpenAPI spec
- SQLAlchemy for ORM
- PostgreSQL for data storage
- Pydantic for validation
- pytest for testing

## Important Conventions

- All API endpoints use kebab-case URLs
- Tests live next to source files in `tests/`
- Use async/await for database queries
- Pydantic models for request/response validation
- Type hints on all functions

## Important Constraints

- Must support Python 3.12+
- No external dependencies for core logic
- All endpoints must have tests
- Response time < 50ms for list endpoints

## Development Commands

```bash
# Install dependencies
uv sync

# Run development server
uv run fastapi dev

# Run tests
uv run pytest

# Run linter
uv run ruff check

# Run type checker
uv run mypy
```

## Testing

- pytest for unit and integration tests
- httpx for async test client
- Factory Boy for test data
- Coverage target: 80%+

## Deployment

- Docker-based deployment
- Environment variables for configuration
- Database migrations with Alembic

## AI Instructions

- Always run tests before completing
- Follow existing patterns in the codebase
- Use async/await for all database operations
- Never modify migration files
- Save important decisions to project memory

## Known Issues

- None currently
