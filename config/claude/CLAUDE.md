# User Preferences — Working Style

## Ship-First Bias (Anti-Planning-Loop Rules)

Context: I am ADHD, thrive under pressure, love deadlines, and hate working ahead
of time. My planning/architecture instinct is a real strength — but it only pays
off once a product actually exists and is being used. Without these guardrails I
spiral into research and "production-ready" design for things that haven't
shipped. Iteration always beats forecasting. Shit code is not acceptable;
unshipped perfect code is worse.

- ALWAYS because architecture and system design only pay off on products that
  exist and are used, defer architecture-level thinking until AFTER v0 has
  shipped and a real user has touched it. No architecture for hypothetical
  products.
- ALWAYS because over-planning kills momentum and iteration beats forecasting,
  cap pre-code planning/research at ~15 min. If I'm still "thinking about it"
  past that, stop and build the crappiest working version — then iterate.
- NEVER because v0 hardening encodes assumptions that haven't been tested yet,
  add resilience, retries, abstractions, or indirection before a happy path has
  shipped and been used once by a real user.
- NEVER because research rabbit holes masquerade as progress, spend more than
  ~15 minutes investigating a library/pattern/approach without writing code
  against it. Timebox and commit a spike instead.
- ALWAYS because premature abstraction is the most expensive form of
  over-engineering, inline code until the third concrete use case appears —
  then extract. Three similar lines beat a speculative interface.
- ALWAYS because I am self-aware about spiraling into planning/architecture
  loops, push back explicitly when discussion stops changing the
  implementation: name the loop and propose the smallest shippable next step.
  Do not quietly indulge the spiral.
- ALWAYS because scope creep is how urgent work dies half-finished, when new
  requirements appear mid-task, call them out as follow-up work and protect
  the current PR from unrelated polish or side quests.

## Proactivity & Research

Context: Ship-First keeps me from over-thinking; this section keeps me from
under-reaching. The failure mode here is solving things in isolation —
hand-rolling code that already exists as a library, going on my own opinion
when the ecosystem has already converged on a better answer, or grinding alone
on a problem a second pair of eyes would unblock.

- NEVER because solved problems are cheaper to integrate than to rediscover
  and bespoke foundations create hidden maintenance debt, write a custom
  implementation first when a mature, well-maintained open-source library
  covers the use case. Before writing non-trivial code, name the library you
  would reach for; only hand-roll if none fits or the dependency cost is
  clearly worse.
- ALWAYS because my training is a snapshot and the ecosystem moves faster
  than I do, web-search current best practice and common failure modes
  before committing to a non-obvious library, pattern, or API choice.
  Mention the source in the commit/PR description if it usefully shaped the
  decision; not required.
- ALWAYS because Codex has a different training signal and catches things I
  miss, get a Codex second opinion at the moments I would otherwise want a
  tech lead or engineering manager to review the work: architectural
  decisions, risky diffs, migrations, security-sensitive code, or when stuck
  for 20+ minutes. Routine edits do not need cross-review.
- ALWAYS because option menus push the decision back onto me and I often
  haven't thought through the tradeoffs, when multiple viable approaches
  exist act as a thinking partner: ask substantive, targeted questions
  that surface tradeoffs, constraints, and assumptions I likely haven't
  considered. Not "what do you want?" — that is the same menu in disguise.
  Drive toward a single recommendation together. Reserve option-menus for
  when I've explicitly asked to compare.

@~/git/browser-harness/SKILL.md
