# Design

FlowSurveyor analyzes flow structure and observed evidence.

## Goals

- Aggregate node and edge durations.
- Count successes and failures.
- Compute critical paths from observed edge durations.
- Rank likely bottlenecks.
- Report observed wait time and blocked handoffs.
- Rank parallelism or split-work opportunities.
- Report failure and retry impact.
- Suggest simple improvement actions from bottlenecks and failures.
- Compare variants from observed event totals and describe improvements or
  regressions.
- Check event quality against graph structure.
- Produce machine-readable reports.
- Stay independent from specific runners, loggers, databases, or web frameworks.

## v0.2.0 Completion Scope

The first release is complete when FlowSurveyor can take a graph and observed
events, produce explainable analysis, export a versioned report, and verify the
behavior with tests, examples, and a benchmark.

The v0.2.0 release does not promise data collection, persistent storage,
execution, dashboards, or automatic optimization. Those are separate
responsibilities in the FlowBrigade Toolkit.

## Non-goals

- Running tasks
- Persisting event history
- Collecting telemetry from external systems
- Rendering dashboards
- Modifying graph definitions
- Replacing FlowDependency or FlowLogbook

## Core Model

```text
SurveyGraph + SurveyEvent[] -> SurveyReport
```

FlowSurveyor uses small local types instead of importing FlowDependency or
FlowLogbook directly. This keeps the package dependency-free and allows adapters
to map from multiple sources.

## Integration Boundary

FlowCaptain and other higher-level tools should prefer `analyze` over direct
`survey` calls when they are connecting adapters. `analyze` returns a
`SurveyOutcome` with `ok`, `report`, and `errors`, so integration code can
reject bad input without relying on exception control flow.

Direct `survey` calls remain available for simple local usage and tests.

## Report

`SurveyReport` contains:

- schema version
- node stats
- edge stats
- critical path
- bottleneck ranking
- wait insights
- parallelism opportunities
- failure impacts
- improvement recommendations
- event quality issues

`schemaVersion` is currently `1`. Consumers should read it before assuming a
report shape. Future report changes that alter machine-readable semantics should
increase this value.

The current bottleneck score is intentionally simple:

```text
total duration + failure count * average duration
```

This keeps the first version explainable. More scoring models can be added
later without changing the input model.

Wait insights are derived from edge waiting and blocked events. Parallelism
opportunities are ranked from observed node duration, fan-in, fan-out, and
critical-path membership. Failure impacts are ranked from failed duration,
failure count, retry count, and retry-marked duration.

## Recommendations

Recommendations are deliberately rule-based in the first version. They are not
an optimizer and do not mutate the graph. They identify targets worth reviewing:

- high-scoring nodes may need parallelism or smaller work units,
- high-scoring edges may need wait or handoff reduction,
- failed nodes may need reliability investigation,
- repeated retries should be investigated before throughput optimization,
- critical-path edges should be reviewed first because they bound end-to-end
  duration.

## Event Quality

Quality checks report missing graph nodes, missing graph edges, duplicate event
ids, missing durations, and unknown statuses. These checks help adapters detect
bad telemetry before the report is trusted.

## Variants

Variant comparison summarizes observed event count, duration, failures,
improvements, and regressions per variant. FlowSurveyor does not choose a
winner by itself; callers can combine the comparison with domain-specific cost
or reliability rules.

## Relationship To Other Components

FlowDependency owns graph modeling. FlowLogbook owns execution/event records.
FlowSurveyor consumes equivalent graph and event data to produce analysis.

FlowCaptain can connect these components through adapters and use FlowSurveyor
as the analysis provider for generated reports.
