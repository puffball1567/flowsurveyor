import std/json

import ./types

proc toJson*(value: KeyValue): JsonNode =
  %*{"key": value.key, "value": value.value}

proc toJson*(value: AggregateStats): JsonNode =
  %*{
    "id": value.id,
    "count": int(value.count),
    "successCount": int(value.successCount),
    "failureCount": int(value.failureCount),
    "totalDurationMillis": int(value.totalDurationMillis),
    "maxDurationMillis": int(value.maxDurationMillis),
    "averageDurationMillis": value.averageDurationMillis
  }

proc toJson*(value: CriticalPath): JsonNode =
  result = newJObject()
  result["nodeIds"] = newJArray()
  for item in value.nodeIds:
    result["nodeIds"].add(%item)
  result["edgeIds"] = newJArray()
  for item in value.edgeIds:
    result["edgeIds"].add(%item)
  result["totalDurationMillis"] = %int(value.totalDurationMillis)

proc toJson*(value: Bottleneck): JsonNode =
  %*{
    "id": value.id,
    "kind": value.kind,
    "score": value.score,
    "reason": value.reason
  }

proc toJson*(value: WaitInsight): JsonNode =
  %*{
    "edgeId": value.edgeId,
    "fromNode": value.fromNode,
    "toNode": value.toNode,
    "count": int(value.count),
    "blockedCount": int(value.blockedCount),
    "totalWaitMillis": int(value.totalWaitMillis),
    "averageWaitMillis": value.averageWaitMillis,
    "reason": value.reason
  }

proc toJson*(value: ParallelismOpportunity): JsonNode =
  %*{
    "nodeId": value.nodeId,
    "fanIn": int(value.fanIn),
    "fanOut": int(value.fanOut),
    "observedDurationMillis": int(value.observedDurationMillis),
    "onCriticalPath": value.onCriticalPath,
    "score": value.score,
    "reason": value.reason
  }

proc toJson*(value: FailureImpact): JsonNode =
  %*{
    "targetId": value.targetId,
    "kind": value.kind,
    "failureCount": int(value.failureCount),
    "retryCount": int(value.retryCount),
    "failedDurationMillis": int(value.failedDurationMillis),
    "retryDurationMillis": int(value.retryDurationMillis),
    "score": value.score,
    "reason": value.reason
  }


proc toJson*(value: OperationalSummary): JsonNode =
  %*{
    "executionCount": int(value.executionCount),
    "succeededCount": int(value.succeededCount),
    "failedCount": int(value.failedCount),
    "skippedCount": int(value.skippedCount),
    "retryCount": int(value.retryCount),
    "workUnits": value.workUnits,
    "acceptedUnits": value.acceptedUnits,
    "defectUnits": value.defectUnits,
    "totalCycleTimeMillis": int(value.totalCycleTimeMillis),
    "averageCycleTimeMillis": value.averageCycleTimeMillis,
    "totalWaitTimeMillis": int(value.totalWaitTimeMillis),
    "totalBlockedTimeMillis": int(value.totalBlockedTimeMillis),
    "totalObservedTimeMillis": int(value.totalObservedTimeMillis),
    "throughputPerHour": value.throughputPerHour,
    "failureRate": value.failureRate,
    "defectRate": value.defectRate,
    "retryRate": value.retryRate,
    "firstPassYield": value.firstPassYield
  }

proc toJson*(value: Recommendation): JsonNode =
  %*{
    "id": value.id,
    "kind": $value.kind,
    "targetId": value.targetId,
    "confidence": value.confidence,
    "reason": value.reason
  }

proc toJson*(value: EventQualityIssue): JsonNode =
  %*{
    "kind": $value.kind,
    "eventId": value.eventId,
    "targetId": value.targetId,
    "message": value.message
  }

proc toJson*(value: VariantSummary): JsonNode =
  %*{
    "variantId": value.variantId,
    "totalDurationMillis": int(value.totalDurationMillis),
    "failureCount": int(value.failureCount),
    "eventCount": int(value.eventCount)
  }

proc toJson*(value: VariantComparison): JsonNode =
  result = newJObject()
  result["baseVariant"] = %value.baseVariant
  result["targetVariant"] = %value.targetVariant
  result["base"] = toJson(value.base)
  result["target"] = toJson(value.target)
  result["durationDeltaMillis"] = %value.durationDeltaMillis
  result["failureDelta"] = %value.failureDelta
  result["summary"] = %value.summary
  result["improvements"] = newJArray()
  for item in value.improvements:
    result["improvements"].add(%item)
  result["regressions"] = newJArray()
  for item in value.regressions:
    result["regressions"].add(%item)

proc toJson*(value: SurveyReport): JsonNode =
  result = newJObject()
  result["schemaVersion"] = %int(value.schemaVersion)
  result["flowId"] = %value.flowId
  result["variantId"] = %value.variantId
  result["nodeStats"] = newJArray()
  for item in value.nodeStats:
    result["nodeStats"].add(toJson(item))
  result["edgeStats"] = newJArray()
  for item in value.edgeStats:
    result["edgeStats"].add(toJson(item))
  result["criticalPath"] = toJson(value.criticalPath)
  result["bottlenecks"] = newJArray()
  for item in value.bottlenecks:
    result["bottlenecks"].add(toJson(item))
  result["waitInsights"] = newJArray()
  for item in value.waitInsights:
    result["waitInsights"].add(toJson(item))
  result["parallelismOpportunities"] = newJArray()
  for item in value.parallelismOpportunities:
    result["parallelismOpportunities"].add(toJson(item))
  result["failureImpacts"] = newJArray()
  for item in value.failureImpacts:
    result["failureImpacts"].add(toJson(item))
  result["operationalSummary"] = toJson(value.operationalSummary)
  result["recommendations"] = newJArray()
  for item in value.recommendations:
    result["recommendations"].add(toJson(item))
  result["qualityIssues"] = newJArray()
  for item in value.qualityIssues:
    result["qualityIssues"].add(toJson(item))

proc toJsonString*(value: SurveyReport): string =
  $toJson(value)

proc toJsonString*(value: VariantComparison): string =
  $toJson(value)
