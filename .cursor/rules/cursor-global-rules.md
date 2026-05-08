# Global Cursor Rules — Salesforce Development
# Scope: Applies across all Salesforce projects
# Author: Team Standard | Maintained by: Practice Lead
# Last Updated: April 2026

---

## ⚠️ Before Writing Any Code — Mandatory Pre-Edit Rule

**When the task is an edit or modification (not net-new), always retrieve the latest version of the file from the org before generating any changes.**

- Run `sf project retrieve start --source-dir force-app/main/default/<component-path>` to pull the latest metadata from the target sandbox before editing.
- Never assume the local file in VS Code is in sync with the org — it may be stale, manually edited in the org, or modified by another team member.
- If retrieval is not possible in the current context, explicitly warn the user: *"I cannot confirm this is the latest version from the org. Please run a retrieve before applying these changes."*
- This rule applies to: Apex classes, triggers, LWC components, Aura components, Flows, and any other metadata that can be edited both locally and directly in the org.

## 🚫 Deployment Safety Rules — Non-Negotiable

- **If a deployment fails, stop and ask.** Do not attempt to work around the error by trying alternative deploy commands, flags, or approaches. Surface the exact error to the user and wait for instruction.
- **Never use `--ignore-errors`, `--ignore-warnings`, or any force-deploy flags** to push past a failure. Errors exist for a reason — suppressing them risks corrupting org state.
- **Never deploy a full folder** (e.g. `force-app/main/default/`). Always deploy at the **specific component level** — individual classes, triggers, LWC folders, or flows by name.
- Acceptable deploy commands target explicit components only:
  - `sf project deploy start --source-dir force-app/main/default/classes/MyClass.cls`
  - `sf project deploy start --metadata ApexClass:MyClass`
- If you are unsure which components need deploying, **ask the user** rather than deploying broadly.

---

## 🧠 AI Behaviour — How Cursor Should Assist

- You are assisting an **experienced Salesforce development team** working on enterprise-grade orgs.
- Default to **production-safe**, **governor-limit-aware** code at all times.
- Never generate code that bypasses platform guardrails or uses anti-patterns.
- When multiple valid approaches exist, **explain the trade-offs** before choosing one.
- Always match the **API version already present** in the project's `sfdx-project.json`. Do not assume or upgrade API versions.
- If a request is ambiguous, **ask a clarifying question** rather than guessing.
- Flag any suggestion that could have **deployment risk** (e.g. schema changes, permission impacts, automation conflicts).

---

## ☁️ General Salesforce Standards

- Always follow **Salesforce Well-Architected principles**: Scalable, Secure, Resilient.
- Prefer **platform-native solutions** before writing custom code. Always evaluate: Can this be done declaratively first?
- Never hardcode **Record IDs, User IDs, Profile IDs, or Role IDs** — these are org-specific and will break across environments.
- Avoid hardcoding **URLs or org domain references**. Use `System.URL.getOrgDomainUrl()` or named credentials where needed.
- Use **Custom Labels** for all user-facing strings and messages. This ensures translatability and centralised management.
- Constants that are not user-facing (e.g. status values, developer-internal strings) should be defined in a dedicated **Constants Apex class**, not scattered inline.
- Do not use **deprecated APIs or components** — always check if a method, component, or feature is marked deprecated in the current release.
- Adhere to **least-privilege security** — FLS, CRUD, and sharing rules must be respected in all data access patterns.

---

## ⚡ Apex Standards

### Structure & Patterns

- **One trigger per object, no exceptions.** Trigger logic must never live inside the trigger file itself.
- Use the **Trigger Factory pattern**:
  - `ObjectNameTrigger.trigger` → calls `TriggerFactory.createHandler(ObjectNameHandler.class)`
  - `ObjectNameHandler.cls` → implements `ITriggerHandler` interface with `beforeInsert()`, `afterUpdate()` etc.
  - `TriggerFactory.cls` → centrally instantiates and routes handlers
