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

  if report.criticalPath.edgeIds.len > 0:
    result.add(Recommendation(
      id: recommendationId(rkReviewCriticalPath, report.criticalPath.edgeIds[^1]),
      kind: rkReviewCriticalPath,
      targetId: report.criticalPath.edgeIds.join(" -> "),
      confidence: 0.75,
      reason: "critical path controls the minimum end-to-end flow duration"
    ))
