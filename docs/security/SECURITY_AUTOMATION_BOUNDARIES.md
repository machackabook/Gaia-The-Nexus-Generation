# Security Automation Boundaries

The experimental security surface is defensive and authorization-bound.

Allowed automation:

- configuration/integrity baselines
- file watching
- dependency and CVE inventory
- local/owned network exposure inventory
- firewall and Defender posture checks
- signed artifact verification
- authorized lab/CTF execution
- rollback generation
- telemetry and evidence packaging

Review-gated/high-impact:

- firewall policy mutation
- service removal/disablement
- account/credential changes
- quarantine/deletion
- exploit validation outside an isolated lab
- remote execution on another node
- routing/DNS changes

Not part of autonomous operation:

- credential harvesting
- persistence intended to evade the owner/operator
- unauthorized scanning or exploitation
- security-control bypass
- propagation to unapproved devices
- destructive action without rollback/evidence
