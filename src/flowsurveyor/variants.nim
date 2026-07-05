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
  let durationDelta = int(target.totalDurationMillis) - int(base.totalDurationMillis)
  let failureDelta = int(target.failureCount) - int(base.failureCount)
  var improvements: seq[string] = @[]
  var regressions: seq[string] = @[]

  if durationDelta < 0:
    improvements.add("target variant reduced observed duration by " & $(-durationDelta) & "ms")
  elif durationDelta > 0:
    regressions.add("target variant increased observed duration by " & $durationDelta & "ms")

  if failureDelta < 0:
    improvements.add("target variant reduced failures by " & $(-failureDelta))
  elif failureDelta > 0:
    regressions.add("target variant increased failures by " & $failureDelta)

  let summary =
    if improvements.len == 0 and regressions.len == 0:
      "no observed duration or failure change"
    elif regressions.len == 0:
      "target variant improved observed flow metrics"
    elif improvements.len == 0:
      "target variant regressed observed flow metrics"
    else:
      "target variant has mixed observed flow changes"

  VariantComparison(
    baseVariant: baseVariant,
    targetVariant: targetVariant,
    base: base,
    target: target,
    durationDeltaMillis: durationDelta,
    failureDelta: failureDelta,
    summary: summary,
    improvements: improvements,
    regressions: regressions
  )
