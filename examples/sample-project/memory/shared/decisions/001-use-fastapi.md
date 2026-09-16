# Decision: Use FastAPI

We chose FastAPI as our web framework because:
- Native async support
- Automatic OpenAPI documentation
- Pydantic integration for validation
- Strong performance benchmarks

## Alternatives Considered

- Django REST Framework: Too heavyweight for this project
- Flask: No native async, less type safety
- Starlette: Too low-level, FastAPI provides better DX

## Consequences

- Must use async/await for all request handlers
- Pydantic models required for all request/response types
- OpenAPI spec is auto-generated
