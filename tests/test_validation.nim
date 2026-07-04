import std/unittest

import flowsurveyor

suite "validation":
  test "rejects invalid graph":
    var graph = initSurveyGraph("flow")
    graph.nodes.add(surveyNode("a"))
    graph.edges.add(surveyEdge("bad", "a", "missing"))

    expect ValueError:
      requireValid(graph)

  test "rejects invalid event":
    expect ValueError:
      requireValid(SurveyEvent())
