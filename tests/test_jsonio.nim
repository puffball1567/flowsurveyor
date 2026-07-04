import std/json
import std/unittest

import flowsurveyor

suite "json io":
  test "serializes report to json":
    let report = SurveyReport(
      schemaVersion: ReportSchemaVersion,
      flowId: "flow",
      nodeStats: @[AggregateStats(id: "a", count: 1, totalDurationMillis: 10)],
      criticalPath: CriticalPath(nodeIds: @["a"], totalDurationMillis: 10),
      bottlenecks: @[Bottleneck(id: "a", kind: "node", score: 10, reason: "slow")],
      recommendations: @[Recommendation(
        id: "r1",
        kind: rkIncreaseParallelism,
        targetId: "a",
        confidence: 0.5,
        reason: "split work"
      )],
      qualityIssues: @[EventQualityIssue(
        kind: eqikMissingDuration,
        eventId: "e1",
        targetId: "a",
        message: "missing duration"
      )]
    )

    let node = parseJson(report.toJsonString())
    check node["schemaVersion"].getInt() == ReportSchemaVersion
    check node["flowId"].getStr() == "flow"
    check node["nodeStats"][0]["id"].getStr() == "a"
    check node["criticalPath"]["totalDurationMillis"].getInt() == 10
    check node["bottlenecks"][0]["kind"].getStr() == "node"
    check node["recommendations"][0]["kind"].getStr() == "rkIncreaseParallelism"
    check node["qualityIssues"][0]["kind"].getStr() == "eqikMissingDuration"
