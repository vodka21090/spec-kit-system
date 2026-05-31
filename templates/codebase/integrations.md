# External Integrations Template

Template for `docs/codebase/INTEGRATIONS.md` — captures external service dependencies.

**Purpose:** Document what external systems this codebase communicates with — "what lives outside our code that we depend on." Note credential *names* (env var keys) only; never read or record secret values. Omit any section that does not apply.

---

## File Template

```markdown
---
schema_version: 1
doc: INTEGRATIONS
analysis_date: [YYYY-MM-DD]
generated_by: /spec-kit:map-codebase
source_sha: [short-sha]
sections:
  - { id: apis-and-external-services, summary: "[third-party APIs + SDKs]" }
  - { id: data-storage, summary: "[databases, file storage, caching]" }
  - { id: authentication-and-identity, summary: "[auth provider + OAuth]" }
  - { id: monitoring-and-observability, summary: "[error tracking, analytics, logs]" }
  - { id: cicd-and-deployment, summary: "[hosting + CI pipeline]" }
  - { id: environment-configuration, summary: "[env var names per environment]" }
  - { id: webhooks-and-callbacks, summary: "[incoming/outgoing webhooks]" }
---

# External Integrations

## APIs and External Services

**[Category — e.g. Payments / Email / External API]:**
- [Service] — [What it's used for]
  - SDK/Client: [e.g., `stripe` npm package v14.x]
  - Auth: [e.g., "API key in `STRIPE_SECRET_KEY` env var"] — name only
  - Endpoints/usage: [e.g., "checkout sessions, webhooks"]

## Data Storage

**Databases:**
- [Type/Provider] — [e.g., "PostgreSQL on Supabase"]
  - Connection: [e.g., "`DATABASE_URL` env var"]
  - Client: [e.g., "Prisma ORM v5.x"]
  - Migrations: [where they live]

**File Storage:** [Service, SDK, auth env var names, buckets]

**Caching:** [Service, connection env var, client]

## Authentication and Identity

**Auth Provider:** [Service, implementation, token storage, session strategy]

**OAuth Integrations:** [Provider, credential env var names, scopes]

## Monitoring and Observability

**Error Tracking:** [Service + DSN env var name]

**Analytics:** [Service + token env var name + events]

**Logs:** [Destination, or "stdout only"]

## CI/CD and Deployment

**Hosting:** [Platform, deployment trigger, where env vars are configured]

**CI Pipeline:** [Service, workflow files, where secrets are stored]

## Environment Configuration

**Development:** [Required env var names; secrets location; mock/stub services]

**Staging / Production:** [Environment-specific differences; secrets management]

## Webhooks and Callbacks

**Incoming:** [Service, endpoint path, verification method, events]

**Outgoing:** [Service, trigger, endpoint, retry logic]

---

*Integration audit: [date]. Update when adding/removing external services.*
```
