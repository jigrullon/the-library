---
name: remember
description: Save, update, or remove an entry in this project's working-memory snapshot (memory/working-memory.md) — the capped file injected at the start of every session. Trigger on "remember this," "note that," "remember that," "save this," "don't forget," "forget about X," or an explicit ask to update working memory. Do NOT trigger on generic file-saving requests (e.g. "save this file", "save my changes") — this is specifically about the project's persistent working-memory snapshot, not disk I/O.
---

# Remember (working-memory writer)

Curates `memory/working-memory.md` — the capped, three-section snapshot that
`.claude/hooks/inject_working_memory.py` injects at the start of every
session. This is a **different system** from Claude Code's built-in
per-project auto-memory (the one under
`~/.claude/projects/.../memory/MEMORY.md`) — don't confuse the two, and
don't touch the auto-memory files from this skill. This skill only ever
edits `memory/working-memory.md` in this repo.

The file is treated as a **frozen snapshot for the current session** — a
write made now is picked up at the *next* session start, not mid-conversation.
Say so if the user seems to expect the change to appear immediately in this
same session.

## Procedure

1. **Read the entire file first, every time.** Never edit blind, never
   append without having just re-read the current content — that's the
   dedup step. `memory/working-memory.md` has three sections: `Active
   threads`, `Notes worth keeping`, `Pending decisions`.

2. **Classify the request:**
   - **Add** — a new fact, thread, or open question not already covered.
   - **Replace** — supersedes or corrects something already in the file.
   - **Remove** — "forget about X" / "that's no longer true" / "drop the
     note about X" / a pending decision that just got resolved.

3. **Pick the section** the content belongs in (see judgment rules below).
   If genuinely ambiguous between two sections, make the call and say which
   one you picked — don't stall on a clarifying question for this.

4. **Apply the cap.** Target **~2000 characters** for the file body (this
   is the number in the file's own header comment — check the comment
   still says the same thing; if the user asked to change the cap, edit the
   comment too). If the change would exceed it, consolidate *before*
   appending — see below. Never silently blow past the cap.

5. **Write the file back** with `Edit`, preserving the header comment and
   the three-heading structure.

6. **Confirm in one line** what changed and in which section. Don't
   re-summarize the whole file back to the user.

## Judgment rules (edit these as you learn what's worth keeping)

These are deliberately prose, not code — tune them as the user corrects you.

**Duplicate / supersede detection.** Before adding anything, scan every
existing bullet across all three sections for the same *subject* (not just
the same wording — "Stripe coupons need applies_to" and "every coupon must
scope itself" are the same fact). If a bullet already covers the subject:
- If the new info is a straight update/correction → **replace** that bullet
  in place, don't append a second one.
- If the new info is materially the same as what's already there → treat as
  a no-op, tell the user it's already noted (point to the existing bullet)
  rather than writing a near-duplicate.
- If the new info narrows or adds a caveat to an existing bullet → fold it
  into that bullet rather than adding a new line next to it.

**Section placement.**
- *Active threads* — work genuinely in progress across sessions (a
  multi-step build, a branch not yet merged, something you'd want restated
  at the start of the next session so you don't have to re-derive where you
  left off).
- *Notes worth keeping* — durable, low-churn facts: naming quirks, gotchas,
  conventions, "X actually means Y" translations, hard-won lessons. These
  rarely get removed, only superseded.
- *Pending decisions* — open questions where someone (usually the user)
  needs to decide something, and the decision isn't made yet. When a
  pending decision gets resolved, don't just leave it — either delete it or
  convert it into a `Notes worth keeping` bullet recording what was decided
  and why, whichever the user's phrasing implies.

**Consolidation when over cap (do this before trimming content quality).**
1. Look for resolved `Active threads` or `Pending decisions` entries — the
   thread finished, the decision got made — and remove them first; that's
   free space, not lost information (assuming the outcome is worth keeping,
   fold it into `Notes worth keeping` in compressed form).
2. Merge bullets covering the same subject that should have been one bullet
   already.
3. Tighten wording — this file is a snapshot, not documentation; short
   fragments beat full sentences.
4. Only as a last resort, and only if nothing above frees enough room, ask
   the user which existing entry to drop rather than silently deciding for
   them — this is the one step in this whole procedure worth pausing for,
   since deleting someone's note without asking is the failure mode this
   skill exists to avoid.

**"Forget about X" handling.** Search all three sections for entries about
X. If found, remove them and say exactly what was removed. If nothing
matches, say so plainly — don't pretend to have removed something that
wasn't there.

**When NOT to write anything.** If the user's "remember this" is about
something that belongs in the *daily log* instead (a one-off event, a
specific incident, detail that doesn't need to survive as a standing
fact/thread/decision) rather than the curated snapshot, say so and suggest
it can go in today's log file instead — this skill doesn't write there
itself (that's the auto-capture Stop hook's job, not yet built).
