+++
draft       = false
featured    = false
title       = "Unique Id Generator Survey"
slug        = "unique-id-generator-survey"
description = "I compare seven widely used pseudo-random unique-ID generators."
ogImage     = "./unique-id-generator-survey.png"
pubDatetime = 2025-02-07T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "Unique Identifiers",
    "UUID v4",
    "UUID v7",
    "ULID",
    "NanoID",
    "MongoDB ObjectId",
    "KSUID",
    "TSID",
    "Snowflake ID",
    "Pseudo Random Generators",
    "Timestamp Embedding",
    "Sortable Identifiers",
    "Collision Resistance",
    "Distributed Systems",
    "High Throughput Systems",
    "Database Indexing",
    "URL Friendly IDs",
    "Lexicographic Ordering",
    "Human Readable IDs",
    "Technical Comparison Study",
]
+++

![Unique Id Generator Survey](./unique-id-generator-survey.png "Unique Id Generator Survey")

## Table of Contents

---

## Introduction

In this survey, I compare seven widely used pseudo-random unique-ID generators—UUID (v4 & v7), ULID, NanoID, MongoDB ObjectId, KSUID, TSID, and Twitter’s Snowflake—along key dimensions: bit-width, text representation, encoding, embedded timestamp (and sortability), randomness, collision resistance, human-readability, and potential pitfalls (check digits, “magic”/version bits, ambiguous characters). A consolidated comparison table is provided up front, followed by in-depth overviews of each scheme, discussion of strengths and weaknesses, and recommendations for scenarios ranging from high-throughput distributed systems to compact web tokens.

## Comparison Table

*Compiled from official specifications and community benchmarks* ([Wikipedia][1], [GitHub][2], [GitHub][3], [MongoDB][4], [GitHub][5], [Foxhound Systems][6], [Wikipedia][7])

| Generator     | Bit-Width | String Length   | Encoding                | Timestamp Bits                                               | Random Bits                                            | Sortable?                  | Check Digit | Character Set                                    | Ambiguous Characters    |
| ------------- | --------- | --------------- | ----------------------- | ------------------------------------------------------------ | ------------------------------------------------------ | -------------------------- | ----------- | ------------------------------------------------ | ----------------------- |
| **UUID v4**   | 128       | 36 (8-4-4-4-12) | Hexadecimal + hyphens   | 0 (v4 is purely random)                                      | 122 (6 version+variant bits) ([Wikipedia][1])          | No                         | No          | 0–9, a–f, ‘–’                                    | 0↔O, 1↔I/l              |
| **UUID v7**   | 128       | 36              | Hex + hyphens           | 48 (Unix ms epoch) ([npm][8])                                | 74 (version+counter+random) ([npm][8])                 | Yes (lexicographic)        | No          | 0–9, a–f, ‘–’                                    | 0↔O, 1↔I/l              |
| **ULID**      | 128       | 26              | Crockford Base32        | 48 (Unix ms epoch) ([GitHub][2])                             | 80 ([GitHub][2])                                       | Yes (lexicographic)        | No          | A–Z, 0–9 (no I, L, O, U) ([GitHub][2])           | Minimal (designed safe) |
| **NanoID**    | Variable  | \~21 (default)  | URL-safe Base64 variant | 0 (fully random)                                             | \~168 bits of randomness (21 × 6 bits) ([GitHub][3])   | No                         | No          | A–Z, a–z, 0–9, ‘\_’, ‘-’ ([GitHub][3])           | ‘\_’↔‘-’, O↔0, l↔1      |
| **ObjectId**  | 96        | 24 (hex)        | Hexadecimal             | 32 (seconds since Unix epoch) ([MongoDB][4])                 | 40 (5-byte random value) + 24 (counter) ([MongoDB][4]) | Roughly (per-second order) | No          | 0–9, a–f                                         | Minimal (hex only)      |
| **KSUID**     | 160       | 27              | Base62                  | 32 (big-endian UTC seconds since 2014-05-13) ([GitHub][5])   | 128 ([GitHub][5])                                      | Yes (lexicographic)        | No          | 0–9, A–Z, a–z                                    | 0↔O, 1↔I/l              |
| **TSID**      | 64        | 13              | Crockford Base32        | 42 (ms-precision since custom epoch) ([Foxhound Systems][6]) | 22 (random/counter/node mix) ([Foxhound Systems][6])   | Yes (numerical order)      | No          | A–Z, 0–9 (no I, L, O, U) ([Foxhound Systems][6]) | Minimal (safe set)      |
| **Snowflake** | 64        | \~18–19 digits  | Decimal                 | 41 (ms since custom epoch) ([Wikipedia][7])                  | 12 (sequence) + 10 (machine) ([Wikipedia][7])          | Yes (numerical order)      | No          | 0–9                                              | None (digits only)      |

## 1. UUID (Universally Unique Identifier)

UUIDs are 128-bit identifiers standardized by RFC 4122.

* **UUID v4** is purely random (122 bits of entropy) with 6 fixed version/variant bits; average collision risk is negligible (2^122 possible values) ([Wikipedia][1]).
* **UUID v7** embeds a 48-bit Unix-millisecond timestamp followed by random bits, restoring sortability while retaining randomness ([npm][8]).
* **Strengths:** Universally supported across databases, languages, and platforms; no coordination needed ([Wikipedia][1]).
* **Weaknesses:** v4 is not ordered; hyphenated hex is bulky; index fragmentation in databases; version bits act as “magic” markers but can break lexicographic order ([Wikipedia][1]).
* **Use Cases:** v4 for general-purpose IDs where order doesn’t matter; v7 for time-series keys in high-load databases.

