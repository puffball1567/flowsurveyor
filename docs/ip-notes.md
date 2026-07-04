# IP Notes

FlowSurveyor is designed around public, general software engineering concepts:

- event aggregation
- duration totals and averages
- success/failure counts
- bottleneck ranking
- rule-based improvement hints
- telemetry quality checks
- variant duration and failure comparison
- longest-path style critical path analysis in a directed acyclic graph
- JSON report export

The implementation is intentionally original and small. It does not copy code,
data structures, query languages, dashboards, or internal behavior from
workflow engines or observability systems.

If a credible concern is raised, the maintainers should review the affected
feature, document the finding, and remove or redesign the feature if needed.
