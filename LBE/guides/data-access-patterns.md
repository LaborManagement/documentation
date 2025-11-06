# Data Access Patterns Guide

This guide explains the three data-access approaches that we support across services—Spring Data JPA, jOOQ DSL, and jOOQ with external `.sql` templates—and how to decide which one to use.

---

## Overview

| Pattern                | What it is                                                     | Strengths                                              | Trade-offs                                             |
|------------------------|----------------------------------------------------------------|--------------------------------------------------------|--------------------------------------------------------|
| **Spring Data JPA**    | Repository interfaces over entities and JPQL/Criteria queries  | Simple for CRUD; reuses entity lifecycle & auditing    | Harder to express complex joins; JPQL errors at runtime|
| **jOOQ DSL**           | Type-safe SQL built with generated or dynamic DSL objects      | Compile-time schema checks; rich SQL features; one round-trip | Requires codegen or string-based fields; bypasses entity cache |
| **jOOQ + SQL files**   | Analyst-owned `.sql` templates loaded and executed via jOOQ    | Centralised queries; easy to tweak without Java changes | No compile-time check of templates; must keep aliases stable |

Use this checklist to pick a pattern for a new method:

1. **Does the method mutate a JPA entity or rely on entity lifecycle callbacks / auditing?**  
   → Start with JPA so the entity state stays consistent. Switch to jOOQ only if performance demands it and you can manage the extra mapping.

2. **Do you need a multi-join read with lots of filters/sorting?**  
   → Use jOOQ DSL—especially once the schema is stable and codegen is on—so the query is readable and type-safe.

3. **Is the query primarily a report/aggregation maintained by data analysts?**  
   → Put it in a `.sql` template under `src/main/resources/sql`, load it with `SqlTemplateLoader`, and execute via jOOQ so analysts can adjust it without touching Java.

---

## When to use Spring Data JPA

**Ideal for:**

- CRUD and simple lookups that map directly to entities (`findByUsername`, `save`, etc.).
- Write-heavy flows where we need entity lifecycle events (auditing, cascade rules).
- Areas already instrumented with entity-level auditing (changeset tracking).

**Rules & Tips:**

- Keep repository interfaces focused on persistence concerns—push business logic up into services.
- Use method-name queries or small JPQL snippets; any complex read should graduate to jOOQ.
- Avoid returning entities from external APIs; map them to DTOs in services/controllers.
- Add integration tests (`@DataJpaTest`) when you introduce new JPQL queries to catch typos.

**Why choose JPA?**

- It’s the most direct way to persist aggregates and reuse existing entity mappings.
- Saves boilerplate for transaction management and dirty checking.

---

## When to use jOOQ DSL

**Ideal for:**

- Read-heavy or analytical queries with multiple joins, filters, or window functions.
- Places where schema drift must fail the build (generated DSL offers compile-time guarantees).
- Replacing custom `JdbcTemplate` code while keeping control over SQL shape.

**Rules & Tips:**

- Inject `DSLContext` (the shared auto-config supplies it) and keep DSL code inside DAO classes.
- Prefer generated table/field classes (`Tables.USERS`) once codegen is enabled; otherwise use `DSL.table(DSL.name("users"))` temporarily.
- Keep the result mapping close to the query. Use small record/DTO mappers or `fetchInto()` when the target structure matches the projection.
- Add unit/integration tests that hit a real database (H2/Postgres container) to confirm the SQL behaves as expected.
- When grouping into nested structures, focus on: fetch flat result → group in Java (`Collectors.groupingBy`) → map to DTOs.

**Why choose jOOQ DSL?**

- Strong type safety once codegen is on; schema changes break the build rather than runtime.
- Easy access to advanced SQL features not exposed by JPQL (CTEs, window functions).
- You control the exact SQL, which helps with performance tuning.

---

## When to use jOOQ + SQL templates

**Ideal for:**

- Reporting queries curated by analysts or BI teams.
- Queries that change frequently or are easier to maintain as text (e.g., long CTEs, custom sort logic).
- Contexts where we want to share the SQL outside the application (documentation, re-use).

**Rules & Tips:**

- Store templates under `src/main/resources/sql/<domain>/...`. Use `.sql` extensions.
- Load templates with `SqlTemplateLoader` (already available in payment-flow-service) to support caching and consistent error handling.
- Use positional placeholders (`?`) or named parameters supported by jOOQ parser; keep the order documented in the DAO.
- Keep column aliases stable—service code maps results by alias (`status`, `count`, etc.).
- Introduce tests (e.g., load the template and execute against an in-memory database) to ensure syntax remains valid.
- Document templates in README guides so analysts know what they can safely change.

**Why choose jOOQ + SQL templates?**

- Reduces code churn when only SQL changes.
- Gives analysts a clear way to propose/report adjustments without editing Java.
- Keeps execution on the jOOQ stack (same `DSLContext`, same parameter binding) so we retain consistency with the rest of the codebase.

---

## Migration guidance

1. **JPA → jOOQ DSL**  
   - Identify the repository method to replace (usually read-heavy).  
   - Add a DAO using `DSLContext`, implement the query, and update the service to call the DAO.  
   - Keep the JPA repository for writes if needed, or remove it once the read logic is fully migrated.  
   - Add tests to verify the jOOQ version behaves identically.

2. **JdbcTemplate → jOOQ DSL**  
   - Replace handwritten SQL with DSL statements.  
   - Reuse existing mappers, or convert to `fetchInto()` to map automatically.  
   - Remove manual pagination logic—jOOQ has built-in limit/offset helpers.

3. **jOOQ DSL → jOOQ + SQL template**  
   - Extract the SQL string into a `.sql` file.  
   - Load it via `SqlTemplateLoader`, then execute with `dsl.resultQuery`.  
   - Keep the method signature the same so services/controllers do not need to change.  
   - Update documentation (`README`, runbook) to let analysts know where the template lives.

---

## Quick decision flow

1. **Write operation on an entity?** → Use JPA.  
2. **Read with straightforward filters or unique lookup?** → JPA is acceptable; if eager fetching causes issues, switch to jOOQ.  
3. **Read with multi-table join, aggregations, complex sorting** → Use jOOQ DSL.  
4. **Report maintained by analysts / easy to tweak without redeploy** → jOOQ + SQL template.  
5. **Need both** (write + complex read)? → Combine JPA for writes and jOOQ for reads (each in its own DAO/repo).

---

## Examples

- `auth-service`: Writes stay on JPA repositories (`UserRepository`), read-heavy flows moved to jOOQ DAOs (`UserQueryDao`, `RoleQueryDao`). No templates yet because the logic is part of the service layer.
- `payment-flow-service`: 
  - Worker/employer DAOs use jOOQ DSL for dynamic filters (pagination, search).
  - Aggregation queries (`worker_payment_summary`, `employer_status_distribution`) live in `.sql` files loaded via `SqlTemplateLoader`.
- `reconciliation-service`: Currently uses JPA only; once more analytical queries emerge, consider migrating to jOOQ for read-heavy operations.

---

## Maintenance checklist

- When adding a new method, document which pattern you used and why (Javadoc or README).  
- If you move a query to jOOQ or to a template, update service tests to validate the new path.  
- Make sure each service’s `pom.xml` still connects jOOQ codegen to the right schema, even if codegen is disabled by default.  
- Re-run codegen before releases if the database schema changed and you rely on generated classes.  
- For templates, confirm alias/column changes with the consumers; update the guide when semantics change.

---

Contact the platform team if you need help deciding which pattern to adopt for a new feature or if you plan to introduce a new shared template loader or generator. This guide will evolve as more shared utilities or conventions appear.#
