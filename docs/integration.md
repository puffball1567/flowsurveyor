# Integration

FlowSurveyor is intended to be embedded by FlowCaptain or other orchestration
tools.

## Recommended Boundary

Use `analyze` for adapter-driven integration:

```nim
import flowsurveyor

let input = initSurveyInput(graph, events)
let outcome = analyze(input)

if outcome.ok:
  handle(outcome.report)
else:
  reject(outcome.errors)
```

This boundary is intentionally small:

- callers provide a `SurveyGraph`
- callers provide observed `SurveyEvent` values
- FlowSurveyor validates required shape
- FlowSurveyor returns either a `SurveyReport` or validation errors

## Adapter Responsibility

Adapters from FlowDependency, FlowLogbook, runner logs, databases, or external
systems should map their native records into `SurveyGraph` and `SurveyEvent`.
FlowSurveyor should not depend directly on those packages in v0.2.0.

## Error Handling

`survey` may raise for invalid input. `analyze` is the integration-safe entry
point and returns errors as data.
