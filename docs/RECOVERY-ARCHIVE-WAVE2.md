# Recovery audit — wave 2: archives and AIEnvironment

Status: read-only inspection; not production verified. Raw recovered archives remain outside this public repository.

## Local ZIP inventory
- Golden_Army_DevOS_Cloudflare_v0.6.zip: 19 entries; no nested ZIP entries. Includes Cloudflare Worker, Python bridge, deployment workflow, SQL migration, and PXE docs.
- omni-ide-singularity-quine.zip: 14 entries; no nested ZIP entries. Includes Kotlin IDE, Antigravity, Frontal Cortex and Singularity Quine modules.
- the-scribe-of-nexus (1).zip: cannot parse as standard ZIP; no PK ZIP signature found. Preserve bytes and hash; format/encryption unknown. Do not overwrite or execute.

## Initial code review flags
- Golden Army bridge contains subprocess and shell=True; review command execution paths, authentication and network bind behavior before use.
- No full code audit or credential scan has been completed for these archives.

## Drive recovery discovery
- MustSave folder: ID 1-0e_O9XBhAvFfVmjMtOvfvPagkII3LYN
- Child AIEnvironment: ID 1-5JjmA1ECt9mnTa0qUYyopmW-4gCh5n4
- Child files/folders: AI_Environment.command; QChatBackups_20250604_130307; Projects; GeminiNexus.
- GeminiNexus includes config, filesystem, fallback, gemini_venv, hypercam, iterm2, logs, permissions, styles, terminals, venv.
- Multiple AIEnvironment and MustSave copies exist across connected Drive accounts; canonical identity is not yet established.

## Next tasks
1. Recursively enumerate Drive folder trees, tracking visited IDs and continuation pages.
2. Download permitted ZIP and archive candidates to private quarantine, never directly to public Git.
3. Identify nested archive formats and enforce file count, expanded-size, path traversal, symlink, and depth limits.
4. Hash and compare duplicates, then scan content for secrets and unsafe execution.
5. Create a redacted component mapping and ADAM proof cards.
