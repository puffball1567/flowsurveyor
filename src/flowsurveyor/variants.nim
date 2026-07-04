import ./types
import ./validation

proc variantSummary*(variantId: string;
    events: openArray[SurveyEvent]): VariantSummary =
  result.variantId = variantId
  for event in events:
    requireValid(event)
    if event.variantId != variantId:
      continue
    result.eventCount.inc
    result.totalDurationMillis += event.durationMillis
    if event.status == fsFailed:
      result.failureCount.inc

proc compareVariants*(baseVariant, targetVariant: string;
    events: openArray[SurveyEvent]): VariantComparison =
  let base = variantSummary(baseVariant, events)
  let target = variantSummary(targetVariant, events)
  VariantComparison(
    baseVariant: baseVariant,
    targetVariant: targetVariant,
    base: base,
    target: target,
    durationDeltaMillis: int(target.totalDurationMillis) - int(base.totalDurationMillis),
    failureDelta: int(target.failureCount) - int(base.failureCount)
  )
