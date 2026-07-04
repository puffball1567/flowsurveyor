import std/unittest

import flowsurveyor

suite "aggregate":
  test "aggregates node durations and failures":
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekNodeFinished,
        nodeId = "a", status = fsSucceeded, durationMillis = 100),
      surveyEvent("e2", "test", "flow", "run", sekNodeFinished,
        nodeId = "a", status = fsFailed, durationMillis = 300)
    ]

    let stats = nodeStats(events)
    check stats.len == 1
    check stats[0].id == "a"
    check stats[0].count == 2
    check stats[0].successCount == 1
    check stats[0].failureCount == 1
    check stats[0].totalDurationMillis == 400
    check stats[0].averageDurationMillis == 200.0

  test "aggregates edge durations":
    let events = @[
      surveyEvent("e1", "test", "flow", "run", sekEdgeSatisfied,
        edgeId = "a-b", status = fsSucceeded, durationMillis = 20)
    ]

    let stats = edgeStats(events)
    check stats.len == 1
    check stats[0].id == "a-b"
    check stats[0].totalDurationMillis == 20
