# Offline Conflict Resolution Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task. Follow strict test-driven-development for all code changes. Bite-sized tasks only.

**Goal:** Implement robust offline conflict resolution for the SyncService so that when the same record is edited on multiple devices while offline, the system can intelligently merge or resolve conflicts when both devices come online.

**Architecture:**
- Extend the existing SyncService and SyncOutbox pattern
- Add conflict detection when processing incoming changes from Supabase
- Implement a "Last Write Wins" strategy with audit logging as phase 1
- Add optional user resolution UI for complex conflicts as phase 2
- Use the existing repository pattern and Riverpod providers
- Add new `conflict_log` table for auditing
- Follow all existing patterns (soft delete, boat_id, Drift + Supabase, Pro gating where applicable)

**Tech Stack:** Supabase, Drift, Riverpod, existing SyncService, new conflict resolution utilities

**Key Principles:** YAGNI, DRY, TDD, frequent commits, reuse existing repository and sync patterns. Do not create generic tables - extend specific ones where needed.

---

### Task 1: Update Documentation

**Objective:** Document the conflict resolution strategy in all relevant specs.

**Files:**
- Modify: `progress.md` (mark as in progress, update metrics)
- Modify: `ARCHITECTURE.md` (add detailed conflict resolution section)
- Modify: `prd.md` (add to technical requirements)

**Steps:**
1. Add "Offline Conflict Resolution" as current sprint in progress.md
2. Document strategy in ARCHITECTURE.md (Last Write Wins + audit log + future user resolution)
3. Update PRD with conflict handling requirements

**Verification:**
```bash
grep -A 5 "Offline Conflict Resolution" progress.md ARCHITECTURE.md prd.md
```

**Status:** [completed]

---

### Task 2: Add Conflict Log Model and Table

**Objective:** Create data model for tracking conflicts.

**Files:**
- Modify: `lib/models/models.dart` (add ConflictLog model)
- Modify: Supabase schema (via migration or SQL in docs)

**Steps (TDD):**
1. Write failing test for ConflictLog model serialization
2. Run test to verify failure
3. Add the `ConflictLog` domain model + `ConflictLogs` Drift table (a reserved table already exists) following existing patterns
4. Run test to verify it passes
5. Register the table in `@DriftDatabase(tables: [...])`

**Verification:**
```bash
flutter test test/conflict_log_test.dart -q
grep -A 20 "class ConflictLog" lib/models/models.dart
```

**Status:** [pending]

---

### Task 3: Extend SyncService with Conflict Detection

**Objective:** Add conflict detection logic in SyncService when processing incoming changes.

**Files:**
- Modify: `lib/services/sync_service.dart` (add conflict detection in _handleIncomingChanges)
- Create: `lib/services/conflict_resolution_service.dart`

**Steps (TDD):**
1. Write failing test for conflict detection (same record edited on two devices)
2. Run test to verify it fails
3. Implement basic Last Write Wins strategy with audit logging
4. Run test to verify it passes
5. Add conflict_resolution_service to di.dart

**Verification:**
```bash
flutter test test/sync_conflict_test.dart -q
grep -A 15 "conflict" lib/services/sync_service.dart
```

**Status:** [pending]

---

### Task 4: Add Conflict Resolution UI

**Objective:** Create UI for users to review and resolve conflicts when they occur.

**Files:**
- Create: `lib/ui/conflicts/conflict_resolution_screen.dart`
- Modify: `lib/ui/settings/settings_screen.dart` (add link to conflicts)
- Modify: relevant providers

**Steps (TDD):**
1. Write UI test for conflict resolution screen
2. Implement screen with list of conflicts and resolution options (keep local, keep remote, merge)
3. Integrate with ConflictResolutionService
4. Add to navigation from settings

**Verification:**
- Screen follows TitleTile + drawer pattern
- User can resolve conflicts
- Resolution updates both the local Drift DB and Supabase

**Status:** [pending]

---

### Task 5: Final Integration, Testing & Documentation

**Objective:** Complete integration, add comprehensive tests, update all docs.

**Files:**
- Update: `progress.md`, `ARCHITECTURE.md`, `prd.md`
- Add tests for edge cases (concurrent edits, network failures, etc.)

**Steps:**
1. Run full test suite
2. Update progress.md to mark feature as complete
3. Add to ARCHITECTURE.md with implementation details
4. Test multi-device scenario simulation
5. Commit with conventional messages

**Verification:**
```bash
flutter test
grep -A 10 "Offline Conflict Resolution" progress.md ARCHITECTURE.md
```

**Status:** [pending]

---

**Success Criteria:**
- SyncService can detect and resolve conflicts using Last Write Wins with audit trail
- User can review conflicts in UI and choose resolution strategy
- All changes are properly synced to Supabase and other devices
- No data loss in conflict scenarios
- All tests pass and documentation is updated
- Follows existing architecture patterns (no new generic tables)

**This plan is ready for execution.** 

**Next action:** Start with Task 1 (documentation) then proceed sequentially with TDD for each coding task.
