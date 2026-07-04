import std/unittest

import flowsurveyor

suite "quality":
  test "reports missing graph references and duplicate ids":
    var graph = initSurveyGraph("flow")
    graph.nodes.add(surveyNode("a"))

    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "missing", status = fsSucceeded, durationMillis = 10),
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "a", status = fsSucceeded, durationMillis = 0)
    ]

    let issues = eventQualityIssues(graph, events)
    check issues.len == 3
    check issues[0].kind == eqikMissingGraphNode
    check issues[1].kind == eqikDuplicateEventId
    check issues[2].kind == eqikMissingDuration
