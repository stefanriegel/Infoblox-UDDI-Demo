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
| D006 | M001/S02 | convention | Summary heredoc pattern | HEADER (literal, no expansion) + EOF (interpolated, with expansion) + FOOTER (literal) heredoc blocks | Mixing literal and interpolated heredocs avoids the single-quote expansion bug that caused VPC empty tables. Static markdown (badges, Mermaid, footer) in literal blocks, dynamic data in interpolated blocks. | Yes |
| D007 | M001/S02 | convention | Mermaid diagram color palette | UDDI #0066cc, AWS #FF9900, Azure #0078D4, GCP #4285F4, Verification #7B1FA2, Delete #dc3545 | Each cloud uses its official brand color. UDDI uses Infoblox blue. Verification uses purple to stand out. Delete uses red for danger/destructive actions. Consistent across all workflow summaries. | Yes |
