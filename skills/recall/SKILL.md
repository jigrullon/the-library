---
name: recall
description: Search this project's memory (dated logs in memory/log/, indexed by meaning + keyword in memory/index.sqlite3) to answer questions about past work — "what did we decide about X," "when did we build Y," "did we ever discuss Z," or any question whose answer likely lives in a past session rather than the current one. Trigger on "recall," "what did we decide/say/do about," "when did we," "did we ever," "search memory for," or when a request references specific past work not visible in the current conversation. Always cite the source; never paraphrase from memory without attribution.
---

# Recall (memory search)

Answers questions from this project's history by querying the local
vector+keyword index (`memory/index.sqlite3`, built by
`memory/scripts/index_memory.py` from `memory/log/*.md`) instead of relying
on your own possibly-stale recollection of the conversation, or guessing.

## Procedure

1. Run the search script with the user's question (or a short paraphrase of
   it) as the query:

   ```
   memory/.venv/bin/python memory/scripts/search_memory.py "<query>" --json --limit 6
   ```

   Use `--json` so you get structured fields, not just formatted text.

2. **If no index exists yet** (`memory/index.sqlite3` missing), the script
   exits 1 with a message telling you to run `index_memory.py` first. Do
   that (`memory/.venv/bin/python memory/scripts/index_memory.py`), then
   retry the search once.

3. **Read the results, don't skim past the metadata.** Each result carries
   `citation` (a ready-made "file — date — heading" string), `date`,
   `source_file`, `heading_path`, and `body` (the actual stored text, not a
   re-paraphrase of it).

4. **Answer using the actual content, and always attach the citation.** The
   shape of a good answer: *what was said* (quote or closely paraphrase the
   `body`, don't invent detail beyond it) — *when* (`date`) — *where*
   (`source_file` / `heading_path`). Don't drop the citation even in a short
   answer; "per `memory/log/2026-07-25.md`, Auto-captured > 14:32: ..." is
   the bar, not "I recall that...".

5. **If nothing relevant comes back, say so plainly.** Don't fill the gap
   with a plausible-sounding guess. A low-relevance top result (check
   `scores.relevance` in the JSON — below roughly 0.3 is weak) is worth
   surfacing with a caveat ("the closest match I found was X, but it's not
   a strong match") rather than presenting it as a confident answer.

6. **Multiple results can disagree or refine each other over time** (e.g. a
   decision that was revisited later). Prefer the more recent one when they
   conflict, but mention both with their dates if the discrepancy itself
   seems worth surfacing — that's exactly the kind of thing a paraphrase
   would silently lose.

## What this does NOT search

- `memory/working-memory.md` (the frozen snapshot) is not indexed — it's
  checked at a different cadence (injected fresh every session) and would
  go stale relative to the index. If the question is about *current*
  priorities/threads rather than history, that file (already in your
  context at session start) is the better source, not this search.
- Anything not yet captured into a dated log: today's conversation only
  gets indexed after the Stop hook auto-captures it and someone re-runs
  `index_memory.py` (auto-capture writes the log entry live; indexing it is
  a separate step, not yet wired to run automatically).