- All business logic lives in **handler classes or service classes**, never in triggers directly.
- Use **service layer classes** for complex cross-object or cross-handler logic. Keep handler classes thin.
- Follow **separation of concerns**: Trigger → Handler → Service → Selector/Repository → Domain.

### Governor Limits — Non-Negotiable

- **ZERO tolerance for SOQL or DML inside loops.** This is a hard rule, no exceptions.
- Collect IDs or records into collections first, then execute **bulk SOQL/DML outside the loop**.
- Always use **collections** (Lists, Maps, Sets) for bulk processing.
- Be conscious of: 100 SOQL queries, 150 DML statements, 10,000 records per transaction, 6MB heap, 60s CPU limit.
- When querying large datasets, use **SOQL for loops** (`for (SObject s : [SELECT...])`) to avoid heap overflow.
- Avoid `Database.query()` with dynamic SOQL unless absolutely necessary — if used, sanitise inputs to prevent SOQL injection.

### Bulkification

- Every Apex method that processes records must handle **collections of records**, not single records.
- Method signatures should accept `List<SObject>` or `Map<Id, SObject>`, never just a single `SObject` unless it's a utility.
- Triggers must always work correctly whether 1 or 200 records are processed.

### Error Handling

- Use try-catch blocks for **DML operations in service/integration classes**. Never suppress exceptions silently.
- Use `Database.insert(records, false)` (partial success) only when explicitly required, and always handle `SaveResult` errors.
- Surface meaningful error messages. Use `AuraHandledException` for LWC-facing Apex methods so errors propagate cleanly to the UI.
- Log exceptions using a **platform event-based or custom object-based logging utility** — never just `System.debug` for production error tracking.

### Security

- Always enforce **FLS and CRUD** using `WITH SECURITY_ENFORCED` in SOQL or `Security.stripInaccessible()` before DML.
- Use **`with sharing`** on all classes by default. Use `without sharing` only when explicitly needed and comment why.
- Never trust user input in dynamic SOQL — always use bind variables (`:variable`) to prevent SOQL injection.

### Testing

> ⚠️ Current team discipline: minimal. These rules exist to **uplift** toward a healthy baseline.

- **Minimum 75% code coverage is the floor, not the goal.** Target 90%+ for all new code.
- Every test class must use **`@testSetup`** for shared test data.
- Never use `seeAllData=true` in test classes. Always create test data explicitly.
- Always use the **`TestFactory` class** to create test records — never instantiate SObjects inline across test classes. This ensures consistency and reduces maintenance overhead.
- Tests must cover **positive, negative, and bulk scenarios** (200-record bulk test is mandatory for trigger handlers).
- For every tested functionality, **both a positive and a negative assert are required**:
  - ✅ Positive: assert the expected outcome when inputs are valid
  - ❌ Negative: assert the correct behaviour when inputs are invalid, missing, or edge-case (e.g. null values, wrong record type, missing required fields)
- Use **`System.assertEquals(expected, actual, 'meaningful message')`** — never use bare `System.assert(condition)` without a message.
- Use **`Test.startTest()` / `Test.stopTest()`** to reset governor limits and test async behaviour.
- Test class naming convention: `ClassNameTest.cls` (e.g. `AccountHandlerTest.cls`).
- All test classes must have `@isTest` annotation at the class level, not just method level.

### Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Trigger | `ObjectNameTrigger` | `AccountTrigger` |
| Handler | `ObjectNameHandler` | `AccountHandler` |
| Service | `ObjectNameService` | `AccountService` |
| Test Class | `ClassNameTest` | `AccountHandlerTest` |
| Constants | `AppNameConstants` | `CoreConstants` |
| Batch | `BatchObjectNameDescription` | `BatchAccountCleanup` |
| Schedulable | `ScheduleClassName` | `ScheduleAccountBatch` |

### JSDoc-Style Comments

