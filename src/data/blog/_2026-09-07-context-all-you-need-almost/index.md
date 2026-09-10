+++
draft       = false
featured    = true
title       = "Context Is All You Need—Almost"
slug        = "context-all-you-need-almost"
description = "Most disappointing LLM answers are fluent solutions to the wrong problem—the fix is the missing facts, not a fancier prompt."
ogImage     = "./context-all-you-need-almost.jpg"
pubDatetime = 2026-09-07T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "Context Engineering",
    "AI-Assisted Coding",
    "HTTP Retry Policies",
    "Idempotent Requests",
    "Payment Processing",
    "Software Correctness",
    "Exponential Backoff",
    "Timeout Handling",
    "Tenacity Library",
    "C++20 Standard",
    "Hash Tables",
    "Prompt Injection",
    "Retrieval Augmented Generation",
    "Latency Budgets",
    "HTTP Clients",
    "Performance Measurement",
    "Prompt Engineering",
    "Error Handling",
    "Practical Tutorial",
    "Engineering Deep Dive"
]
+++

![Context Is All You Need—Almost](./context-all-you-need-almost.jpg "Context Is All You Need—Almost")

## Table of Contents

---

# Context Is All You Need—Almost

Ask a model to write an HTTP retry policy and you will get exponential backoff, jitter, a retry cap, and a short list of “transient” errors. It will sound like production advice. It often *is* production advice — for a different system than yours.

Now tell it the request creates a payment, the provider has no idempotency keys, and a timeout does not tell you whether the charge landed. The interesting question stops being how to retry. It becomes whether retrying is even allowed.

The model did not need a more elaborate persona. It needed one fact.

I use ChatGPT and Claude every day. I teach people to direct them, review them, and catch them when they are confidently wrong. The pattern I see is not usually “the model failed to follow instructions.” It is this: **the model answered a well-posed question that was not the question you had.**

A prompt tells the model what you want. Context is what makes a correct, useful answer possible. Many disappointing responses are plausible answers to the wrong version of the problem.

Not all of them. Some failures are knowledge gaps, weak reasoning, or the model’s habit of sounding sure. Context is not a spell. It is the difference between asking a competent colleague “what should we do?” in the hallway, and asking after you have put the relevant files on the table.

## Vague words hide decisions the model still has to make

These requests are all understandable. They are also underspecified:

- “Optimize this function.”
- “Should we use a microservice?”
- “Write a retry policy.”
- “Summarize this incident.”

Optimize for latency, memory, or the next person who has to read it? Recommend an architecture for two developers or two hundred? Summarize for the on-call engineer or the board?

The model still answers. It has to. Training taught it that a fluent, helpful completion is the goal. So it fills the gaps with a default problem: a generic service, a generic reader, a generic idea of “safe.” Those defaults are not stupid. They are *average*. Average is how you get a retry wrapper that would be fine on a read-only status endpoint and disastrous on `POST /charges`.

Words like *fast*, *simple*, *safe*, *production-ready*, and *best* feel like constraints. They are not. They are invitations to pick a meaning. You already have one. The model does not.

> **Pro tip:** If you cannot name the decision the answer is supposed to support, you do not have a task yet. You have a topic. Models are excellent at topics. Topics are where generic advice lives.

Generic advice is cheap. The model will give it to you for free, at any length you want, with citations that may or may not exist. Specific, constrained advice is valuable. Models default to cheap unless you force the constraints into the context.

That is also why two runs of the “same” question disagree. You are not consulting one expert. You are sampling a noisy advisor that was starved of the information a colleague would have demanded before answering. Conflicting answers are the default in that situation. Consistency would be the surprise.

## Context is not “background.” It is the information the model can use *this turn*

For this article, **context is the task-relevant information made available to the model when it generates an answer.**

That is broader than the paragraph you typed. Conversation history is context. A retrieved runbook is context. A compiler error is context. The contents of `retry.py` sitting in the sidebar of the chat are context. So is the fact you did *not* paste.

