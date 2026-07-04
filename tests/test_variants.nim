import std/unittest

import flowsurveyor

suite "variants":
  test "compares variant duration and failures":
    let events = @[
      surveyEvent("a1", "test", "flow", "run-a", sekNodeFinished,
        variantId = "A", nodeId = "x", status = fsSucceeded, durationMillis = 100),
      surveyEvent("b1", "test", "flow", "run-b", sekNodeFinished,
        variantId = "B", nodeId = "x", status = fsFailed, durationMillis = 150),
      surveyEvent("b2", "test", "flow", "run-b", sekNodeFinished,
        variantId = "B", nodeId = "y", status = fsSucceeded, durationMillis = 50)
    ]

    let comparison = compareVariants("A", "B", events)
    check comparison.base.totalDurationMillis == 100
    check comparison.target.totalDurationMillis == 200
    check comparison.durationDeltaMillis == 100
    check comparison.failureDelta == 1
