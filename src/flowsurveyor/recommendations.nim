import std/strutils

import ./types

proc recommendationId(kind: RecommendationKind; targetId: string): string =
  $kind & ":" & targetId

proc recommendations*(report: SurveyReport): seq[Recommendation] =
  for item in report.bottlenecks:
    if item.kind == "node":
      result.add(Recommendation(
        id: recommendationId(rkIncreaseParallelism, item.id),
        kind: rkIncreaseParallelism,
        targetId: item.id,
        confidence: min(1.0, item.score / 1000.0),
        reason: "node ranks high in bottleneck score; consider parallelism or splitting work"
      ))
    else:
      result.add(Recommendation(
        id: recommendationId(rkReduceWait, item.id),
        kind: rkReduceWait,
        targetId: item.id,
        confidence: min(1.0, item.score / 1000.0),
        reason: "edge ranks high in bottleneck score; inspect wait time or handoff cost"
      ))

  for item in report.nodeStats:
    if item.failureCount > 0:
      result.add(Recommendation(
        id: recommendationId(rkInvestigateFailures, item.id),
        kind: rkInvestigateFailures,
        targetId: item.id,
        confidence: min(1.0, item.failureCount.float / max(1.0, item.count.float)),
        reason: "node has failed events; retry cost may be hurting total flow time"
      ))

  for item in report.waitInsights:
    if item.totalWaitMillis > 0 or item.blockedCount > 0:
      result.add(Recommendation(
        id: recommendationId(rkReduceWait, item.edgeId),
        kind: rkReduceWait,
        targetId: item.edgeId,
        confidence: min(1.0, item.totalWaitMillis.float / 1000.0),
        reason: "edge has observed wait or blocked events; inspect handoff, queueing, or dependency timing"
      ))

  for item in report.parallelismOpportunities:
    if item.onCriticalPath or item.fanOut > 1:
      result.add(Recommendation(
        id: recommendationId(rkIncreaseParallelism, item.nodeId),
        kind: rkIncreaseParallelism,
        targetId: item.nodeId,
        confidence: min(1.0, item.score / 1000.0),
        reason: "node is a candidate for splitting or parallelizing based on duration, fan-out, and critical path position"
      ))

  for item in report.failureImpacts:
    if item.failureCount > 0 or item.retryCount > 0:
      result.add(Recommendation(
        id: recommendationId(rkInvestigateFailures, item.targetId),
        kind: rkInvestigateFailures,
        targetId: item.targetId,
        confidence: min(1.0, item.score / 1000.0),
        reason: "target has observed failure or retry impact; reduce error rate before optimizing throughput"
      ))

  if report.criticalPath.edgeIds.len > 0:
    result.add(Recommendation(
      id: recommendationId(rkReviewCriticalPath, report.criticalPath.edgeIds[^1]),
      kind: rkReviewCriticalPath,
      targetId: report.criticalPath.edgeIds.join(" -> "),
      confidence: 0.75,
      reason: "critical path controls the minimum end-to-end flow duration"
    ))
