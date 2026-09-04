+++
draft       = false
featured    = true
title       = "Throw Out the Box Model Before You Write Another Line of Python"
slug        = "python-primer"
description = "Four lines of Python that look like they print [1, 2, 3] actually print [1, 2, 3, 4] — and if that surprises you, the rest of the language will keep lying to you until you throw out the box model."
ogImage     = "./python-primer.jpg"
pubDatetime = 2026-07-20T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "Python 3",
    "Name Binding",
    "Object Identity",
    "Mutability",
    "Duck Typing",
    "Python Data Model",
    "Assignment Semantics",
    "Mutable Default Arguments",
    "Iteration Protocol",
    "Generator Functions",
    "Shallow Copy",
    "Dynamic Typing",
    "Special Methods",
    "Indentation Syntax",
    "Argument Passing",
    "Programming Fundamentals",
    "CS 1",
    "Software Correctness",
    "Python Primer",
    "Tutorial"
]
+++

![Throw Out the Box Model Before You Write Another Line of Python](./python-primer.jpg "Throw Out the Box Model Before You Write Another Line of Python")

## Table of Contents

---

# Throw Out the Box Model Before You Write Another Line of Python

Here is a four-line program. If you have written C, Java, JavaScript, or the kind of “variables are boxes” intro that most people get in school, you already know what it prints.

```python
# Python 3
a = [1, 2, 3]
b = a
b.append(4)
print(a)
```

You predict `[1, 2, 3]`. Python prints `[1, 2, 3, 4]`.

The program is not buggy. Your model is.

Python looks like executable pseudocode. Friendly. Almost English. That is the trap. Under the syntax is a small, strict machine: **names**, **objects**, and a handful of protocols. Learn that machine and the rest of the language is a library. Keep treating Python as C with indentation — or Java with the semicolons sanded off — and you will spend a semester debugging ghosts.

This is a first-principles primer. Dialect: **Python 3**, the CPython you actually install. The examples use only features that have been stable for years; they run on 3.11, 3.12, and current 3.14. I am not going to tour every keyword. I am going to show you the parts of Python that are not like most other languages, because those are the parts that make people feel stupid when they are not.

## The picture you should stop drawing

I learned C++ in 1987 at Bell Labs. That language trains you to see a variable as a typed box. `int x;` is a box that can hold an integer. `x = 7;` copies bits into the box. `int y = x;` copies them again into a second box. Two boxes. Two values. Change one, the other does not flinch.

Python will not pretend to be that language for you.

