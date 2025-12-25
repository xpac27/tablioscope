# Repeat & Volta Inference — Specification and Implementation Plan

This document specifies a **format-agnostic** Javascript engine that infers **repeat signs** (`|: :|`) and **alternate endings / voltas** (`1.` / `2.`) from a fully **linear (unrolled)** sequence of measures, while guaranteeing:

> **Correctness:** `unroll(infer(S)) == S` (exactly), for all inputs `S`.

The engine is designed to work across multiple score formats by injecting a **fingerprinting adapter**, and it includes a verification step (“prove-by-construction”) so unsafe folds are never emitted.

---

## Objectives

- Infer:
  - **Simple repeats**: `|: ... :|`
  - **Voltas** (alternate endings): `1.` / `2.` (extendable to 3+ later)
- Enforce **hard boundaries** (time signature / key / tempo / rehearsal marks) by default.
- Be **deterministic** (same input → same plan).
- Enable **easy testing** using “letter fixtures” like: `A B C A B C D`.

---

## Glossary

- **Linear / unrolled score:** the performed sequence of measures, laid out end-to-end.
- **Folded score:** a compact representation using repeats/voltas that expands to the linear score.
- **Fingerprint:** canonical measure identity used to compare measures for equality.
- **FoldPlan:** repeat/volta constructs expressed in terms of measure indices.

---

## High-level architecture

### 1) Format-agnostic inference engine

The engine consumes an abstract sequence of *items* (measures) through an adapter:

```text
len() -> int
fingerprint(i) -> Fingerprint        // string/bytes; equality defines measure equality
boundary_id(i) -> BoundaryID | nil   // hard boundary between i-1 and i
debug_label(i) -> string             // optional, for logs
```

The engine **must not** inspect score-specific data structures.

### 2) Format adapters

Adapters implement the interface above for:
- **Letters fixtures** (tests and early MVP)
- **Repo’s actual score format** Alphatext:
  - documented in `doc/alphatext_format-knowledge.md`
  - full documentation at `https://github.com/CoderLine/alphaTabWebsite` in folder `alphaTabWebsite/tree/main/docs/`
  alphatex

---

## Formal semantics: unrolling

A folded representation is defined by:
- The original measures (indices `0..N-1`)
- A `FoldPlan` consisting of:
  - `RepeatSpan { start, end, times=2 }`
  - Optional `VoltaSpan { start, end, allowed_passes }` inside the repeat

### Unroll semantics (reference algorithm)

Assume (initially) at most **one** repeat region (no nesting) and voltas only inside it:

```text
unroll(plan, N):
  out = []

  // A) before repeat
  emit indices 0 .. rs-1

  // B) repeat region expanded
  for pass in 1..times:
    i = rs
    while i <= re:
      if i begins a volta segment:
        if pass in allowed_passes:
          emit indices [volta.start .. volta.end]
        i = volta.end + 1
      else:
        emit index i
        i += 1

  // C) after repeat
  emit indices re+1 .. N-1

  return out
```

**Volta constraints:**
- inside exactly one repeat span
- non-overlapping
- ordered by start index

This semantics is the basis for verification and correctness claims.

---

## Correctness strategy: prove-by-construction

Candidate folds are *proposed* heuristically, then *accepted* only if verified by semantics.

### Verification rule

Given input length `N` and adapter `A`:

1. `original_fps = [A.fingerprint(i) for i in 0..N-1]`
2. `unrolled_indices = unroll(candidate_plan, N)`
3. `unrolled_fps = [A.fingerprint(j) for j in unrolled_indices]`

Accept candidate iff:

```text
unrolled_fps == original_fps
```

and boundary rules are satisfied.

This guarantees any emitted plan is correct with respect to the defined semantics.

---

## Repeat / volta candidate generation

### A) Simple repeats (exact)

Detect repeated contiguous blocks `(a, b, L)`:

```text
fps[a..a+L) == fps[b..b+L)
```

Filter by:
- `L >= min_repeat_len` (default 2–4 measures)
- no hard boundary crossed within the block occurrences
- additional readability heuristics (optional): alignment to phrases, etc.

### B) Voltas (alternate endings)

Detect patterns equivalent to:

```text
P + E1 + P + E2 + C
```

Where `P` and `C` are shared, and `E1`, `E2` diverge.

