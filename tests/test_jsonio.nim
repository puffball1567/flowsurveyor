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
      waitInsights: @[WaitInsight(edgeId: "a-b", fromNode: "a", toNode: "b",
        count: 1, totalWaitMillis: 20, averageWaitMillis: 20.0, reason: "wait")],
      parallelismOpportunities: @[ParallelismOpportunity(nodeId: "a",
        observedDurationMillis: 10, onCriticalPath: true, score: 15, reason: "split")],
      failureImpacts: @[FailureImpact(targetId: "a", kind: "node",
        failureCount: 1, retryCount: 2, failedDurationMillis: 30,
        retryDurationMillis: 30, score: 210, reason: "failure")],
      operationalSummary: OperationalSummary(executionCount: 2,
        succeededCount: 1, failedCount: 1, retryCount: 2,
        totalCycleTimeMillis: 40, totalObservedTimeMillis: 40,
        throughputPerHour: 90.0, failureRate: 50.0),
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
    check node["waitInsights"][0]["edgeId"].getStr() == "a-b"
    check node["parallelismOpportunities"][0]["nodeId"].getStr() == "a"
    check node["failureImpacts"][0]["retryCount"].getInt() == 2
    check node["operationalSummary"]["executionCount"].getInt() == 2
    check node["operationalSummary"]["failureRate"].getFloat() == 50.0
    check node["recommendations"][0]["kind"].getStr() == "rkIncreaseParallelism"
    check node["qualityIssues"][0]["kind"].getStr() == "eqikMissingDuration"