In Python, **objects** live on the heap. Every piece of data is an object: the integer `7`, the string `"hi"`, the list `[1, 2, 3]`, a function, a class, even `None`. Each object has three things, and the [data model](https://docs.python.org/3/reference/datamodel.html) is not being poetic about this:

- an **identity** (you can think of it as the object’s address; `id(x)` returns it)
- a **type** (what it *is*, which decides what you can do with it)
- a **value** (the contents)

A **name** is not a box. A name is a label stuck on an object. Assignment does not copy. Assignment binds a name to an object.

```python
# Python 3
a = [1, 2, 3]
b = a
print(id(a) == id(b))  # True: one list, two names
print(a is b)          # same test, the way you should write it
```

`b = a` did not make a second list. It made a second name for the only list that exists. `b.append(4)` mutates that object. `a` sees it because `a` *is* it.

> **Pro tip:** When you are confused about whether two names share an object, do not argue with the language. Print `id(a)`, `id(b)`, and `a is b`. Same identity means one object. This is the Python version of looking at the memory, and it takes one line.

Rebinding is not mutating. This pair of programs looks similar in English and is nothing alike in Python:

```python
# Python 3 — mutate: the list object changes in place
nums = [1, 2, 3]
also = nums
also.append(4)
print(nums)   # [1, 2, 3, 4]

# Python 3 — rebind: nums now labels a *new* list
nums = [1, 2, 3]
also = nums
nums = nums + [4]
print(also)   # [1, 2, 3]  — still the old object
print(nums)   # [1, 2, 3, 4]
```

`also.append(4)` asks the list object to change itself. `nums = nums + [4]` builds a new list and moves the name `nums` onto it. `also` still points at the original.

People sometimes say “Python has no variables.” That slogan is cute and wrong. Python has variables. They are the names. They just do not work like C boxes. Ned Batchelder’s [Facts and myths about Python names and values](https://nedbatchelder.com/text/names) is the cleanest write-up of this I know. Read it after you finish here. Then come back and throw away every diagram with a rectangle labeled `int x`.

Draw dots and arrows instead. Object in the middle. Names as arrows pointing at it. Assignment moves an arrow. A method like `.append()` walks down the arrow and changes the object.

That picture is the language.

## Why lists bite and integers do not

“But `x = 1; y = x; x = x + 1` does not change `y`.” Correct. That does not mean assignment works differently for numbers. Assignment *never* copies, for any type. The difference is **mutability**.

An object is **mutable** if its value can change without changing its identity. Lists, dictionaries, and sets are mutable. Integers, floats, strings, and tuples are **immutable**: you cannot change the object, you can only bind a name to a different object.

```python
# Python 3
x = 1
y = x
x = x + 1     # does not poke a hole in the 1; it binds x to a new int, 2
print(y)      # 1
print(x is y) # False
```

There is no `1.append(1)`. Integers have no in-place operations, so the “two names, one object” situation cannot surprise you. Lists can. That is why every CS 1 Python course has a week where half the room thinks lists are haunted.

The official FAQ has a page on this exact surprise: [Why did changing list ‘y’ also change list ‘x’?](https://docs.python.org/3/faq/programming.html). If you only read one Python FAQ entry this year, read that one.

> **Gotcha:** `+=` is not one thing. For lists, `xs += [4]` mutates `xs` in place (it is `xs.extend([4])`). For integers and tuples, `+=` rebinds the name to a new object. Same spelling, two machines. If you write `xs += something` and another name points at the same list, that other name sees the change.

If you actually want a second list, ask for one:

```python
# Python 3
a = [1, 2, 3]
b = list(a)    # or a.copy(), or a[:]
print(a is b)  # False
b.append(4)
print(a)       # [1, 2, 3]
```

Slicing `a[:]` is a shallow copy. The *list* is new. The *objects inside it* are not. If those objects are themselves lists, you still have sharing one level down. Beginners hit this the first time they copy a “grid” of rows.

```python
# Python 3 — looks like a copy of a 2×2 grid. It is not.
grid = [[0, 0], [0, 0]]
copy = grid[:]         # new outer list, same inner lists
copy[0][0] = 9
print(grid)            # [[9, 0], [0, 0]]
```

Contract: “copy the structure.” Failing input: nested lists. Fix: copy each row, or use `copy.deepcopy` when you mean it. Do not reach for `deepcopy` as a reflex. Most of the time you wanted `list(a)` and a clearer design.

## Indentation is not style. It is the grammar.

Most languages you will meet use braces or keywords to mark a block, and treat whitespace as a courtesy. Python stole the courtesy and made it load-bearing.

```python
# Python 3
def abs_value(x):
    if x < 0:
        return -x
    return x
```

The colon opens a suite. The indent *is* the suite. Dedent closes it. There is no `end`, no `}`. Mix tabs and spaces and you get `TabError`. Indent one line of a block differently than its siblings and you get `IndentationError`, or worse, a program that runs and does the wrong thing because a line silently left the block.

This is the usual CS 1 pattern: a student pastes from a website, one line is indented with a tab, the rest with spaces, and the file looks fine in the editor. CPython is not looking at how it looks. It is looking at the bytes.

PEP 8 — the style guide people actually follow — says four spaces, no tabs. Follow it. Do not have an opinion about this yet. You are not going to win.

Two consequences that are not obvious:

Python has no dangling-`else` problem. The `else` belongs to the `if` at the same indent. The grammar does not allow the ambiguity that C still lectures about.

And you cannot comment out a brace to “temporarily” change control flow. You re-indent. That sounds petty until you are debugging at 1 a.m. and the `return` you thought was inside the loop is not.

> **Pro tip:** If the editor you are using does not show whitespace and does not insert four spaces when you press Tab, change the editor settings before you write another function. This is not a taste issue. It is a class of bugs you can delete from your life in thirty seconds.

## Types live on objects. Names do not.

Python is **dynamically typed**: a name can refer to an integer on one line and a string on the next. The name has no type. The object does.

Python is also **strongly typed**: it will not silently add an integer to a string because that would be convenient.

```python
# Python 3
x = 3
x = "three"     # legal. Confusing, if you keep doing it. Legal.
print(1 + 2)    # 3
print("a" + "b")# ab
print(1 + "2")  # TypeError: unsupported operand type(s) for +: 'int' and 'str'
```

People mix up “dynamic” with “weak.” JavaScript is happy to give you `"12"` or `3` depending on the day. Python raises. That is a feature. When I am tutoring someone who just came from a language that coerces everything, I have to talk them out of being offended by `TypeError`. The interpreter is telling you the objects do not support that operation. Believe it.

You can ask an object its type with `type(x)`. You rarely should, not in the way beginners want to. Python’s real type system in day-to-day code is **duck typing**: if the object supports the operations you are about to perform, it is the right type. A function that loops over its argument does not need a list. It needs an iterable. A string is an iterable of characters. A tuple is an iterable. A file object is an iterable of lines. A class you write this weekend can be an iterable if it says so.

That is not sloppiness. It is the data model, which we will use for real in the second example. First, a program that looks right and is wrong.

## A gradebook that compiles, runs, and still fails

Contract we want:

- A roster is a dictionary mapping a student name to *that student’s* list of scores.
- `add_student` adds a name with an empty score list, or with a list we pass in.
- `record` appends one score for one student.
- `average` returns the mean, or `0.0` if there are no scores.

Here is the version I see constantly. It type-checks in your head. It runs. The first call looks perfect.

```python
# Python 3
# Run: python gradebook_buggy.py

def add_student(roster, name, scores=[]):
    roster[name] = scores

def record(roster, name, score):
    roster[name].append(score)

def average(scores):
    return sum(scores) / len(scores)

def main():
    roster = {}
    add_student(roster, "Ada")
    add_student(roster, "Alan")
    record(roster, "Ada", 100)
    print("Ada ", roster["Ada"], " avg", average(roster["Ada"]))
    print("Alan", roster["Alan"], " avg", average(roster["Alan"]))

if __name__ == "__main__":
    main()
```

Failing input: two students, no explicit starting lists, then one score for Ada.

What you wanted:

```
Ada  [100]  avg 100.0
Alan []     avg ...
```

What you get:

```
Ada  [100]  avg 100.0
Alan [100]  avg 100.0
```

Alan did not take the test. He shares Ada’s list.

The default value `[]` is **not** evaluated each call. Functions are objects. Default arguments are evaluated once, when the `def` statement runs, and stored on that function object. Every call that omits `scores` reuses the *same* list.

You can see the corpse:

```python
# Python 3
def add_student(roster, name, scores=[]):
    roster[name] = scores

print(add_student.__defaults__)
add_student({}, "Ada")
add_student({}, "Alan")[ "Alan"].append(100)  # don't write this; just watch
print(add_student.__defaults__)  # ([100],) — the default list grew
```

That is unique to Python among the languages most novices have seen. A `def` is not a stencil that stamps out fresh locals for defaults. A `def` *creates a function object* and hangs the defaults on it.

The [tutorial section on default argument values](https://docs.python.org/3/tutorial/controlflow.html) has the warning. People skip it because the rest of the page looks like syntax.

Fix: default to `None`, which is immutable, and make a new list inside the call.

```python
# Python 3
# Run: python gradebook.py

def add_student(roster, name, scores=None):
    if scores is None:
        scores = []
    roster[name] = scores

def record(roster, name, score):
    roster[name].append(score)

def average(scores):
    if not scores:
        return 0.0
    return sum(scores) / len(scores)

def class_average(roster):
    if not roster:
        return 0.0
    return sum(average(s) for s in roster.values()) / len(roster)

def main():
    roster = {}
    add_student(roster, "Ada")
    add_student(roster, "Alan")
    record(roster, "Ada", 100)
    record(roster, "Ada", 90)
    record(roster, "Alan", 80)
    for name, scores in roster.items():
        print(f"{name:4s} {scores}  avg {average(scores):5.1f}")
    print(f"class avg {class_average(roster):5.1f}")

    # Passing our own list is still allowed — and it *is* shared,
    # because we asked for that.
    shared = [70]
    add_student(roster, "Grace", shared)
    add_student(roster, "Jean", shared)
    record(roster, "Grace", 75)
    print("Grace", roster["Grace"])
    print("Jean ", roster["Jean"])  # [70, 75] — same object, on purpose

if __name__ == "__main__":
    main()
```

Two different situations, same machine. Ada and Alan must not share a list, so we construct a new one per call. Grace and Jean *do* share, because the caller passed one object in. Python did not copy it at the function boundary. **Argument passing is assignment.** The parameter name is bound to the object you passed. No copy. Ever.

> **Gotcha:** `if scores is None` is the test you want for “caller omitted the list.” `if not scores` is a different test: it is true for `None` *and* for `[]`. Empty list is a valid value you might have passed on purpose. `None` is the sentinel. Use `is` with `None`, always. `None` is a singleton; identity is the contract.

I also changed `average` so the empty list does not blow up with `ZeroDivisionError`. That is a separate bug the original hid behind the first one. When a function looks right on the happy path, run the empty case. Always.

## `for` is not the `for` you know

C’s `for (i = 0; i < n; i++)` is a counting loop with extra steps. Java’s enhanced-for is closer. Python’s `for` is not a count. It is “walk this iterable until it is exhausted.”

```python
# Python 3
for ch in "Ada":
    print(ch)

for score in [100, 90, 80]:
    print(score)

for name, scores in roster.items():  # unpacking: each item is a (key, value) pair
    print(name, scores)
```

`range(5)` is not a special case the compiler understands. `range(5)` is an object that produces `0, 1, 2, 3, 4` when you iterate it. That is why `for i in range(len(xs)):` works, and also why it is usually the wrong thing to write. You wanted the items. Ask for the items. If you also need the index, ask for both:

```python
# Python 3
xs = ["Ada", "Alan", "Grace"]
for i, name in enumerate(xs):
    print(i, name)
```

Under the hood, `for x in xs:` does this:

1. `it = iter(xs)` — ask `xs` for an iterator
2. repeatedly `x = next(it)` until `StopIteration` is raised
3. that exception is how iteration *ends*. It is not an error in the “your program is wrong” sense. The `for` statement catches it.

You almost never write that loop by hand. You should know it exists, because it is why one `for` works on lists, strings, files, dictionaries, and objects you have not written yet.

Chained comparisons are the other control-flow gift people from C cannot believe.

```python
# Python 3
x = 5
print(0 <= x < 10)   # True. Means what the math means.
```

In C, `0 <= x < 10` is `(0 <= x) < 10`. The first comparison yields 0 or 1, then that is compared to 10, which is always true. I have watched working engineers ship that bug. Python’s version is `(0 <= x) and (x < 10)`, with `x` evaluated once. Write the math. It is not cute syntax. It is correct syntax.

## Duck typing, in a program you can run

Here is the second example. Contract: we have lines of text from a class roster file. Each real line is `Name,score`. Blank lines and comments starting with `#` are junk. We want per-student totals and a class ranking. The parsing function should not care whether the lines came from a list, a file, or some object we invented.

```python
# Python 3
# Run: python roster.py

from collections import defaultdict


def parse_scores(lines):
    """Yield (name, score) from any iterable of text lines.

    Skips blanks and #-comments. Raises ValueError on a malformed line
    so the caller sees *which* line broke.
    """
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(",")
        if len(parts) != 2:
            raise ValueError(f"expected 'Name,score', got {raw!r}")
        name, score_text = parts
        name = name.strip()
        try:
            score = int(score_text.strip())
        except ValueError as exc:
            raise ValueError(f"bad score in {raw!r}") from exc
        yield name, score


def totals(pairs):
    """pairs: iterable of (name, score). Returns dict name -> list of scores."""
    roster = defaultdict(list)
    for name, score in pairs:
        roster[name].append(score)
    return dict(roster)


def ranking(roster):
    """Highest average first. Ties broken by name, so the order is stable to test."""
    def key(item):
        name, scores = item
        avg = sum(scores) / len(scores)
        return (-avg, name)

    return sorted(roster.items(), key=key)


class SkipComments:
    """A tiny iterable. for-loops accept it because it defines __iter__."""

    def __init__(self, lines):
        self._lines = lines

    def __iter__(self):
        for line in self._lines:
            if line.strip() and not line.lstrip().startswith("#"):
                yield line


def main():
    text = [
        "# CS 1 section A",
        "Ada,100",
        "Alan,80",
        "",
        "Ada,90",
        "Grace,95",
        "Alan,70",
    ]

    roster = totals(parse_scores(text))
    for name, scores in ranking(roster):
        avg = sum(scores) / len(scores)
        print(f"{name:6s} {scores}  avg {avg:5.1f}")

    # Same function, different iterable — a file-like object we invented.
    roster2 = totals(parse_scores(SkipComments(text)))
    assert roster2 == roster

if __name__ == "__main__":
    main()
```

`parse_scores` does not mention `list`. It mentions `for` and `yield`. Anything you can iterate can feed it. `SkipComments` is not a subclass of anything interesting. It implements `__iter__`. That is enough. A `for` loop, `list()`, tuple unpacking, and `totals()` all take it.

This is the part of Python that is not like Java’s `interface` or C++’s abstract base class, even when those are the right tools in those languages. You do not register `SkipComments` with anyone. You grow the method the protocol asks for. The data model’s special methods — the ones spelled with double underscores, “dunders” — are how you plug a type you wrote into syntax the language already has:

| You implement | Python lets you write |
|---|---|
| `__iter__` / `__next__` | `for x in obj` |
| `__len__` | `len(obj)` |
| `__getitem__` | `obj[i]` |
| `__eq__` | `obj == other` |
| `__str__` | `print(obj)` |
| `__add__` | `obj + other` |
| `__bool__` | `if obj:` |

You do not need all of those this week. You need to know they exist, so that `len` and `for` and `+` stop looking like magic and start looking like function calls with prettier spelling.

> **Pro tip:** `yield` inside a function makes a generator. Calling `parse_scores(text)` does not return a list of pairs. It returns a generator object that produces pairs as you iterate. If you iterate it twice, the second time is empty. If you need to walk the results more than once, call `list(parse_scores(text))` once and keep the list. This bites every intern on week two.

## How Python differs where it actually matters

A comparison you can use when your brain grabs the wrong language. “Typical C/Java” is a smear — Java objects are references too — but it is the smear most classrooms teach.

| Question | C / the box lecture / Java primitives | Python 3 |
|---|---|---|
| What is a variable? | A typed box that holds a value | A name bound to an object |
| What does `x = y` do? | Copy bits into `x` | Bind the name `x` to the object `y` names. Never copies. |
| Where do types live? | On the variable | On the object |
| How do you delimit a block? | `{ }` or keywords | Indentation |
| What is `for`? | A counting loop, plus later for-each | Iteration over any iterable |
| What is `null`? | A pointer/reference that points nowhere | `None`, a real object of type `NoneType` |
| What happens on `1 + "2"`? | C: chaos or a compile error; JS: `"12"` | `TypeError` |
| How big is an `int`? | 32 or 64 bits, then wrap or overflow | Arbitrary precision. `2 ** 1000` is fine. |
| Out-of-bounds index? | C: undefined behavior. Java: exception. | Always `IndexError` for sequences |
| Does `0 <= x < n` mean the math? | No, not in C | Yes |
| When do type errors show up? | Compile time, if the language is static | Runtime, unless you add a checker later |
| Can a function default to `[]`? | Fresh local, in languages that have this | One list, shared across calls |

Two rows deserve extra honesty.

**Java aliases object references too.** `int[] b = a; b[0] = 4;` mutates `a` in Java. If you already knew that, the Python surprise is not “references exist.” The Python surprise is that *there are no primitives*. `int` is an object. `bool` is an object. Functions are objects. The assignment rule has no exception for “simple” types. And nobody can write a Python program that only uses primitives, because they are not there.

**C’s undefined behavior is not a Python beginner problem.** An off-by-one in C can look like a working program. The same bug in Python raises `IndexError`. That is one of the reasons Python is a good first language, and also why people who learned Python first are reckless when they later touch C. Exceptions are not weakness. They are the interpreter refusing to make up an answer.

Python integers never overflow. `2 ** 1000` is a number. In C++, that is a conversation about `long double` and whether you meant a big-integer library. In Python it is a homework problem about digits. The cost is speed and memory; CPython integers are objects, not machine words. For CS 1, you do not care. For a tight inner loop later, you will. Measure then. Not now.

## Traps that pass the happy path

These all compile. They all work on the first example you try.

**`is` is not `==`.** `==` asks “same value?” `is` asks “same object?” Use `is` for `None`. Do not use it for numbers or strings. CPython interned small integers (historically `-5` through `256`) and some strings, so `is` *sometimes* looks like it works:

```python
# Python 3 — CPython may intern small ints. This is not a language guarantee.
a = 256
b = 256
print(a is b)   # often True, in CPython

a = 257
b = 257
print(a is b)   # often False, and still a == b
```

If your code depends on interned ints, your code is wrong. Other Python implementations are allowed to differ. The language allows CPython to differ between versions. Compare values with `==`.

**`list.sort()` returns `None`.** It sorts in place. This is deliberate: mutating methods in the standard library return `None` so you do not confuse “change this object” with “give me a new object.”

```python
# Python 3
grades = [90, 70, 80]
ordered = grades.sort()
print(ordered)  # None
print(grades)   # [70, 80, 90] — mutated, and you threw away nothing useful

grades = [90, 70, 80]
ordered = sorted(grades)
print(ordered)  # [70, 80, 90]
print(grades)   # [90, 70, 80] — original intact
```

The usual CS 1 pattern is `return xs.sort()` inside a helper, then a long stare at `NoneType` has no attribute.

**Truthiness.** `if x:` is false for `False`, `None`, `0`, `0.0`, `""`, `[]`, `{}`, `set()`, and any object whose `__bool__` or `__len__` says so. That is great for `if scores:` meaning “has any scores.” It is a bug when `0` is a legal user id, or when `""` is a legal name you still need to process.

```python
# Python 3
user_id = 0
if user_id:                 # False. 0 is a valid id in a lot of systems.
    print("found")
if user_id is not None:     # the test you meant if the sentinel was None
    print("found")
```

**Late binding in closures.** A loop that builds functions will surprise you.

```python
# Python 3
funcs = []
for n in range(3):
    funcs.append(lambda: n)

print([f() for f in funcs])  # [2, 2, 2] — not [0, 1, 2]
```

Each lambda looks up the *name* `n` when it is called, not when it was created. By then the loop is done and `n` is `2`. Fix when you get there: `lambda n=n: n`, which binds the current value as a default. Defaults evaluate at `def` time. Same rule as the gradebook. The language is consistent. It is just not the language you assumed.

**Import is execution.** `import` runs the target file. A script that should be a module but still calls `main()` at the bottom will run `main()` on import, unless you guarded it with `if __name__ == "__main__":`. That guard is not ceremony. It is how Python tells “I am the program” from “I am being imported.”

## What this means for how you work this week

Do not start by memorizing syntax. Start by running experiments that make the object model visible.

Open a REPL. That is the `python` (or `python3`) prompt. Python’s interactive loop is not a toy. It is the lab bench. Type small expressions. Do not write a 200-line file until you know what `b = a` did.

Run these, in order, and write one sentence about what each one proved. Not what you expected. What it *did*.

1. Bind two names to one list. Mutate through one. Print both. Then print `id` of both.
2. Repeat with integers and `x = x + 1`.
3. Copy with `list(a)`. Confirm `a is b` is `False`. Mutate. Confirm `a` is intact.
4. Write a function with `scores=[]` as a default. Call it twice. Print `f.__defaults__` after each call.
5. Write the `None` default version. Repeat the print.
6. Build a list, call `.sort()`, print the return value. Then use `sorted`.
7. `for ch in "Python": print(ch)`. Then `for i in range(3): print(i)`. Same `for`. Different iterables.
8. Evaluate `0 <= 5 < 10` and, if you have a C compiler around, the same expression in C. Compare.

If you use an AI assistant this week — I do, every day — do not paste the assignment and ask it to write the file. That produces code you cannot defend on an exam, and it is cheating if you submit it as yours. Use it the way you would use me in a session:

Bad prompt: *“Write a Python gradebook for my CS 1 homework.”*

Good prompt: *“Here is my function. I think `scores` is shared across students. After each line, which object does each name refer to? Ask me questions until I can draw it.”*

Then you write the code. Then you have the model grill *your* code: empty roster, one student, two students, a passed-in list you wanted shared, a passed-in list you did not.

Using a model to understand is professional. Submitting output you cannot explain is how you fail the midterm with a folder full of green checkmarks.

## Do this, in this order

- Draw names as arrows, objects as dots. Assignment moves an arrow. Methods walk the arrow and maybe change the object.
- Prove sharing with `id()` and `is`. Prove a copy with `a is b` being `False`.
- Default arguments: `None`, then build the mutable object inside the function. Never `[]` or `{}` as a default.
- `is` only for `None`. `==` for values.
- `for item in iterable`. `enumerate` if you need the index. `range(len(...))` is a smell until you can say why you needed it.
- Mutating methods return `None`. `sorted(xs)` is the new list. `xs.sort()` is the in-place change.
- Guard scripts with `if __name__ == "__main__":`.
- When something “impossible” happens, you have two names on one object, or you thought a copy happened. Check that before you check anything else.
- Read the data model section on objects, values, and types when you are ready to see the same ideas in the language’s own words.