Constraints (initial targets):
- `len(P) >= min_prefix_len` (e.g., 2)
- `len(E1), len(E2) <= max_ending_len` (e.g., 8)
- rejoin continuation `C` must be unambiguous
- no boundary crossing

Candidates may over-generate; verification ensures safety.

---

## Plan selection & determinism

Multiple verified plans may exist.

### Scoring

Define a cost function:
- baseline: print all measures normally
- savings for folding repeats
- penalties for:
  - repeat barlines
  - volta brackets
  - complexity / excessive segmentation

### Deterministic tie-breaks

Sort candidates and break ties by:
1. earliest repeat start
2. longest repeated span
3. fewer constructs
4. earliest end

Ensure stable ordering so runs are reproducible.

---

## Data model (suggested)

```text
FoldPlan
  repeats: [RepeatSpan]          // v1: 0..1 element; later allow multiple non-overlapping
  voltas:  [VoltaSpan]           // tied to a specific repeat span

RepeatSpan
  start: int
  end: int
  times: int (default 2)

VoltaSpan
  start: int
  end: int
  allowed_passes: set<int>       // {1}, {2}, etc.
  // optionally: label "1.", "2."
```

---

## Logging and debugging

Add a verbose mode that logs:
- candidate generation summary
- reasons for rejection:
  - boundary crossing
  - verification mismatch (show first differing position and labels)
  - failing constraints (prefix too short, endings too long, etc.)

---

## Roadmap (with an early parsing MVP step)

### Step 0 — **Parsing MVP + one working example (early)**
Goal: have an end-to-end path that parses a *simple valid example* and returns the correct result.

- Implement a tiny parser for a text fixture, e.g.:
  - Input file: `A B C A B C D`
  - Output: a folded rendering like `|: A B C :| D` (or a printed `FoldPlan`)
- Use the **letters adapter**:
  - `fingerprint(i) = token[i]`
  - `boundary_id(i) = nil`
- Implement minimal inference: detect the one obvious repeat candidate.
- Implement `unroll(plan)` + verification.
- Provide one unit test asserting:
  - inferred plan is accepted by verification
  - rendered folded form matches expectation
  - `unroll(infer(S)) == S`

This step ensures correctness plumbing (parse → infer → verify → render) is validated immediately.

---

### Step 1 — Letters adapter + golden tests
- Expand tests using fixtures:
  - simple repeat: `A B C A B C D`
  - volta: `A B X A B Y D` → `|: A B [1: X] [2: Y] :| D`
  - boundary stops fold: insert boundary between positions
  - ambiguous patterns → reject (no fold)

---

### Step 2 — Implement the full engine loop (candidates → verify → score → select)
- Candidate enumerator for simple repeats
- Candidate enumerator for voltas
- Verification gating
- Deterministic scoring selection
- Return `FoldPlan`

---

### Step 3 — Integrate repo’s real adapter (Alphatext documented in doc/alphatext_format-knowledge.md)
- Implement strict measure fingerprinting for the real format:
  - rhythm, pitch/string+fret, rests, tuplets, ties, techniques relevant to output
- Implement boundary extraction:
  - signature/key/tempo/rehearsal markers as `boundary_id(i)`

---

### Step 4 — Renderer integration
- Integration at the end of existing conversion pipeline (to Alphatext) in jsonToAlphaText.js
  - existing pipeline: JSON → Alphatext
  - new pipeline: JSON → Alphatext → infer folds → Alphatext with repeats
- Render repeat barlines and voltas from `FoldPlan` in Alphatext format

---

### Step 5 — Property testing (recommended)
- Random generators over fingerprint sequences (letters) and/or simplified real measures
- Property: `unroll(infer(S)) == S`
- Add coverage for boundaries and edge cases

---

### Step 6 — Extensions
- Multiple non-overlapping repeats per score

---

### Step 7 — Extensions
- Multi-pass repeats (x3 etc.)

---

## Acceptance criteria

- The verifier ensures the engine cannot emit an incorrect fold.
- Letters fixtures pass and are easy to read and maintain.
- Real adapter integration produces correct output on representative samples.
- Deterministic results across runs.

---

## Appendix: Example expectations (letters)

### Simple repeat
Input:
```text
A B C A B C D
```

Folded:
```text
|: A B C :| D
```

### Volta
Input:
```text
A B X A B Y D
```

Folded:
```text
|: A B 1.[X] 2.[Y] :| D
```

(Exact formatting is renderer-dependent; semantics must match.)
