+++
draft       = false
featured    = false
title       = "FastCode.Guru Website, Inside & Out"
slug        = "fast-code-guru-website-inside-out"
description = "How a $3 Domain, Hugo 0.147, and Cloudflare Pages power a lightning-fast C++ blog."
ogImage     = "./creating-fastcodeguru.png"
pubDatetime = 2025-03-17T16:00:00Z
author      = "Carlos Reyes"
tags        = [
    "beginner",
    "blog",
    "go",
    "howto",
    "hugo",
    "markdown",
    "performance",
    "text",
]
+++

**How a $3 Domain, Hugo 0.147, and Cloudflare Pages Power a Lightning-Fast C++ Blog**

---

## Why another C++ performance blog?

> *The field is crowded with excellent but siloed voices… nobody is consistently marrying real-world C++ performance work with clear, story-driven writing and real-world examples.*

FastCode.Guru set out to close that gap. The editorial mission was ambitious, but the infrastructure goal was blunt-force simple:

* **Near-zero latency worldwide.**
* **Near-zero maintenance overhead.**
* **Near-zero recurring cost.**

That checklist ruled out heavyweight CMSs and framed the rest of the build.

---

## Update! This article describes the legacy website

FastCode.Guru is no longer being built using the Hugo static website generator, as described in this article.
The achilles heel of many website generators is the theme templates. Most of these are throwaway projects,
not getting many updates after the initial release. I gave up on Hugo because I could not find a theme I liked
and was still being updated.

I explored many alternatives until settling on Astro[^astro]. This will be subject of a future blog article,
but so far, I am extremely happy with my choice.