- All `public` and `global` methods must have an ApexDoc comment block:

```apex
/**
 * @description Processes account records and updates related contacts.
 * @param accountIds Set of Account IDs to process
 * @return Map of Account ID to updated Contact list
 */
public static Map<Id, List<Contact>> processAccounts(Set<Id> accountIds) { ... }
```

- All classes must have a header comment stating purpose, author, and last modified date.

---

## 🌩️ Flow Standards

### When to Use Flow

- Use **Flow-first** for: record-triggered automation, simple field updates, approval processes, guided screen interactions, and scheduled automation.
- Use **Apex** when: logic is too complex for Flow, requires advanced collections manipulation, requires callouts, or needs precise error handling.
- Never build the same logic in both Flow and Apex for the same object/trigger context — **pick one and own it**.

### Design Principles

- Every Flow must have a **clear, descriptive API name**: `Object_TriggerType_Description` (e.g. `Account_AfterSave_SyncToContact`).
- Add a **description** to every Flow explaining its purpose, trigger context, and any dependencies.
- Use **Decision elements** to centralise conditional logic — avoid duplicating conditions across branches.
- Break large Flows into **sub-flows** for reusability and testability. A Flow exceeding ~30 elements is a candidate for decomposition.
- Never chain more than **2 levels of sub-flow** — it becomes impossible to debug.
- Avoid **cross-object field references in trigger-context Flows** where the object wasn't explicitly queried — this can cause unexpected DML behaviour.

### Governor Awareness

- Be aware that each Flow element that queries or updates records counts toward **DML and SOQL limits** within the transaction.
- Prefer **one Get Records element** that retrieves all needed records, over multiple Gets scattered through the Flow.
- Avoid **loops with DML inside** — same rule as Apex. Use collection-level assignment before a single DML element outside the loop.

### Error Handling

- Always add a **Fault Path** to every DML element (Create/Update/Delete Records). The default "unhandled fault" message is not acceptable in production.
- Fault paths must at minimum **log the error** (via a platform event or custom log record) and show a **user-friendly message** on screen Flows.

### Naming Conventions

| Element Type | Convention |
|---|---|
| Flow API Name | `Object_Context_Description` |
| Variables | `var_ObjectField_Purpose` (e.g. `var_AccountId_Input`) |
| Collections | `col_ObjectName_Purpose` (e.g. `col_Contacts_ToUpdate`) |
| Formulas | `frm_Description` (e.g. `frm_IsEligible`) |
| Constants | `const_Description` (e.g. `const_StatusActive`) |

---

## 🖥️ LWC (Lightning Web Components) Standards

### Architecture

- Follow **single responsibility** — one component does one thing. If a component is handling data fetching, display, and user interaction all in one, split it.
- Separate into:
  - **Container components** (smart): handle data wiring, imperative calls, state management
  - **Presentational components** (dumb): receive data via `@api`, emit events upward, no direct data access
- Use **`@api`** properties for parent-to-child communication.
- Use **custom events** for child-to-parent communication. Never manipulate a parent's DOM from a child.

### Data Access

- Use **`@wire`** for read operations where reactivity is needed (record data that reacts to ID changes).
- Use **imperative Apex calls** (async/await) for operations that require explicit control: form submissions, conditional fetches, post-action refreshes.
- Use **`getRecord` / Lightning Data Service** for simple single-record reads — avoids an unnecessary Apex method.
- Always handle **loading, error, and empty states** explicitly in every component that fetches data.

```javascript
// Always handle all three states
@wire(getAccountData, { accountId: '$recordId' })
wiredAccount({ error, data }) {
    if (data) {
        this.account = data;
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.account = undefined;
    }
}
```

### Error Handling

- Never silently swallow errors. Always set an error property and display it in the template.
- Use `try/catch` with `async/await` for imperative calls.
- Surface errors using **`LightningAlert`** or a custom toast notification utility — not `console.error` alone.

