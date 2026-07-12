import flowsurveyor

proc main() =
  var totalReports = 0
  for i in 0 ..< 1000:
    var graph = initSurveyGraph("survey-" & $i, variantId = "A")
    graph.nodes.add surveyNode("extract-" & $i, metadata = [kv("owner", "etl")])
    graph.nodes.add surveyNode("load-" & $i, metadata = [kv("owner", "etl")])
    graph.edges.add surveyEdge("edge-" & $i, graph.nodes[0].id, graph.nodes[1].id, expectedDurationMillis = Natural(i + 1))

    let events = @[
      surveyEvent("start-" & $i, "leak-probe", graph.id, "run", sekNodeStarted, nodeId = graph.nodes[0].id, status = fsRunning),
      surveyEvent("finish-" & $i, "leak-probe", graph.id, "run", sekNodeFinished, nodeId = graph.nodes[1].id, status = fsSucceeded, durationMillis = Natural(i + 1), metrics = [kv("work_units", "1")])
    ]
    discard analyze(graph, events)
    inc totalReports

  doAssert totalReports == 1000

main()