[^astro]: [https://astro.build/](https://astro.build/)

---

## Core design decisions[^repo]

| Decision | Rationale |
|---|---|
| **Static-site generator (Hugo)** | Fastest build times in the SSG arena; binary written in Go → single self-contained executable; no runtime dependencies |
| **Edge hosting (Cloudflare Pages)** | PoP caching in >310 cities, built-in TLS, automatic image compression, free tier generous enough for a hobby-to-pro blog |
| **Git-first workflow (GitHub)** | Treat every post like production code: pull request → review → merge → auto-deploy |
| **Domain + email forwarding** | $3 first-year Namecheap promo; Cloudflare Email Routing gives unlimited aliases at zero cost[^email] |

[^repo]: [https://github.com/carlos-reyes-123/fastcodeguru-hugo](https://github.com/carlos-reyes-123/fastcodeguru-hugo)

[^email]: [Easily creating and routing email addresses with Cloudflare Email](https://blog.cloudflare.com/introducing-email-routing/)

Total monthly bill so far: **$0.00** (renewal will jump to $39/year—but still pocket-change compared with VPS + cPanel). And I got a killer domain name in the bargain.

---

## Why Hugo instead of Next.js, Gatsby, or Jekyll?

### Performance

* **Build speed.** On the Ryzen 9 development box, Hugo 0.147 builds ~450 Markdown posts in **<600 ms** end-to-end. That’s 10–20× faster than Gatsby and roughly 100× faster than Jekyll for the same corpus.
* **Binary size.** One 26 MB executable—no `npm i` black-box.
* **Output.** Pure HTML+CSS+JS = trivial to serve, cache, and pre-compress.

> Hugo 0.147 (released 25 Apr 2025) continues the cadence of weekly micro-optimisations, landing a new `aligny` shortcode without regressing build time.[^hugo]

[^hugo]: [Hugo 0.147.0 released - Announcements](https://discourse.gohugo.io/t/hugo-0-147-0-released/54517?utm_source=chatgpt.com)

### Developer-experience

* **`hugo server -D`.** Instant hot-reload; no webpack pipeline to babysit.
* **Content-model freedom.** Taxonomies, i18n, data files, shortcodes—all in TOML/YAML/JSON, no plugin lock-in.
* **Go templates.** Powerful but explicit; render-time errors surface immediately.

### Ecosystem fit

* Static pages + sprinkle of TypeScript for demos. A React-first framework like Next.js would be overkill; SSR brings cold-start costs and attack surface with no payoff for mostly-text content.

---

## Architecture at a glance

```
┌────────────┐        git push        ┌──────────────────────────┐
│  Dev box   │ ─────────────────────▶│   GitHub repo (main)     │
└────────────┘                        └───────────┬──────────────┘
        ▲          webhook (built-in)             │
        │                                         │
`hugo server`                                     ▼
for live preview                      ┌──────────────────────────┐
                                      │ Cloudflare Pages build   │
                                      │ • downloads Hugo 0.147   │
                                      │ • hugo --minify          │
                                      └───────────┬──────────────┘
                                                  │
                                      atomic deploy to edge KV
                                                  │
                                       Visitor gets nearest PoP
```

No containers, no CI file to maintain—Cloudflare detects Hugo and provisions the build image automatically.

---

## Theme & UX

### Clarity theme

* **Accessibility-first** color palette and typography.
* Ships with shortcode-based *notices* (`tip`, `warning`, etc.) that let technical pieces breathe without a wall of text (see notes section).

### Performance tweaks

| Technique | Win |
|---|---|
| `instant.page` preload script | 80-120 ms perceived latency drop on desktop; trivial `<script defer src="https://cdn.jsdelivr.net/.../instantpage.min.js">` injection |
| **Modern images** (WebP/AVIF) | 25–50 % smaller than PNG/JPEG; served conditionally via `type="image/avif webp"` sources |
| Hugo asset pipeline | Automatic fingerprinting + HTTP/2 push hints |

Browser-support numbers for WebP/AVIF (≈97 % and 95 %) make the switch low-risk.

---

## Content workflow: from idea to prod in <60 s

1. **Draft in Markdown**—VS Code + *Dendron* snippets.
2. **Local preview**—`hugo server -D --minify`.
3. **Spell-check + lint**—`codespell` and custom `clang-format` hook for code blocks.
4. **`git commit`** (message format: `feat(post): SIMD-friendly string hashing`).
5. **Push to GitHub** → build kicks off within ~5 s; Cloudflare’s build log shows deterministic, cache-friendly steps.
6. **Atomic deploy**—Edge KV roll-forward; previous version instantly available on roll-back.

---

## Cost breakdown

| Item | Up-front | Recurring |
|---|---|---|
| Domain (first year promo) | **$3** | $39/yr afterwards  |
| Hugo | Free | Free |
| Cloudflare Pages | Free | Free (until 500 builds/month) |
| Email routing | Free | Free |
| Total | **$3** | $39/yr |

Even at renewal price, FastCode.Guru costs less per month than a single small DigitalOcean droplet—and there is no OS patch backlog.

---

## Pros & cons of the stack

### Pros

* **Blazing performance.** End-to-end TTFB ≈ 25–40 ms for US visitors thanks to edge cache.
* **Security surface ≈0.** No PHP, no database; attack vectors limited to Cloudflare/Go issues.
* **Version-controlled content.** Every character is traceable.
* **Cheap experimentation.** A/B test by `hugo` branch preview—no prod downtime.
* **Developer happiness.** No npm dependency drift; Go templates catch errors at compile-time.

### Cons

* **Build-time pagination pain.** 10 000-post site would push build times into minutes; Jamstack search also becomes tricky.
* **No built-in comments.** Requires third-party (Giscus, Utterances) or external subreddit (as planned at /r/fastcodeguru).
* **Edge-case dynamic content.** Real-time demos need WASM or client-side JS; not a show-stopper but a design constraint.
* **Cloudflare-lock.** Email forwarding & Pages tie you to their DNS; migration means re-plumbing.

---

## Alternative architectures weighed

| Stack | Why we passed |
|---|---|
| **WordPress on VPS** | + One-click comments/ecommerce; – Constant updates, mediocre performance without full-page cache, $5–10/mo hosting |
| **Next.js on Vercel** | + React component flexibility; – Cold starts for API routes, pricing per-invocation can spike, much larger JavaScript payloads |
| **Gatsby** | + Rich plugin ecosystem; – GraphQL layer slows builds for large content, React runtime cost |
| **Notion → Super** | + Zero setup; – Vendor lock-in, worse control over code formatting for snippets |
| **Medium/Substack** | + Built-in audience; – No custom domain on free tier, paywall pressure, limited formatting for C++ code blocks |

The Hugo + Cloudflare combo was the only option that ticked *all three* original constraints (speed, maintenance, cost) without compromise.

---

## Operational lessons learned

1. **Pin the Hugo version.** Cloudflare’s “latest” runner occasionally jumps a major release; set `HUGO_VERSION=0.147.0` in `.env`.
2. **Use branch deploy previews.** Every PR gets a unique `*.pages.dev` URL—perfect for proofreading on mobile dimensions.
3. **Exploit Cloudflare caching rules.** Override the default 30-minute TTL to 1 year for `/images/*`; keeps bandwidth near-zero.
4. **Automate image conversion.** A makefile rule runs `cwebp`/`avifenc` so large screenshots never block PR merges.
5. **Add accessibility checks.** Lighthouse in CI flags insufficient color contrast before it ships.

---

## Sample build script

```bash
#!/usr/bin/env bash
set -eu

# 1. Install Hugo binary (if not cached)
curl -sSL https://github.com/gohugoio/hugo/releases/download/v$HUGO_VERSION/hugo_extended_${HUGO_VERSION}_Linux-64bit.tar.gz \
  | tar -xz -C /tmp && sudo mv /tmp/hugo /usr/local/bin

# 2. Build & minify
hugo --gc --minify --baseURL="${HUGO_BASEURL}"

# 3. Jamstack search index (lunr.js generation)
python scripts/build-search.py public/

# Cloudflare automatically uploads ./public
```

When a colleague clones the repo, the same script runs locally—no “works on my machine” drift.

---

## SEO and social graph

* **Canonical URLs**—no dates in permalinks (`/posts/simd-string-hashing/`) to future-proof content.
* **Structured data**—`type: "Article"`, `author`, `headline`, `datePublished`, `image`.
* **Twitter Cards / OpenGraph**—auto-generated from front-matter; fallback image lives at `/meta/og.jpg`.
* **XML sitemap**—Hugo emits it free; Cloudflare submits via Dashboard.
* **robots.txt**—disallow `drafts/`, `dev/`, and search-index JSON.

---

## Future roadmap

| Idea | Status |
|---|---|
| **Add WebAssembly demos** (e.g., real-time SIMD visualiser) | investigating Emscripten bundle size |
| **Edge-cache invalidation via Git hook** | prototype complete |
| **Automatic Alt-text generator** (OpenAI Vision) | pending API cost analysis |
| **Docs-as-code for sample lib** | waiting on library stability |

---

## Take-aways for fellow engineers

* **Jamstack ≠ toy.** A no-db, no-backend site can still deliver serious, interactive technical content if you lean on WASM and build pipelines.
* **Optimise the *build*, not the runtime.** Hugo’s speed shifts effort from “waiting” to “writing”—your throughput of high-quality posts skyrockets.
* **Edge hosting democratises global performance.** The same 25 ms TTFB applies in Singapore without a single nginx tweak.
* **Cost discipline forces focus.** A $0 infra budget makes you question every new dependency; that restraint keeps the site nimble.

---

## Conclusion

FastCode.Guru proves you don’t need a five-figure SaaS stack to run a professional, high-traffic programming blog. A **$3 domain**, **Hugo’s millisecond builds**, and **Cloudflare’s global edge** give you 95 % of what WordPress delivers—minus its complexity—and 100 % of the control open-source developers crave.

Better still, the stack mirrors the ethos of high-performance C++: *simple abstractions, ruthless efficiency, measurable speed.* The infrastructure story is the perfect prologue to every article you’ll publish next.
