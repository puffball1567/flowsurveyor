import std/tables

import ./types
import ./validation

proc update(stats: var AggregateStats; event: SurveyEvent) =
  stats.count.inc
  if event.status == fsSucceeded or event.status == fsSkipped:
    stats.successCount.inc
  elif event.status == fsFailed:
    stats.failureCount.inc
  stats.totalDurationMillis += event.durationMillis
  if event.durationMillis > stats.maxDurationMillis:
    stats.maxDurationMillis = event.durationMillis
  if stats.count > 0:
    stats.averageDurationMillis = stats.totalDurationMillis.float / stats.count.float

proc nodeStats*(events: openArray[SurveyEvent]): seq[AggregateStats] =
  var table = initOrderedTable[string, AggregateStats]()
  for event in events:
    requireValid(event)
    if event.nodeId.len == 0:
      continue
    if not table.hasKey(event.nodeId):
      table[event.nodeId] = AggregateStats(id: event.nodeId)
    table[event.nodeId].update(event)
  for _, value in table:
    result.add(value)

proc edgeStats*(events: openArray[SurveyEvent]): seq[AggregateStats] =
  var table = initOrderedTable[string, AggregateStats]()
  for event in events:
    requireValid(event)
    if event.edgeId.len == 0:
      continue
    if not table.hasKey(event.edgeId):
      table[event.edgeId] = AggregateStats(id: event.edgeId)
    table[event.edgeId].update(event)
  for _, value in table:
    result.add(value)

proc statsById*(stats: openArray[AggregateStats]): Table[string, AggregateStats] =
  result = initTable[string, AggregateStats]()
  for item in stats:
    result[item.id] = item
