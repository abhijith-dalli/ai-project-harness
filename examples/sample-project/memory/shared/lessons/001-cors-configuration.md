# Lesson: CORS Configuration Required for Local Development

When developing locally with a separate frontend, CORS must be configured
in FastAPI or the frontend cannot make API calls.

## What Happened

Frontend requests were blocked by CORS policy during local development.

## Root Cause

FastAPI does not include CORS middleware by default. The frontend runs on
a different port (e.g., 3000) than the API (e.g., 8000).

## How to Prevent

Always include CORS middleware in the FastAPI app:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Evidence

Commit abc123 that fixed the CORS issue.
