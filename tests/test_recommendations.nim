import std/unittest

import flowsurveyor

suite "recommendations":
  test "survey includes improvement recommendations":
    var graph = initSurveyGraph("flow")
    graph.nodes.add(surveyNode("a"))

    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "a", status = fsFailed, durationMillis = 300),
      surveyEvent("e2", "test", "flow", "run", sekNodeFinished,
        nodeId = "a", status = fsSucceeded, durationMillis = 300)
    ]

    let report = survey(graph, events)
    check report.recommendations.len >= 2
    check report.recommendations[0].targetId == "a"
