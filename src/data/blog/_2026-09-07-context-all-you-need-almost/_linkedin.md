Hook options: 1 / 2 / 3 (each ≤ 140 characters, counted)
- 1 (96): The retry policy looked production-ready. It would have billed the customer twice on a timeout.
- 2 (103): A timeout after POST /charges is not a failure. It is an unknown. Retrying it is how you double-charge.
- 3 (107): The model did not ignore your instructions. It answered a well-posed question that was not the one you had.
Using: 1
Audience class: B
Angle extracted: A fluent “production” retry policy double-charges a payment POST because a timeout is unknown, not failed; one system fact beats a senior-engineer persona.
Link mode: first-comment
Character counts: hook = 96; post body = 2211 (including line breaks, excluding the first-comment block)

```
---POST---
The retry policy looked production-ready. It would have billed the customer twice on a timeout.
Ask a model for an HTTP retry policy and you get exponential backoff, jitter, a cap, and a list of "transient" errors.
That is often real advice. For a different system than yours.

The interesting question is not how to retry. It is whether retrying is even allowed.

A timeout after POST /charges does not mean the charge failed. The provider may have created it, then the connection dropped before the body came back.

Retry that POST and you create a second charge. The decorator did what you asked.

The contract you needed was "at most one charge." Nobody wrote that down, so nothing in the code enforces it.

I will not blame the retry library. The model answered a well-posed question that was not the one you had.

"You are a senior engineer" and "be thorough" do not substitute for a constraint. They raise the register of the answer, not the problem.

Words like production-ready, safe, and best feel like constraints. They are invitations to pick a meaning.

You already have one. The model does not.

The fact that changes the answer is short. Charge creation has no idempotency key the server can use to collapse a duplicate.

A timeout is an unknown outcome, not a failed one. Duplicate charges are unacceptable.

Status reads and charge writes are different jobs. A GET of payment status can retry inside a two-second budget.

Charge creation should record unknown and stop.

Folklore only has success and failure. Payments need three.

This week, forbid code until the model fills a table: safe to retry, never retry, or retry only with an idempotency key. Make it list the unknowns.

If it cannot fill that table from what you gave it, the answer is not ready. The missing row is the work.

If two runs disagree, you starved the advisor. Conflicting answers are the default when a colleague would have demanded the files first.

The full write-up, with the timeout-after-commit path that compiles and still double-charges, is on FastCodeGuru.org.

Which call in your system is still wrapped in a retry, even though a timeout leaves you not knowing whether it committed?

#llm
#debugging
#python
---END POST---
```

```
---FIRST COMMENT---
Full write-up, with the timeout-after-commit simulation that prints two charges for one order:

https://fastcodeguru.org/[SLUG]
---END FIRST COMMENT---
```

```
---
## For Carlos (not for publication)
- Hook why it won: Concrete cost on a phone screen (looked careful, billed twice). Unresolved enough to expand, specific enough that swapping nouns would break it. The well-posed-question hook is the article thesis; save it for a follow-up.
- Claims to verify: Timeout after POST can mean the charge already committed; no idempotency key makes automatic retry a duplicate; GET status vs POST charge are different jobs; interactive budget is 2s in the article; persona/"thorough" raises register only; success/failure folklore vs UNKNOWN as a third outcome; "missing row is the work" matches the article's retry-classification table.
- URL to paste (replace [SLUG] if needed): https://fastcodeguru.org/[SLUG] — likely context-is-all-you-need-almost; article body did not include a URL.
- Image to attach: none. If you want one, a two-column card only: GET /status (retry inside 2s) vs POST /charges (record UNKNOWN, do not retry). Keep the URL in the first comment so LinkedIn does not build a link-preview card.
- Follow-up posts from the same article (3 bullets, one idea each, not written out):
  - More context is not better context: burying "do not retry charges" in a repo dump / stale wiki.
  - Same empty "optimize this" prompt, three jobs: HUD of eight IDs vs 50M exact IDs vs adversarial keys.
  - Four-condition check (minimal / relevant / same-length irrelevant / decisive fact removed) scored on task correctness, not polish.
- Cuts you can make if the composer says you are over 3,000:
  - Drop the two-runs-disagree paragraph.
  - Drop "You already have one. The model does not."
  - Merge "Charge creation should record unknown and stop." into the GET/POST paragraph.
  - Drop the first-person retry-library line if the well-posed-question idea is already landing.
```
