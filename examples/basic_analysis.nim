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
    edgeId = "extract-transform", status = fsSucceeded, durationMillis = 20),
  surveyEvent("e3", "runner", "daily-report", "run-1", sekNodeFinished,
    nodeId = "transform", status = fsSucceeded, durationMillis = 300),
  surveyEvent("e4", "runner", "daily-report", "run-1", sekEdgeSatisfied,
    edgeId = "transform-publish", status = fsSucceeded, durationMillis = 40),
  surveyEvent("e5", "runner", "daily-report", "run-1", sekNodeFinished,
    nodeId = "publish", status = fsSucceeded, durationMillis = 80)
]

let report = survey(graph, events)
doAssert report.criticalPath.edgeIds == @["extract-transform", "transform-publish"]
doAssert report.bottlenecks[0].id == "transform"

echo report.toJsonString()
