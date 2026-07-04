import std/strutils
import std/unittest

import flowsurveyor

proc integrationGraph(): SurveyGraph =
  result = initSurveyGraph("flow")
  result.nodes.add(surveyNode("extract"))
  result.nodes.add(surveyNode("publish"))
  result.edges.add(surveyEdge("extract-publish", "extract", "publish"))

suite "integration":
  test "analyze returns report without forcing callers to catch exceptions":
    let graph = integrationGraph()
    let events = @[
      surveyEvent("e1", "adapter", "flow", "run-1", sekNodeFinished,
        nodeId = "extract", status = fsSucceeded, durationMillis = 10),
      surveyEvent("e2", "adapter", "flow", "run-1", sekEdgeSatisfied,
        edgeId = "extract-publish", status = fsSucceeded, durationMillis = 5)
    ]

    let outcome = analyze(graph, events)

    check outcome.ok
    check outcome.errors.len == 0
    check outcome.report.schemaVersion == ReportSchemaVersion
    check outcome.report.flowId == "flow"

  test "analyze reports validation errors instead of raising":
    let graph = initSurveyGraph("")
    let events = @[
      surveyEvent("", "adapter", "", "", sekNodeFinished,
        nodeId = "missing", status = fsSucceeded, durationMillis = 10)
    ]

    let outcome = analyze(graph, events)

    check not outcome.ok
    check outcome.errors.len >= 4
    check outcome.errors[0].startsWith("graph:")