Not everything in that pile is an instruction. A PDF in the retrieval set is evidence to interpret, not an order to obey. Mixing those up is how a model “follows” a stale wiki page that contradicts the code you meant to ask about.

| Component | What it contributes | What the model does if it is missing |
|---|---|---|
| **Goal** | The outcome you are trying to achieve | Picks a popular outcome and optimizes for sounding complete |
| **Evidence** | Code, logs, docs, measurements, diffs | Invents a typical codebase |
| **Constraints** | What is feasible or forbidden | Uses textbook defaults (retry, microservice, `unordered_set`, …) |
| **Decision criteria** | How to choose among valid answers | Optimizes for polish and apparent thoroughness |
| **Audience and output** | What makes the result usable | Writes a blog post at you |
| **Unknowns** | What must be flagged instead of assumed | Silently fills the gap so it can finish the answer |

That last row is the one people skip. If you do not say what you do not know, the model will not know that it does not know it. It will still produce a retry policy. It will just produce one that pretends the unknown is settled.

> **Gotcha:** “Be thorough” and “you are a senior engineer” do not substitute for a constraint. They raise the *register* of the answer. They do not change the problem.

## One HTTP retry, two different jobs

Here is the underspecified request, the one I see constantly:

```text
Write a retry policy for our HTTP client.
```

A typical answer talks about exponential backoff, full jitter, a small number of attempts, and retrying timeouts and connection failures. For a `GET` of payment *status*, that shape is often reasonable. [RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html) treats `GET` as safe and idempotent: the intended effect of repeating the request is the same as doing it once.

