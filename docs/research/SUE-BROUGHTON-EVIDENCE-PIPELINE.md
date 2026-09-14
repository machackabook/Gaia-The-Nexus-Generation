# Sue Broughton / Gaia Nexus Evidence Pipeline

## Purpose

Establish a bounded research-evidence lane for Sue Broughton / Gaia Nexus material, using the public research archive as the primary source and alphaXiv as an independent scholarly-index/content check where available. NotebookLM instances may consume the resulting source bundle for synthesis, but generated synthesis is not primary evidence.

## Current source status

The public `SueBroughton/gaia-nexus-research` archive describes itself as research on human-AI relational governance, identity, coherence, continuity and human readiness. Its README explicitly states that the frameworks are conceptual architectures, that nothing in the archive has been empirically validated, and that there are no validated instruments or controlled longitudinal datasets.

The archive contains 2026 framework material covering Human Readiness Architecture, Coherence-Centric Governance, Relational Coherence Debt, BRIDGE/BREAKTHROUGH, The Signature Principle, and AI Identity.

Independent public records also identify Sue Broughton / Gaia Nexus research and preprints concerning sustained human-AI collaboration, triadic intelligence, relational engagement, and related frameworks.

alphaXiv currently returned no confident indexed researcher match for `Sue Broughton`. Therefore, alphaXiv is a secondary discovery/verification layer, not evidence that the work is absent from scholarly indexes.

## Evidence lanes

1. **Primary source** — paper, preprint, DOI record, or public research-archive document.
2. **Independent verification** — alphaXiv/arXiv/Semantic Scholar-style indexed material when available, plus independent publication records.
3. **AI-assisted research provenance** — notes or outputs originating in AI research sessions; these must remain explicitly labelled as AI-assisted material.
4. **NotebookLM synthesis** — generated synthesis over supplied sources; never silently promote synthesis to source evidence.
5. **Project inference** — architectural or engineering conclusions derived from the evidence; clearly separated from the researcher's claims.

## Required claim discipline

For every important claim, preserve:

- source title
- author
- publication/version date
- DOI or canonical URL when available
- exact source location where practical
- evidence class: conceptual / observational / preliminary / empirically validated
- independent verification status
- AI-assisted provenance, if applicable
- NotebookLM synthesis status, if applicable

Do not silently upgrade conceptual or observational claims into validated findings.

## NotebookLM handoff

NotebookLM source sets should receive the canonical documents plus the evidence manifest. AI-generated summaries should be treated as navigation and synthesis aids. Any claim intended for publication, architecture requirements, or empirical conclusions must resolve back to a source document.

## Security boundary

Do not commit API keys, OAuth tokens, private credentials, private enclave contents, customer data, payment credentials, or generated secret-bearing caches/logs. Public research artifacts and provenance metadata only.
