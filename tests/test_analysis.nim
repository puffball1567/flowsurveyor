import std/unittest

import flowsurveyor

proc sampleGraph(): SurveyGraph =
  result = initSurveyGraph("flow")
  result.nodes.add(surveyNode("extract"))
  result.nodes.add(surveyNode("transform"))
  result.nodes.add(surveyNode("publish"))
  result.edges.add(surveyEdge("extract-transform", "extract", "transform"))
  result.edges.add(surveyEdge("transform-publish", "transform", "publish"))

suite "analysis":
  test "computes critical path from observed edge durations":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "extract-transform", status = fsSucceeded, durationMillis = 50),
      surveyEvent("e2", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "transform-publish", status = fsSucceeded, durationMillis = 70)
    ]

    let path = criticalPath(graph, events)
    check path.nodeIds == @["extract", "transform", "publish"]
    check path.edgeIds == @["extract-transform", "transform-publish"]
    check path.totalDurationMillis == 120

  test "ranks bottlenecks by duration and failures":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "extract", status = fsSucceeded, durationMillis = 100),
      surveyEvent("e2", "test", "flow", "run", sekNodeFinished,
        nodeId = "transform", status = fsFailed, durationMillis = 200),
      surveyEvent("e3", "test", "flow", "run", sekNodeFinished,
        nodeId = "transform", status = fsSucceeded, durationMillis = 200)
    ]

    let ranked = bottlenecks(graph, events)
    check ranked[0].id == "transform"
    check ranked[0].kind == "node"

  test "survey returns complete report":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "extract", status = fsSucceeded, durationMillis = 100),
      surveyEvent("e2", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "extract-transform", status = fsSucceeded, durationMillis = 30)
    ]

    let report = survey(graph, events)
    check report.schemaVersion == ReportSchemaVersion
    check report.flowId == "flow"
    check report.nodeStats.len == 1
    check report.edgeStats.len == 1
    check report.bottlenecks.len > 0