`POST` is not idempotent. Repeating it may create a second charge. Payment APIs that want safe retries usually require an idempotency key so the server can collapse duplicates. Stripe’s own API docs are explicit about this: send an `Idempotency-Key` on `POST`, and a connection error is something you can retry *with the same key* without creating a second object. See [Stripe: Idempotent requests](https://docs.stripe.com/api/idempotent_requests). If the provider does not support that, the textbook retry policy is not conservative. It is a double-charge machine.

The contextualized request is not a longer persona. It is facts:

```text
Help design a retry policy for a Python service that calls a payment provider.

Operations: GET payment status; POST to create a charge.

Provider behavior: charge creation does not support idempotency keys.
If a request times out, we may not know whether the charge succeeded.

Constraints: duplicate charges are unacceptable.
Interactive requests have a two-second latency budget.

Unknown: we do not yet know whether the provider can look up a charge
by our transaction reference.

Deliverable: recommend behavior separately for status reads and charge
creation. Identify missing information. Do not assume a timeout means
the operation failed.
```

Now the model has a different problem:

- Reads and writes are different jobs.
- A timeout is an **unknown outcome**, not a failed outcome.
- Automatically retrying the charge can duplicate it.
- Reconciliation might be possible, but only if a lookup-by-reference exists — and you said you do not know that yet.
- Even a *safe* retry has to fit in two seconds. Five attempts with exponential backoff will not.

The decisive improvement was not “please think step by step.” It was a fact about the system.

## Code that compiles, looks careful, and still double-charges

This is the shape of answer you get from the short prompt. It is the kind of snippet that survives a glance in review because it uses a real library and names the right folklore.

```python
# Typical generated "production retry." Python 3.11+
# Looks careful. Unsafe on a non-idempotent POST.
# pip install tenacity requests

import requests
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_random_exponential,
)

@retry(
    stop=stop_after_attempt(5),
    wait=wait_random_exponential(multiplier=0.2, max=2),
    retry=retry_if_exception_type((requests.Timeout, requests.ConnectionError)),
    reraise=True,
)
def create_charge(session: requests.Session, payload: dict) -> dict:
    response = session.post(
        "https://provider.example/v1/charges",
        json=payload,
        timeout=2,
    )
    response.raise_for_status()
    return response.json()
```

Walk through a timeout. The client sent `POST /charges`. The provider created the charge, then the TCP connection dropped before the body came back. `requests` raises `Timeout`. Tenacity tries again. The provider sees a *new* `POST` and creates a *new* charge.

The decorator did what you asked. The contract you needed was “at most one charge.” Nobody wrote that contract down, so nothing in the code enforces it.

> **Gotcha:** A timeout after a non-idempotent `POST` is not “please try the same operation again.” It is “the outcome is unknown.” Retrying the `POST` is how you turn an unknown into a duplicate. This compiles. The happy path (provider answers on the first try) passes. The failure is the timeout path, which is exactly when retries run.

Here is a small, runnable cousin of that bug. No network. The fake provider can commit a charge and *then* time out, which is the case people keep forgetting.

```python
# payment_retry_sim.py
# Python 3.11+
# python payment_retry_sim.py

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum, auto
import uuid

class Outcome(Enum):
    SUCCESS = auto()
    TIMEOUT_AFTER_COMMIT = auto()   # charged, client saw nothing
    TIMEOUT_BEFORE_COMMIT = auto()  # not charged
    TRANSIENT = auto()              # not charged, retry may be safe

@dataclass
class Charge:
    charge_id: str
    amount_cents: int
    our_ref: str

@dataclass
class FakeProvider:
    """Charge creation has no idempotency keys."""
    charges: list[Charge] = field(default_factory=list)
    script: list[Outcome] = field(default_factory=list)
    step: int = 0

    def _next(self) -> Outcome:
        if self.step >= len(self.script):
            return Outcome.SUCCESS
        outcome = self.script[self.step]
        self.step += 1
        return outcome

    def create_charge(self, amount_cents: int, our_ref: str) -> str:
        outcome = self._next()
        if outcome is Outcome.TIMEOUT_BEFORE_COMMIT:
            raise TimeoutError("no response; charge was not created")
        if outcome is Outcome.TRANSIENT:
            raise ConnectionError("connection reset; charge was not created")

        rec = Charge(str(uuid.uuid4()), amount_cents, our_ref)
        self.charges.append(rec)
        if outcome is Outcome.TIMEOUT_AFTER_COMMIT:
            raise TimeoutError("no response; charge may exist")
        return rec.charge_id

    def get_status(self, charge_id: str) -> str:
        for c in self.charges:
            if c.charge_id == charge_id:
                return "succeeded"
        raise KeyError(charge_id)

def naive_retry_create(provider: FakeProvider, amount: int, ref: str,
                       attempts: int = 3) -> str:
    last: Exception | None = None
    for _ in range(attempts):
        try:
            return provider.create_charge(amount, ref)
        except (TimeoutError, ConnectionError) as exc:
            last = exc
    assert last is not None
    raise last

def main() -> None:
    provider = FakeProvider(script=[
        Outcome.TIMEOUT_AFTER_COMMIT,
        Outcome.SUCCESS,
    ])
    try:
        naive_retry_create(provider, amount=1999, ref="order-42")
    except TimeoutError:
        pass
    print(f"charges created: {len(provider.charges)}")
    for c in provider.charges:
        print(f"  {c.charge_id} ref={c.our_ref}")

if __name__ == "__main__":
    main()
```

You should see two charges for `order-42`. The first attempt committed and then timed out. The retry “recovered” by billing the customer again.

That is not a tenacity bug. It is a missing fact: **charge creation is not safe to retry.**

A policy that respects the brief looks less like a decorator and more like two different state machines. Status reads may retry inside the two-second budget. Charge creation does not retry on unknown outcomes. It records `unknown` and, if the provider later turns out to support lookup-by-reference, reconciles. If it does not, a human or a slower out-of-band job has to.

```python
# Same file, or a second module. Python 3.11+.

from dataclasses import dataclass
from enum import Enum, auto
import time

class ChargeAttempt(Enum):
    SUCCEEDED = auto()
    FAILED = auto()      # we know it did not commit
    UNKNOWN = auto()     # timeout or cutoff after the request was sent

@dataclass
class AttemptResult:
    status: ChargeAttempt
    charge_id: str | None
    detail: str

def get_status_with_retry(
    provider: FakeProvider,
    charge_id: str,
    budget_s: float = 2.0,
) -> str:
    """GET-equivalent: safe to retry while the latency budget remains."""
    deadline = time.monotonic() + budget_s
    delay = 0.05
    last: Exception | None = None
    while time.monotonic() < deadline:
        try:
            return provider.get_status(charge_id)
        except KeyError:
            raise
        except (TimeoutError, ConnectionError) as exc:
            last = exc
            remaining = deadline - time.monotonic()
            if remaining <= delay:
                break
            time.sleep(delay)
            delay = min(delay * 2, remaining)
    raise TimeoutError(f"status read exhausted budget: {last}")

def create_charge_once(
    provider: FakeProvider,
    amount_cents: int,
    our_ref: str,
) -> AttemptResult:
    """POST-equivalent: do not retry unknown outcomes."""
    try:
        charge_id = provider.create_charge(amount_cents, our_ref)
        return AttemptResult(ChargeAttempt.SUCCEEDED, charge_id, "created")
    except ConnectionError as exc:
        # Scripted as "reset before commit." In a real client this is
        # only FAILED if you *know* the request never left your process.
        return AttemptResult(ChargeAttempt.FAILED, None, str(exc))
    except TimeoutError as exc:
        return AttemptResult(ChargeAttempt.UNKNOWN, None, str(exc))

def demo_safe_path() -> None:
    provider = FakeProvider(script=[Outcome.TIMEOUT_AFTER_COMMIT])
    result = create_charge_once(provider, 1999, "order-42")
    print(result.status.name, "charges=", len(provider.charges))
    # UNKNOWN and one charge on the provider. We do not POST again.
    # Next step depends on a capability we explicitly do not have yet:
    # lookup by our_ref. Do not invent that API.

if __name__ == "__main__":
    demo_safe_path()
```

Notice what the second version refuses to do. It does not pretend `ConnectionError` is always safe in the real world — I labeled that. A reset *after* the bytes left the machine is also unknown. The simulation makes the distinction only so you can see the timeout-after-commit case in isolation. In production I treat “request was written to the socket, no response” as unknown unless the protocol gives me a stronger guarantee.

The model will not volunteer that distinction unless the context makes “unknown” a first-class outcome. Folklore only has success and failure. Payments need three.

> **Pro tip:** When you ask for a retry policy, force the model to classify each call as *safe to retry*, *never retry*, or *retry only with an idempotency key / replay protection*. If it cannot fill that table from what you gave it, the answer is not ready. The missing row is the work.

## The same failure, in C++, with a different costume

Retries are not the only place this shows up. “Optimize this” is just as empty, and it shows up in game code and in money code with opposite correct answers.

Take a tiny uniqueness count. C++20. This is the whole function someone pastes.

```cpp
// C++20
// g++ -std=c++20 -O2 -Wall -Wextra unique_count.cpp
#include <algorithm>
#include <cstdint>
#include <iostream>
#include <vector>

std::int64_t count_unique(std::vector<std::int64_t> ids) {
    std::sort(ids.begin(), ids.end());
    auto last = std::unique(ids.begin(), ids.end());
    return static_cast<std::int64_t>(last - ids.begin());
}

int main() {
    std::vector<std::int64_t> ids{9, 1, 9, 3, 1};
    std::cout << count_unique(ids) << "\n";  // 3
}
```

Bad prompt:

```text
You are a world-class C++ performance engineer.
Optimize this function. Production-ready. Be thorough.
```

A very common completion is to reach for a hash table, because textbooks say average `O(1)` insert.

```cpp
// C++20 — typical "optimized" rewrite. Compiles. Not automatically better.
#include <cstdint>
#include <unordered_set>
#include <vector>

std::int64_t count_unique(const std::vector<std::int64_t>& ids) {
    std::unordered_set<std::int64_t> seen(ids.begin(), ids.end());
    return static_cast<std::int64_t>(seen.size());
}
```

That is a plausible answer to *some* problem. Which problem?

**Game HUD, eight entity IDs, once a frame.** The sort of eight integers is noise. The hitch is almost certainly draw submission, cache misses in the scene, or a sync with the GPU. Allocating an `unordered_set` every frame is a good way to make the “optimization” visible in the allocator, not the profiler. The right answer is often “do not touch this; measure the frame.”

**Overnight reconciliation, 50 million trade IDs, must be exact.** Sorting can be the right call: deterministic, predictable memory, friendly to the prefetcher. A hash set can also win. I will not pretend to know which one wins on your box. Representative results from a typical x86-64 machine are worthless next to a measurement of *this* workload. What the context *does* tell you is that cleverness has to preserve exactness, and that allocator traffic and worst-case hash behavior are in scope.

**IDs come from the outside world.** Then `std::unordered_set` with the default hash is not just a performance choice. It is a robustness choice. Adversarial or accidentally-pathological 64-bit keys can turn “average `O(1)`” into a long, sad chain of collisions. A sort does not have that failure mode.

Same twelve lines of C++. Three different jobs. The model cannot infer your frame budget, your risk tolerance, or whether these integers are entity IDs or ledger keys merely because that is obvious to you.

I will not dump a matching engine in an article about prompts. I will say this: in a trading firm, “make it faster” without “never change rounding, never reorder fills, never retry a non-idempotent IO” is how you get a faster wrong system. In a game studio, the same prompt without “this is cosmetic, 1 ULP is fine, do not touch the save format” is how you get a physics rewrite nobody asked for.

> **Pro tip:** Before “optimize,” write down three numbers a colleague would ask for: how often it runs, how large `n` is, and what happens if the answer is slightly wrong. If you cannot fill those in, you are not ready to accept the model’s rewrite.

## Bad prompts, good prompts

**Bad:**

```text
You are a senior staff engineer. Write a production-ready retry policy
for our HTTP client. Be thorough. Think step by step.
```

This is costume jewelry. “Senior,” “production-ready,” and “thorough” push the model toward a longer, more confident average answer. They do not tell it whether a timeout is a failure.

**Also bad, in a different direction:**

```text
Optimize this C++ function. Use modern C++. Prefer unordered_set.
Do not ask questions.
```

You just forbade the only useful behavior the model has when context is missing, which is to list assumptions.

**Good enough to paste:**

```text
Task: recommend a retry policy, not implement one yet.

Codebase: Python 3.11 service, httpx, one payment provider.

Calls:
- GET /status/{id}  — read payment status
- POST /charges     — create a charge

Facts:
- POST /charges does not accept idempotency keys.
- A timeout can mean the charge was created, or not. We cannot tell
  from the exception alone.
- Duplicate charges are unacceptable.
- Interactive path: 2.0s end-to-end budget.

Unknowns (do not invent APIs for these):
- Can we look up a charge by our transaction reference?
- Does the provider offer a reconciliation endpoint?

Output:
1. A table: operation × retry? × on which errors × max time spent.
2. Explicit UNKNOWN outcome handling for POST.
3. A list of assumptions. If an assumption would change the table,
   stop and ask; do not pick silently.
4. No code until I accept the table.
```

The last line is load-bearing. If you let the model skip to code, you will spend the rest of the hour arguing with a decorator.

For homework and exams the same structure applies, with one extra rule. Using a model to understand the *problem* is how professionals work. Submitting output you cannot explain is cheating, and it leaves you unable to pass the exam. Attempt first. Ask the model to explain the problem, not to finish it. Write the code yourself. Then have the model grill *your* code. If you cannot defend a retry on `POST`, you should not ship it, and you should not turn it in.

## A four-condition check, not a longer prompt

Do not only compare “short prompt” to “long prompt.” Length is not the thing you are testing. Compare four conditions, same model, same output requirements, several runs each. Score **task correctness**, not polish.

| Condition | What you are testing |
|---|---|
| Minimal request | Baseline folklore (“backoff and jitter”) |
| Request plus relevant context | Whether the facts change the substance |
| Request plus similar-length *irrelevant* detail | Whether you just needed more tokens |
| Relevant context with one decisive fact removed | What actually drove the improvement |

For the payment example, the decisive fact to remove is “charge creation does not support idempotency keys,” or “a timeout does not mean the charge failed.” If the recommendation does not change when that sentence disappears, the model was not using it.

Score each run with a boring checklist. Yes/no. No style points.

| Criterion | Pass? |
|---|---|
| Treats GET status and POST charge as different policies | |
| Treats timeout on POST as unknown, not failed | |
| Refuses automatic retry of charge creation without replay protection | |
| Fits any retry of the *read* path inside the 2s budget | |
| Names the unknown lookup-by-reference instead of inventing it | |

A longer, more confident answer that retries `POST` with jitter still fails. That is the whole point.

I am not going to invent a bake-off table and pretend I ran your model yesterday. Run it. Two or three times per condition is enough to see the pattern. If the relevant-context column is the only one that consistently passes, you have your thesis on the page in front of you. If the irrelevant-detail column also passes, you got lucky, or the model already feared double charges — and you should still not rely on that fear, because it is not a contract.

The fact-removal condition is the one people skip. Do not skip it. It is the closest you will get to a controlled experiment in a chat window.

## More context is not better context

This is where the folklore of “just paste the repo” dies.

The Transformer paper that started this whole architecture is [Vaswani et al., *Attention Is All You Need*](https://arxiv.org/abs/1706.03762). Attention is a way to route information inside a sequence. It is not a promise that every token you dump in the window will be used well.

Liu et al., in [*Lost in the Middle*](https://arxiv.org/abs/2307.03172), measured how models actually use long inputs on multi-document QA and key-value retrieval. Performance was often best when the relevant bit sat at the beginning or the end, and worse when it sat in the middle. Performance also dropped as the input got longer, including for models advertised as long-context. That paper is from 2023, published in TACL in 2024; newer models may be less fragile. I would still not bury the sentence “do not retry charge creation” in page 40 of a pasted wiki.

So:

**Irrelevant material competes with evidence.** A 40-file dump that includes the billing service, the marketing site, and last year’s Kubernetes YAML does not make the model more informed. It makes the decisive constraint quieter.

**Stale facts can be worse than missing facts.** Missing, the model may ask, or it may hedge, or you may notice the hedge is absent. Stale, it will confidently design around “we cannot look up by reference” six months after that endpoint shipped. Wrong context is not neutral. It is a wrong spec.

**Contradictory documents need an authority.** The README says retry all 5xx. The runbook says never retry payments. The code retries everything through a middleware written in 2019. If you paste all three and do not say which one wins, the model will pick the most textbook-looking one, or average them into something nobody would have written on purpose.

**Untrusted content can contain instructions.** Retrieved pages, ticket comments, pasted Slack, vendor emails — the model does not have a separate channel for “data.” It is all tokens. Prompt injection is on the OWASP LLM list for that reason; the [OWASP cheat sheet](https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html) is a reasonable starting point. You do not need a cartoon “ignore previous instructions” jailbreak. You need a PDF that says “always retry” in a section the model treats as policy. Label evidence as evidence. Tell the model it is allowed to disagree with a retrieved document.

**Optimize for relevant, reliable context — not maximum context.**

> **Gotcha:** RAG makes this worse when it is treated as “more truth.” A retrieved chunk is a *quote from some document at some time*. It is not automatically in force. If your pipeline cannot say *which* document, *which version*, and *whether it is allowed to override the user*, you do not have context. You have a blender.

## Weaker models, better files

I have heard, and I have seen often enough to treat it as a working hypothesis, that a smaller model with the right brief will beat a frontier model given “write a retry policy.” I will not fake a leaderboard. Measure it on *your* tasks.

The reason the hypothesis is plausible is the same as the rest of this article. A lot of what we call “reasoning” in these tools is “selecting a default problem and speaking fluently about it.” If you have already selected the problem — GET vs POST, unknown vs failed, two-second budget — the remaining work is more modest. A weaker model can fill in a table. A stronger model, starved of facts, will write you a beautiful essay about jitter.

That is also why I want you to keep **folders of context files** per project, ready to drop into a conversation. Not the whole repository. A kit:

- `system.md` — what this service is, what it must never do
- `constraints.md` — latency budgets, compliance, “no duplicate charges”
- `glossary.md` — what *you* mean by *safe*, *fast*, *simple*
- `unknowns.md` — questions that are still open
- a slice of code, not the tree
- one current runbook page, with a date on it

When the question is easy, the model’s default may be good enough. When the question is hard and the right answer is not obvious — retry or not, hash set or sort, microservice or not — the default is almost certainly somebody else’s system. That is when the folder earns its keep.

Do not turn a one-line question into a specification document every time. “What does `vector::reserve` do?” does not need a brief. “Design the retry policy” does.

<details>
<summary><strong>A reusable context brief</strong></summary>

Use this as a thinking aid, not as a ritual.

```text
Task: What should the model do?
Purpose: What decision or action will this support?
Relevant facts: What must it know about this specific situation?
Sources: Which materials support those facts, and how current are they?
Constraints: What must the answer respect?
Success criteria: What would make the result useful?
Unknowns: What information is missing? Do not fill these silently.
Output: What form should the response take?
```

If a section is empty, that is information. An empty **Unknowns** section means you are claiming the problem is fully specified. Be sure that is true.

</details>

## Treat the model as a noisy, context-starved advisor

Models are optimized to sound helpful. Helpful and consistent are not the same objective. Helpful and correct are not either.

If you ask twice and get two architectures, you probably did not specify the decision criteria. Ask a third time with “list the assumptions you needed to pick one.” The assumptions are the context you should have provided on the first try.

If you ask two models and they agree on backoff-and-jitter for a payment `POST`, they are not “independent experts confirming the design.” They are two averages of the same internet. Agreement is cheap when the folklore is strong. You still need the idempotency fact.

AI makes a good programmer faster only if they understand what it is doing. The decorator above is the test. If you cannot explain why it is wrong on timeout-after-commit, you are not being accelerated. You are being given a very fluent way to ship a duplicate charge.

I spend a fair amount of [tutoring](https://fastcodeguru.org/tutoring) time on exactly that review: not prettier prompts, but “what was the model never told, and what did it invent so it could keep talking?”

## Do this week

1. Pick one request you already made this month that came back fluent and useless. Write the brief you *should* have given. Do not send it yet.
2. Identify the single fact that would have changed the answer. If you cannot find one, the request was a topic, not a task.
3. Run the four-condition check on that fact. Score the checklist, not the prose.
4. Start a project folder with `constraints.md` and `unknowns.md`. Put dates in the files. Drop those two files in before you paste code.
5. On the next retry / optimize / “should we” question, forbid code until the model produces a table of options and a list of assumptions.
6. If you are a student: use the model to interrogate *your* solution. If you cannot explain the timeout case, you are not done, regardless of what compiled.

Before you ask “how can I phrase this better?”, ask “what would a competent colleague need to know to answer this well?”

Context is necessary. It is not sufficient. You still have to read the answer, run the timeout path, and refuse to ship a decorator that cannot tell *unknown* from *failed*. The title of the Transformer paper was a real claim about architecture. This title is a useful exaggeration about work. Almost is doing a lot of lifting. Keep it.