## 2. ULID (Universally Unique Lexicographically Sortable Identifier)

ULID is a 128-bit, Base32-encoded ID combining a 48-bit millisecond timestamp and 80 bits of randomness ([GitHub][2]).

* **Strengths:** Lexicographically sortable, URL-safe, case-insensitive, no ambiguous characters (omits I, L, O, U) ([GitHub][2]).
* **Weaknesses:** Randomness within the same millisecond is not sequenced; 26-character string still longer than decimal Snowflake IDs ([GitHub][2]).
* **Use Cases:** Distributed databases needing sortable keys; log-aggregation; offline-first systems.

## 3. NanoID

NanoID generates compact, cryptographically secure, URL-friendly IDs in JavaScript (and >20 languages), defaulting to 21 characters (≈168 bits) from an alphabet of 64 symbols (A–Z, a–z, 0–9, ‘\_’, ‘–’) ([GitHub][3]).

* **Strengths:** Extremely small bundle (< 120 B gzip), customizable length and alphabet, no external dependencies ([GitHub][3]).
* **Weaknesses:** Not time-sortable; default alphabet may include confusing symbols (‘\_’ vs ‘–’, O↔0, l↔1) ([GitHub][3]).
* **Use Cases:** Front-end session tokens; short links; non-sequential random IDs.

## 4. MongoDB ObjectId

ObjectId is a 12-byte BSON type: 4 bytes timestamp (seconds), 5 bytes random value, 3 bytes counter ([MongoDB][4]).

* **Strengths:** Rough insertion order; compact 24-hex string; built into MongoDB with getTimestamp() support ([MongoDB][4]).
* **Weaknesses:** Only second-level resolution; client clocks may differ; not strictly monotonic; no textual check digit ([MongoDB][4]).
* **Use Cases:** Default MongoDB document IDs; document versioning.

## 5. KSUID (K-Sortable Unique IDentifier)

KSUID is a 20-byte (160 bit) ID: a 32-bit big-endian “KSUID epoch” timestamp + 128 bits of randomness, encoded as 27 Base62 characters ([GitHub][5]).

* **Strengths:** Sortable by creation time; over 100 years of timestamp range; high collision resistance (2^128) ([GitHub][5]).
* **Weaknesses:** Base62 includes all letters and digits, leading to potential 0/O and 1/I/l confusion ([GitHub][5]).
* **Use Cases:** Segment’s analytics pipeline; clustered‐index keys in SQL databases.

## 6. TSID (Time-Sorted Unique IDentifier)

TSID is a 64-bit integer: leading 42 bits for ms-precision timestamp + 22 bits of random/node/counter, optionally including a node ID, rendered as 13 Crockford Base32 characters ([Foxhound Systems][6]).

* **Strengths:** Drop-in replacement for 64-bit auto-increment; efficient indexing; human-readable 13-char URLs; strong collision resistance ([Foxhound Systems][6]).
* **Weaknesses:** Millisecond granularity can reorder within the same ms; configuration complexity for multi-node setups; requires user-defined generator ([Foxhound Systems][6]).
* **Use Cases:** SQL primary keys where ordering and compactness matter; microservices needing consistent 64-bit IDs.

## 7. Snowflake (Twitter)

Snowflake is a 64-bit integer: 41 bittimestamp (ms since custom epoch) + 10 bits machine ID + 12 bits per-ms sequence, serialized as a decimal string ([Wikipedia][7]).

* **Strengths:** Numerical IDs (no alphabet confusion); monotonic per-machine; extractable timestamp; widely adopted by Twitter, Discord, Instagram ([Wikipedia][7]).
* **Weaknesses:** Epoch and bit allocations are fixed; requires coordination for machine IDs; long decimal (\~18 digits) can be cumbersome in URLs ([Wikipedia][7]).
* **Use Cases:** Social‐media post IDs; high-scale event logs; distributed systems requiring per-node unique sequences.

## Recommendations

* **Compact, random web tokens:** NanoID
* **Universal library support & large address space:** UUID v4 (random) or UUID v7 (sorted)
* **Ordered distributed IDs:** ULID (128 bits) or KSUID (160 bits)
* **Space-efficient SQL primary keys:** TSID (64 bits)
* **MongoDB specific:** ObjectId
* **High-throughput event streaming:** Snowflake (per-node sequences)
* **When timezone auditing is critical:** Snowflake or ULID/UUID v7 (explicit timestamp)
* **Avoid confusing characters:** choose ULID or TSID (omit I, L, O, U)

Each generator balances trade-offs in size, sortability, entropy, and human-factors. Your ideal choice depends on whether you prioritize pure randomness, timestamp ordering, storage efficiency, or ease of transcription.

[1]: https://en.wikipedia.org/wiki/Universally_unique_identifier "Universally unique identifier"
[2]: https://github.com/ulid/spec "The canonical spec for ulid - GitHub"
[3]: https://github.com/ai/nanoid "ai/nanoid: A tiny (124 bytes), secure, URL-friendly, unique string ID ..."
[4]: https://www.mongodb.com/docs/manual/reference/bson-types/ "BSON Types - Database Manual v8.0 - MongoDB Docs"
[5]: https://github.com/segmentio/ksuid "segmentio/ksuid: K-Sortable Globally Unique IDs - GitHub"
[6]: https://www.foxhound.systems/blog/time-sorted-unique-identifiers/ "TSIDs strike the perfect balance between integers and UUIDs for most databases – Foxhound Systems"
[7]: https://en.wikipedia.org/wiki/Snowflake_ID "Snowflake ID"
[8]: https://www.npmjs.com/package/nanoid "nanoid - NPM"
