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
