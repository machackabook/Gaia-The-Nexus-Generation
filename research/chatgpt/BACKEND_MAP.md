# Backend Correlation Map — Pass 1

## Confirmed GitHub surfaces

### NEXUS-SENTINEL-LEDGER

Observed repository material includes:

- `sentinel_prime/tdoc-meta-wrapper-v9.sh`
- archived v8 TDOC wrapper
- append-only ledger path
- lock, manifest and quarantine directories
- remedy/continuity concepts
- `docs/WATERFALL.md`
- `mesh/REPOS.manifest.json`
- environment template explicitly warning against committing filled secrets

This is the strongest existing Sentinel lineage and should be referenced rather than independently reimplemented.

### nexus-repo-sync

Observed repository material includes:

- `config/gaia-sync.json` with schema `gaia-sync-policy/v1` and project `GAIASWINDOW`
- `.github/workflows/cascade.yml`
- `.github/workflows/waterfall-hourly.yml`
- `.github/workflows/evolution-controller.yml`
- `docs/PIPELINE.md`
- `docs/LEDGER.jsonl`
- `docs/engram/ENGRAM_INDEX.md`
- convergence and Team Enhance records

Existing documentation explicitly preserves important invariants: no secrets in the public tree, no blind history rewrite, and review for divergence.

## GaiasWindow convergence target

The Windows node should therefore be assembled as an integration surface over existing authorities:

```text
GaiasWindow
  -> local Windows bootstrap / health baseline
  -> Sentinel adapter -> NEXUS-SENTINEL-LEDGER lineage
  -> sync adapter -> nexus-repo-sync policy
  -> telemetry / diagnostic normalization
  -> Gaia visual/runtime surface
  -> reviewable GitHub branch + PR
```

The Drive document `Gaias Window: A Comprehensive Analysis of Webtvos Integration` describes an environmental-monitoring architecture with ingestion, ledger, AI/ML processing and a visualization/WebTVOS layer. It also contains examples involving Docker Compose, Python, Node.js, cloud storage and Kubernetes. Those are document-described design elements and should be verified against actual repositories before being labeled deployed.

## Next-pass questions

- Which Drive artifacts correspond byte-for-byte or semantically to GitHub files?
- Which Windows diagnostics identify actionable GaiasWindow stability issues?
- Which Sentinel v8 concepts were intentionally changed in v9?
- Which mesh/cascade workflows are active versus documentary remnants?
- Which GaiasWindow visual/telemetry components already exist in Gaia-related repositories?