### Performance

- Use **`@wire` with `cacheable: true`** on Apex methods that are read-only — this enables client-side caching.
- Avoid calling Apex in `connectedCallback` for data that can be wired reactively.
- Use **lazy loading** for heavy child components when they are conditionally rendered.
- Avoid **unnecessary re-renders** — don't set reactive properties inside loops or `renderedCallback` without guards.

### Security

- Never use `innerHTML` or `lwc:dom="manual"` without explicit justification — XSS risk.
- Do not expose sensitive data via `@api` properties if the component can be embedded in Experience Cloud.
- Always validate inputs on both client (UX) and server (Apex) sides.

### Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Component folder | `camelCase` | `accountSummaryCard` |
| Component JS class | matches folder | `accountSummaryCard` |
| `@api` properties | `camelCase` | `recordId`, `objectApiName` |
| Custom events | `kebab-case` | `record-saved`, `status-changed` |
| Private properties | `_camelCase` with underscore prefix | `_isLoading` |
| CSS classes | `kebab-case` | `card-header`, `error-message` |

### JSDoc Comments

- All `@api` properties must be documented:

```javascript
/**
 * @description The Salesforce Record ID of the Account to display.
 * @type {string}
 */
@api recordId;
```

- All public methods exposed via `@api` must have full JSDoc.

---

## ⚡ Aura Standards (Legacy — Minimal Coverage)

> Aura is in maintenance mode for this team. No new Aura components should be built.
> All new UI work must use LWC.

- If maintaining existing Aura components, **do not introduce new anti-patterns**.
- Keep `helper.js` as the logic layer. Keep `controller.js` thin (call helper methods only).
- Use `$A.enqueueAction` correctly — set `action.setStorable()` for read-only server calls.
- When a full rewrite to LWC is not feasible, wrap LWC components inside Aura using `<c:lwcComponentName>` interop.
- All Apex methods called from Aura must be `@AuraEnabled` — do not reuse `@RemoteAction` or other patterns.
- Add a `// TODO: Migrate to LWC` comment at the top of any Aura component touched during maintenance.


---

## 📐 Static Analysis (Introducing PMD + ESLint)

> The team is in the process of introducing static analysis. These are the target standards.

### Apex (PMD / Salesforce Code Analyser)

- Target zero violations for **Critical and High** severity PMD rules.
- Key rules to enforce from day one:
  - `ApexSOQLInjection` — no string concatenation in dynamic SOQL
  - `ApexCRUDViolation` — FLS/CRUD must be enforced
  - `AvoidDeeplyNestedIfStmts` — max 3 levels of nesting
  - `ApexUnitTestClassShouldHaveAsserts` — every test must assert something
  - `NullAssignment` — no explicit null assignments in production logic

### LWC (ESLint)

- Use the **`@salesforce/eslint-config-lwc`** base config.
- No `console.log` statements in committed code — use a logging utility or remove before PR.
- No unused variables or imports.
- All `@api` properties must be documented (enforced via JSDoc ESLint plugin where possible).

---

## 📋 Quick Reference — Do / Don't

| ✅ Do | ❌ Don't |
|---|---|
| One trigger per object | Logic inside trigger files |
| Trigger Factory pattern | Bare triggers |
| Bulkify all Apex | SOQL/DML inside loops |
| `WITH SECURITY_ENFORCED` | Skip FLS/CRUD checks |
| Custom Labels for UI text | Hardcoded strings in UI |
| Flow for declarative automation | Duplicate automation in both Flow and Apex |
| Fault paths on all Flow DML | Unhandled Flow faults |
| `@wire` for reactive reads | Apex callouts in `connectedCallback` |
| LWC for all new UI | New Aura components |
| `with sharing` by default | `without sharing` without a comment |
| `AuraHandledException` for UI errors | Silent exception swallowing |
| JSDoc on all public methods and `@api` props | Undocumented public interfaces |
