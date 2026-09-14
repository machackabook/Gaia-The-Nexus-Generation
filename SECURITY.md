# Security Policy

## Public/private boundary

This repository is public architecture and reusable software only.

Do not submit:

- API keys, access tokens, passwords, cookies, or OAuth credentials;
- private signing material or certificates;
- encrypted enclave files or their keys;
- customer or payment data;
- private network endpoints that provide authenticated access;
- local caches, logs, compiled bytecode, or machine-specific state.

## Production security gate

Production changes should pass:

1. secret scanning;
2. dependency vulnerability scanning;
3. static analysis;
4. unit and integration tests;
5. artifact integrity checks;
6. provenance generation;
7. least-privilege review;
8. release approval.

## Payment security

Payment credentials are handled by Stripe. The application should store identifiers and entitlement state, not raw card information.

Stripe webhooks must be authenticated and processed idempotently before granting durable entitlements.

## Enclave security

The Nexus Enclave is a separate trust boundary. Public repository code may implement the protocol surface, but the enclave itself and its credentials remain outside this repository.

## Disclosure

If a secret is accidentally committed, rotate/revoke it immediately. Removing a file from the latest commit is not sufficient to assume a credential is safe.
