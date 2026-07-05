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

  test "reports wait insights for blocked or waiting edges":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekEdgeWaiting,
        edgeId = "extract-transform", status = fsRunning, durationMillis = 40),
      surveyEvent("e2", "test", "flow", "run", sekEdgeBlocked,
        edgeId = "extract-transform", status = fsSkipped, durationMillis = 30)
    ]

    let insights = waitInsights(graph, events)
    check insights.len == 1
    check insights[0].edgeId == "extract-transform"
    check insights[0].fromNode == "extract"
    check insights[0].toNode == "transform"
    check insights[0].totalWaitMillis == 70
    check insights[0].blockedCount == 1

  test "reports parallelism opportunities from duration and critical path":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "transform", status = fsSucceeded, durationMillis = 500),
      surveyEvent("e2", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "extract-transform", status = fsSucceeded, durationMillis = 100),
      surveyEvent("e3", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "transform-publish", status = fsSucceeded, durationMillis = 200)
    ]

    let opportunities = parallelismOpportunities(graph, events)
    check opportunities.len > 0
    check opportunities[0].nodeId == "transform"
    check opportunities[0].onCriticalPath
    check opportunities[0].observedDurationMillis == 500

  test "reports failure and retry impact":
    let graph = sampleGraph()
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "transform", status = fsFailed, durationMillis = 250,
        metrics = [kv("retries", "2")]),
      surveyEvent("e2", "test", "flow", "run", sekNodeFinished,
        nodeId = "extract", status = fsSucceeded, durationMillis = 50)
    ]

    let impacts = failureImpacts(events)
    check impacts.len == 1
    check impacts[0].targetId == "transform"
    check impacts[0].failureCount == 1
    check impacts[0].retryCount == 2
    check impacts[0].failedDurationMillis == 250

    let report = survey(graph, events)
    check report.failureImpacts.len == 1
    check report.recommendations.len > 0
