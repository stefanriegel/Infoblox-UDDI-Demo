# Decisions Register

<!-- Append-only. Never edit or remove existing rows.
     To reverse a decision, add a new row that supersedes it.
     Read this file at the start of any planning or research phase. -->

| # | When | Scope | Decision | Choice | Rationale | Revisable? |
|---|------|-------|----------|--------|-----------|------------|
| D001 | M001 | arch | DNS sync model | UDDI-native sync only (no dual-write) | The whole demo story is "create in UDDI, it syncs everywhere." Dual-write undermines the message. | No |
| D002 | M001 | arch | Combined demo primary cloud | AWS as default, with provider choice | AWS has simplest VPC model. SE can choose others but default should work smoothly. | Yes — if Azure/GCP preferred |
| D003 | M001 | convention | Demo resource tagging | All demo resources tagged `demo=true` + `automation=github-actions` | Enables tag-based cleanup discovery. Already established pattern. | No |
| D004 | M001 | scope | Terraform state management | Local state with GitHub Actions cache | Production remote state is out of scope. Cache key includes workflow+provider+name for isolation. | Yes — if demo state conflicts arise |
| D005 | M001 | convention | Presentation approach | Step-by-step narration in logs + professional job summary | SEs run this live — logs ARE the demo, summary is the takeaway. Both matter. | No |
