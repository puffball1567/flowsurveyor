import std/unittest
import flowsurveyor

suite "memory model":
  test "uses Nim ARC memory manager":
    when defined(gcArc):
      check true
    else:
      check false

  test "creates and releases survey graphs and events under ARC":
    var totalEvents = 0
    for i in 0 ..< 200:
      var graph = initSurveyGraph("survey-" & $i, variantId = "A")
      graph.nodes.add surveyNode("extract-" & $i, metadata = [kv("owner", "etl")])
      graph.nodes.add surveyNode("load-" & $i, metadata = [kv("owner", "etl")])
      graph.edges.add surveyEdge("edge-" & $i, graph.nodes[0].id, graph.nodes[1].id, expectedDurationMillis = Natural(i))
      let event = surveyEvent(
        "event-" & $i, "memory-test", graph.id, "run", sekNodeFinished,
        nodeId = graph.nodes[1].id,
        status = fsSucceeded,
        durationMillis = Natural(i),
        metrics = [kv("work_units", "1")]
      )
      totalEvents += ord(event.kind == sekNodeFinished)
    check totalEvents == 200
