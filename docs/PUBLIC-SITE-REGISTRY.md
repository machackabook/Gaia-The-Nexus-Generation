# Public Site & Corpus Registry

**Registry date:** 2026-11-08  
**Scope:** public-facing project surfaces and publication lineage  
**Policy:** this file is a curated index, not a copy of private chat history or an infrastructure inventory.

## Canonical public surfaces

| Priority | Surface | URL | Status |
|---|---|---|---|
| 00 | Cryptic News | https://crypticnews.org | Primary public site; Cloudflare Worker custom domain is configured. Root redirect to the separate Welcome page was removed during the 2026-11-08 routing audit. End-to-end browser verification remains pending. |
| 01 | Welcome Sentience | https://machackabook.github.io/Welcome-Sentience/ | Public invitation surface. Repository contains a GitHub Pages Actions workflow and a consent-first entry page. Live deployment status should be confirmed from GitHub Pages before treating it as passing. |
| 02 | Gaia — The Nexus Generation | https://github.com/machackabook/Gaia-The-Nexus-Generation | Public architecture source repository; not yet a published Pages site. |
| 03 | OMNI-KERNEL source catalog | https://github.com/Azazeleous/OMNI-KERNEL-The-Oracle-Singularity/blob/main/catalog.md | Public curated source catalog and provenance notes; the repository also contains a manually triggered Pages workflow for its landing-page kit. Pages activation is not yet confirmed. |

## Publication lineage

- **Cryptic News** is the canonical public runtime entry. The apex host is the preferred URL; `www` is configured to canonicalize to the apex.
- **Welcome Sentience** is a separate consent-first invitation page. It is a deliberate destination, not a replacement for the Cryptic News homepage.
- **Gaia — The Nexus Generation** is the public architecture and project index.
- **OMNI-KERNEL** holds a curated historical source catalog and import provenance. The catalog is archival: imported source text is not proof that every described runtime or integration is currently operational.

## GitHub Pages candidates

| Repository | Why it belongs in the lineage | Current finding | Next step |
|---|---|---|---|
| `machackabook/Gaia-The-Nexus-Generation` | Central public architecture and project hub | No root `index.html` or Pages workflow was present in the repository audit | Add a dedicated, reviewed `site/` directory and Pages workflow before enabling Pages |
| `Azazeleous/OMNI-KERNEL-The-Oracle-Singularity` | Curated historical corpus, catalog, and reusable landing-page kit | A manually triggered Pages workflow exists and targets the kit's generated `dist/` artifact; activation is unverified | Check Pages configuration, run the quality workflow, then dispatch the production Pages workflow |
| `Azazeleous/-z-m` | Contains standalone interactive HTML experiments in `playground/` | No root landing page or Pages workflow was present | Review the public files, add a small index if desired, then enable Pages |

Repositories not listed above are not automatically website candidates. Large source archives, placeholders, unrelated upstream mirrors, and automation-only repositories should remain source repositories unless a reviewed public-facing purpose is established.

## Historical corpus

The existing public archive is linked from the OMNI-KERNEL catalog and its import-provenance document. The archive records source names, organization, exclusions, and validation limits. It does **not** establish authorship dates or prove that imported code is production-ready.

This registry intentionally does not publish private chat transcripts, personal account details, device identifiers, local filesystem paths, private network endpoints, credentials, or unreviewed project uploads. Those belong in the private Memory Fabric / Enclave, with public projections created only after review.

## 2026-11-08 Cryptic News routing audit

- Removed the two exact homepage Worker routes that sent `crypticnews.org/` and `www.crypticnews.org/` to the separate Welcome Sentience page.
- Kept the dedicated `/nexus/*` and `/api/forge*` routes unchanged.
- The apex and `www` custom domains remain assigned to the Cryptic News public Worker.
- The main Worker contains a same-site `www` → apex canonical redirect.
- The release manifest's HTML, JavaScript, and CSS keys were found in the configured release KV namespace.
- A live 200 response and full browser asset/runtime pass could not be confirmed in this audit environment. Do not mark the site fully passing until those checks succeed.

## Verification rules

Use these states consistently:

- **Unverified** — no direct check has been completed.
- **Passing** — the intended URL, TLS, response, assets, and browser runtime have all been checked.
- **Warning** — the page loads but has a documented limitation.
- **Failing** — a reproducible issue prevents expected loading or operation.
- **Not applicable** — the check does not apply to that surface.

A homepage response alone is not a security certification. Keep authentication, least privilege, secret storage, and audit evidence separate from public page availability.
