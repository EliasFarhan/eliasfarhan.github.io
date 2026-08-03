---
layout: post
title:  "Soup Raiders Native (8/11): core::Result everywhere, exceptions only at startup"
categories: [gamedev, cpp]
series: soupraiders-native
---

Opening hook: the rule I wanted was simple — exceptions are allowed while the engine boots and nowhere else. Getting there was a `std::expected`-shaped refactor across four repositories, and the justification I wrote at the top of the plan turned out to be factually wrong.

<!--more-->

## The rule

- `core::Result<T>` (a `std::expected` shape) for anything that can fail on *data*: a missing asset, a malformed file, a version mismatch.
- Exceptions confined to startup, where there's a single catch and a clean exit.
- Nothing past `Begin()` throws. That's what makes the boundary real rather than aspirational.

## Is `std::expected` even available on every toolchain you ship on?

Worth spelling out, because "it's in C++23" is not an answer. The check that actually settles it:

| Check | Result |
|---|---|
| `<expected>` header present in the target's standard library | ✅ |
| guard | `#if _LIBCPP_STD_VER >= 23` |
| compile probe at `gnu++20` | ❌ no `std::expected` |
| compile probe at `gnu++23` | ✅ clean, including `and_then` |
| **the out-of-line symbol, in the shipped shared runtime** | ✅ `bad_expected_access<void>::what()` is **defined** |

- **That last row is the one that matters. A header can be present and still not link.** The runtime had been built with C++23 already, so this was a **toolchain flag change, not a port**.
- Why I bothered checking rather than assuming: another standard header that "should" have been there on the same target is genuinely absent, and I'd already been caught by it once. A standard is a document; a toolchain is an artifact.

## The headline justification was wrong, and checking it fixed a real bug

- The plan said: *GPU setup runs on a job worker, where an escaping exception is `std::terminate`.* It does not. That job is scheduled to the **main queue**, which the main thread drains — so its throws did reach `main()`'s catch all along.
- The genuine worker-thread exposure is elsewhere: the mesh import job (assimp) and the texture decode job. The decode job already caught in place; **the mesh import job did not, and now does.** A real bug, found only because I went back to verify a premise I'd already written down as settled.
- Related subtlety: marking that job failed would have been a no-op, because the downstream scheduling is deliberately unconditional so joins can't deadlock. The failure travels on a scene-level flag instead, reset per load.

## What deliberately did *not* become a `Result`

This is the more interesting half.

- **`Pipeline::SetUniformData` runs ~1300× per frame** on the docks, and its failure mode is an authoring mistake, not a data condition. It got the project's overflow policy instead: **assert in Debug, warn-once and skip in Release.**
- **Warn-*once* is load-bearing**: the log sink writes synchronously at ~100 ms a line. Logging that failure every call would itself be the bug.
- **Three throw sites remain**, documented in the conventions rather than silently skipped — the GPU texture/sampler/transfer-buffer creators sit under interfaces whose signatures carry no error channel, so converting them is a second core-interface refactor of the same size. Converting *boundaries* upstream keep them from escaping.
- The principle: a `Result` is for conditions the caller can act on. Everything else is either an assertion or a policy.

## The small stuff that ate real time

- **`core::Error` had to become `core::ErrorInfo`** — `core::Error` was already the name of the log function, and a class name is hidden by a same-named function in the same scope.
- **A C++20 → C++23 bump broke three files in a fourth repository**: they used `std::terminate` without including `<exception>`. libc++ supplied it transitively at C++20 and stopped at C++23. Three one-line includes, and three sibling headers already had it — so it was oversight, not convention.
- **`RequestExit(bool failed)` / `HasFailed()`** had to be added, because `Run()` calls `Begin()` itself and `main()`'s try can't be narrowed without splitting the core API.
- **Severity belongs at the call site, not in the loader.** FishPalace's dialog manifest is *expected* to be missing; under the old scheme every loader logged its own error. Now the loader reports and the caller decides — that one is a warning.

## The test that shows it working

Delete a shader from both the loose tree and the archive:

```
ERROR: GPU setup failed while importing scene resources: FILE_NOT_FOUND: Could not open data/shaders/docks/docks.frag
ERROR: Scene loading failed; exiting
ERROR: soup_raiders: exiting after a failed scene load
```

Exit code **1**, logged **once**, the asset named, the code typed, no `std::terminate`. A negative test is the only thing that demonstrates an error-handling refactor at all — everything else just proves the happy path still works.

## Verification surface, for scale

Builds on every desktop preset plus the console; a four-way level-swap run; a 109-spot scripted walkthrough with zero error lines; an archive-only run proving every converted loader reads from the zips; and the negative test above.

## Next

Memory: fixed-capacity containers, and the heap nobody has ever sized.
