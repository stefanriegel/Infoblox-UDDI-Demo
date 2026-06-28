# Workflow narration is the demo UI

The GitHub Actions workflows are the product's presentation surface, not just orchestration. The verbose log narration (banner boxes, per-zone/per-record progress), the per-provider verification dashboards, and the `$GITHUB_STEP_SUMMARY` markdown (Mermaid diagrams, tables, value-proposition sections) exist to *show* an SE audience what Terraform + UDDI are doing. They are the demo.

## Consequence for architecture reviews

Do **not** treat workflow verbosity as duplication to collapse. Specifically, these are deliberate and stay:

- The two-pass / per-provider DNS dashboards in `run-demo.yml` (query then render per Cloudflare/Azure/Route53/GCP).
- The hand-built job-summary skeletons (Mermaid + tables) across all workflows, including the two near-identical ones in `cleanup.yml`.

A reviewer optimizing for DRY would flag these; they are presentation, and the redundancy is the point.

## What may still be deepened

Only the **plumbing behind the narration** — logic that is not itself shown as the demo's payoff:

- UDDI API access (auth, base URL, pagination, the `is_demo` predicate, delete) → extracted to the `uddi` composite action (`.github/actions/uddi/`). This fixed a real bug: the demo-tag predicate had drifted between DNS records and IPAM subnets. The action emits its own operational narration to the run log, and the workflows keep every `$GITHUB_STEP_SUMMARY` block.
- The per-cloud Terraform deploy loop in `vpc-deployment.yml` → extracted to the `deploy-network` composite action. Orchestration, not narration; the per-cloud verification dashboards stay in the jobs.
- The public-resolver `dig` loop (Google/Cloudflare/Quad9) → extracted to the `dns-resolvers` composite action, shared by `run-demo.yml` and `combined-demo.yml`. The action writes the same `dig-*.txt` files / exposes the answers as outputs, so each workflow's presented summary is unchanged — only the resolver set and the empty-answer fallback stopped being duplicated.
- The DNS provider dashboard's **second-pass field re-extraction** in `run-demo.yml` → the verification step now writes a normalized `dns-record.json` once (`{provider,found,id,fqdn,type,target,ttl,proxied,provisioning_state}`), and the `Job Summary - DNS Verification` step renders from it instead of re-running per-provider `jq` over the raw `*-response.json`. The two visible per-provider dashboards (query narration in the verification step, and the markdown summary) both stay byte-identical; only the duplicated extraction died. The raw `*-response.json` files are still written and uploaded as proof. This is the bounded slice of the dashboard normalization — the queries and rendering themselves are presentation and were left in place.

The sharper line, learned while doing this: the *visible* per-provider dashboards and `dig` output stay (presentation); the *mechanics that produce them* (the resolver loop, the API auth/pagination, the deploy loop) are plumbing and may sit behind a seam, as long as the workflow still renders the same thing.

## Rule of thumb

If removing it changes what the audience *sees*, it is demo UI — leave it. If it only changes how the bytes are fetched or filtered, it is plumbing — it may move behind a seam.
