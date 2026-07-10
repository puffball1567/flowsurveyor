# FlowSurveyor

FlowSurveyor is a small Nim library for analyzing flow graphs and observed flow
events.

It is part of the **FlowBrigade Toolkit**.

## Status

FlowSurveyor v0.3.0 is focused on offline flow analysis. Within that scope,
the current version provides:

- graph and event analysis primitives
- node and edge duration aggregation
- success/failure aggregation
- critical path analysis from observed edge durations
- bottleneck ranking
- wait and blocked-edge insights
- parallelism opportunity ranking
- failure and retry impact analysis
- operational summary metrics for cycle time, wait/blocking time, throughput,
  failure rate, defect rate, retry rate, and first-pass yield
- improvement recommendations
- event quality checks
- variant duration/failure comparison with improvement/regression notes
- JSON report export
- examples, tests, design notes, and benchmarks

## v0.3.0 Scope

The v0.3.0 scope is intentionally narrow and complete:

- accept an in-memory `SurveyGraph` and observed `SurveyEvent` values
- aggregate node and edge duration, success, and failure statistics
- compute the observed critical path for directed acyclic graphs
- rank bottlenecks by duration and failure impact
- report edge wait time and blocked handoffs
- rank nodes that may benefit from splitting or parallelism
- report failure and retry impact from observed events
- summarize operational indicators such as throughput, cycle time, defect rate,
  retry rate, and first-pass yield
- emit rule-based improvement recommendations
- detect basic event quality issues before trusting a report
- compare variants by observed duration, failures, and event count
- describe variant improvements and regressions
- export a JSON report with `schemaVersion = 1`

Recommendations are explainable rule-based hints. They are not an automatic
optimizer, planner, scheduler, or AI decision engine.

## Out Of Scope

FlowSurveyor analyzes evidence. It does not execute tasks, persist records,
collect events from external systems, or render dashboards.

Those responsibilities belong to other FlowBrigade Toolkit components:

- FlowDependency models graph structure.
- FlowLogbook records runs and flow events.
- FlowGarage will store reports and generated artifacts.
- FlowCaptain will coordinate components.

## Example

```nim
import flowsurveyor

var graph = initSurveyGraph("daily-report")
graph.nodes.add(surveyNode("extract", "Extract"))
graph.nodes.add(surveyNode("transform", "Transform"))
graph.nodes.add(surveyNode("publish", "Publish"))
graph.edges.add(surveyEdge("extract-transform", "extract", "transform"))
graph.edges.add(surveyEdge("transform-publish", "transform", "publish"))

let events = @[
  surveyEvent("e1", "runner", "daily-report", "run-1", sekNodeFinished,
    nodeId = "extract", status = fsSucceeded, durationMillis = 100),
  surveyEvent("e2", "runner", "daily-report", "run-1", sekEdgeSatisfied,
    edgeId = "extract-transform", status = fsSucceeded, durationMillis = 20)
]

let report = survey(graph, events)
echo report.toJsonString()
```

The report includes structured fields for:

- `criticalPath`
- `bottlenecks`
- `waitInsights`
- `parallelismOpportunities`
- `failureImpacts`
- `operationalSummary`
- `recommendations`

Variant comparison can be computed from events that carry `variantId`:

```nim
let comparison = compareVariants("A", "B", events)
```

Event quality checks report mismatches between graph structure and observed
events:

```nim
let issues = eventQualityIssues(graph, events)
```

For component integration, use `analyze` when the caller should receive
validation errors instead of catching exceptions:

```nim
let outcome = analyze(graph, events)
if outcome.ok:
  echo outcome.report.toJsonString()
else:
  echo outcome.errors
```

## Requirements

FlowSurveyor only depends on Nim's standard library.

## Public API

The public API is exported from `import flowsurveyor`:

- graph and event types from `types`
- aggregation helpers from `aggregate`
- analysis helpers from `analysis`
- integration-safe analysis helpers from `integration`
- event validation and quality checks from `validation` and `quality`
- recommendation helpers from `recommendations`
- variant comparison helpers from `variants`
- JSON export helpers from `jsonio`

## Development

```bash
nimble test
nimble examples
nimble bench
```

## Intellectual Property Notes

FlowSurveyor intentionally uses general, well-known analysis concepts:
aggregation, duration totals, failure counts, ranking, and longest-path style
critical path analysis over a directed acyclic graph. Recommendations are simple
rule-based hints derived from bottleneck and failure aggregates.

It does not copy code, query languages, dashboards, or internal behavior from
workflow systems or observability products.

See [docs/ip-notes.md](docs/ip-notes.md).
