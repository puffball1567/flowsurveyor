import std/algorithm
import std/strutils
import std/tables

import ./aggregate
import ./quality
import ./recommendations
import ./types
import ./validation

proc outgoingEdges(graph: SurveyGraph; nodeId: string): seq[SurveyEdge] =
  for edge in graph.edges:
    if edge.fromNode == nodeId:
      result.add(edge)

proc topologicalOrder(graph: SurveyGraph): seq[string] =
  requireValid(graph)
  var indegree = initTable[string, int]()
  for node in graph.nodes:
    indegree[node.id] = 0
  for edge in graph.edges:
    indegree[edge.toNode] = indegree.getOrDefault(edge.toNode) + 1

  var ready: seq[string]
  for node in graph.nodes:
    if indegree[node.id] == 0:
      ready.add(node.id)

  while ready.len > 0:
    let nodeId = ready[0]
    ready.delete(0)
    result.add(nodeId)
    for edge in graph.outgoingEdges(nodeId):
      indegree[edge.toNode] = indegree[edge.toNode] - 1
      if indegree[edge.toNode] == 0:
        ready.add(edge.toNode)

  if result.len != graph.nodes.len:
    raise newException(ValueError, "cycle detected")

proc observedDuration(edge: SurveyEdge; edgeStats: Table[string, AggregateStats]): Natural =
  if edgeStats.hasKey(edge.id) and edgeStats[edge.id].averageDurationMillis > 0:
    return Natural(edgeStats[edge.id].averageDurationMillis)
  if edge.expectedDurationMillis > 0:
    return edge.expectedDurationMillis
  Natural(edge.weight)

proc criticalPath*(graph: SurveyGraph; events: openArray[SurveyEvent]): CriticalPath =
  requireValid(graph)
  let order = graph.topologicalOrder()
  let edgeTable = statsById(edgeStats(events))

  var best = initTable[string, Natural]()
  var previousNode = initTable[string, string]()
  var previousEdge = initTable[string, string]()

  for nodeId in order:
    if not best.hasKey(nodeId):
      best[nodeId] = 0
    for edge in graph.outgoingEdges(nodeId):
      let candidate = best[nodeId] + edge.observedDuration(edgeTable)
      if candidate > best.getOrDefault(edge.toNode, 0):
        best[edge.toNode] = candidate
        previousNode[edge.toNode] = nodeId
        previousEdge[edge.toNode] = edge.id

  var endNode = ""
  var total: Natural = 0
  for nodeId, value in best:
    if value >= total:
      total = value
      endNode = nodeId

  if endNode.len == 0:
    return CriticalPath()

  var reverseNodes = @[endNode]
  var reverseEdges: seq[string]
  var current = endNode
  while previousNode.hasKey(current):
    reverseEdges.add(previousEdge[current])
    current = previousNode[current]
    reverseNodes.add(current)

  for i in countdown(reverseNodes.high, 0):
    result.nodeIds.add(reverseNodes[i])
  for i in countdown(reverseEdges.high, 0):
    result.edgeIds.add(reverseEdges[i])
  result.totalDurationMillis = total

proc bottlenecks*(graph: SurveyGraph; events: openArray[SurveyEvent];
    limit = 5): seq[Bottleneck] =
  let nodes = nodeStats(events)
  let edges = edgeStats(events)
  for item in nodes:
    let failurePenalty = item.failureCount.float * item.averageDurationMillis
    let score = item.totalDurationMillis.float + failurePenalty
    if score > 0:
      result.add(Bottleneck(
        id: item.id,
        kind: "node",
        score: score,
        reason: "duration=" & $item.totalDurationMillis & "ms failures=" & $item.failureCount
      ))
  for item in edges:
    let failurePenalty = item.failureCount.float * item.averageDurationMillis
    let score = item.totalDurationMillis.float + failurePenalty
    if score > 0:
      result.add(Bottleneck(
        id: item.id,
        kind: "edge",
        score: score,
        reason: "duration=" & $item.totalDurationMillis & "ms failures=" & $item.failureCount
      ))

  result.sort(proc(a, b: Bottleneck): int =
    if a.score < b.score: 1
    elif a.score > b.score: -1
    else: cmp(a.id, b.id)
  )
  if result.len > limit:
    result.setLen(limit)

proc retryCount(event: SurveyEvent): Natural =
  for metric in event.metrics:
    if metric.key == "retries" or metric.key == "retryCount":
      try:
        return Natural(parseInt(metric.value))
      except ValueError:
        return 0
  0

proc edgeById(graph: SurveyGraph): Table[string, SurveyEdge] =
  result = initTable[string, SurveyEdge]()
  for edge in graph.edges:
    result[edge.id] = edge

proc nodeStatsById(events: openArray[SurveyEvent]): Table[string, AggregateStats] =
  statsById(nodeStats(events))

proc graphDegrees(graph: SurveyGraph): tuple[fanIn, fanOut: Table[string, Natural]] =
  result.fanIn = initTable[string, Natural]()
  result.fanOut = initTable[string, Natural]()
  for node in graph.nodes:
    result.fanIn[node.id] = 0
    result.fanOut[node.id] = 0
  for edge in graph.edges:
    result.fanOut[edge.fromNode] = result.fanOut.getOrDefault(edge.fromNode, 0) + 1
    result.fanIn[edge.toNode] = result.fanIn.getOrDefault(edge.toNode, 0) + 1

proc waitInsights*(graph: SurveyGraph; events: openArray[SurveyEvent];
    limit = 5): seq[WaitInsight] =
  requireValid(graph)
  let edges = graph.edgeById()
  var table = initTable[string, WaitInsight]()
  for event in events:
    requireValid(event)
    if event.edgeId.len == 0:
      continue
    if event.kind != sekEdgeWaiting and event.kind != sekEdgeBlocked:
      continue
    if not table.hasKey(event.edgeId):
      let edge = edges.getOrDefault(event.edgeId)
      table[event.edgeId] = WaitInsight(
        edgeId: event.edgeId,
        fromNode: edge.fromNode,
        toNode: edge.toNode
      )
    table[event.edgeId].count.inc
    table[event.edgeId].totalWaitMillis += event.durationMillis
    if event.kind == sekEdgeBlocked or event.status == fsFailed or event.status == fsSkipped:
      table[event.edgeId].blockedCount.inc

  for _, item in table:
    var insight = item
    if insight.count > 0:
      insight.averageWaitMillis =
        insight.totalWaitMillis.float / insight.count.float
    insight.reason = "wait=" & $insight.totalWaitMillis & "ms blocked=" &
      $insight.blockedCount
    result.add(insight)

  result.sort(proc(a, b: WaitInsight): int =
    let left = a.totalWaitMillis.float + a.blockedCount.float * max(1.0, a.averageWaitMillis)
    let right = b.totalWaitMillis.float + b.blockedCount.float * max(1.0, b.averageWaitMillis)
    if left < right: 1
    elif left > right: -1
    else: cmp(a.edgeId, b.edgeId)
  )
  if result.len > limit:
    result.setLen(limit)

proc parallelismOpportunities*(graph: SurveyGraph; events: openArray[SurveyEvent];
    limit = 5): seq[ParallelismOpportunity] =
  requireValid(graph)
  let stats = nodeStatsById(events)
  let degrees = graph.graphDegrees()
  let critical = criticalPath(graph, events)
  for node in graph.nodes:
    let item = stats.getOrDefault(node.id)
    let fanIn = degrees.fanIn.getOrDefault(node.id, 0)
    let fanOut = degrees.fanOut.getOrDefault(node.id, 0)
    let onCritical = node.id in critical.nodeIds
    let duration = item.totalDurationMillis
    if duration == 0:
      continue
    var score = duration.float
    if onCritical:
      score = score * 1.5
    if fanOut > 1:
      score = score * 1.25
    if fanIn > 1:
      score = score * 1.1
    if score <= 0:
      continue

    var reason = "duration=" & $duration & "ms"
    if onCritical:
      reason.add(" criticalPath=true")
    if fanOut > 1:
      reason.add(" fanOut=" & $fanOut)
    if fanIn > 1:
      reason.add(" fanIn=" & $fanIn)

    result.add(ParallelismOpportunity(
      nodeId: node.id,
      fanIn: fanIn,
      fanOut: fanOut,
      observedDurationMillis: duration,
      onCriticalPath: onCritical,
      score: score,
      reason: reason
    ))

  result.sort(proc(a, b: ParallelismOpportunity): int =
    if a.score < b.score: 1
    elif a.score > b.score: -1
    else: cmp(a.nodeId, b.nodeId)
  )
  if result.len > limit:
    result.setLen(limit)

proc failureImpacts*(events: openArray[SurveyEvent]; limit = 5): seq[FailureImpact] =
  var table = initTable[string, FailureImpact]()
  for event in events:
    requireValid(event)
    let targetId =
      if event.nodeId.len > 0: event.nodeId
      elif event.edgeId.len > 0: event.edgeId
      else: ""
    if targetId.len == 0:
      continue
    let kind = if event.nodeId.len > 0: "node" else: "edge"
    if not table.hasKey(targetId):
      table[targetId] = FailureImpact(targetId: targetId, kind: kind)

    let retries = event.retryCount()
    table[targetId].retryCount += retries
    if retries > 0:
      table[targetId].retryDurationMillis += event.durationMillis
    if event.status == fsFailed:
      table[targetId].failureCount.inc
      table[targetId].failedDurationMillis += event.durationMillis

  for _, item in table:
    if item.failureCount == 0 and item.retryCount == 0:
      continue
    var impact = item
    impact.score = impact.failedDurationMillis.float +
      impact.retryDurationMillis.float + impact.failureCount.float * 100.0 +
      impact.retryCount.float * 25.0
    impact.reason = "failures=" & $impact.failureCount & " retries=" &
      $impact.retryCount & " failedDuration=" & $impact.failedDurationMillis &
      "ms retryDuration=" & $impact.retryDurationMillis & "ms"
    result.add(impact)

  result.sort(proc(a, b: FailureImpact): int =
    if a.score < b.score: 1
    elif a.score > b.score: -1
    else: cmp(a.targetId, b.targetId)
  )
  if result.len > limit:
    result.setLen(limit)


proc metricNumber(event: SurveyEvent; names: openArray[string]): float =
  for metric in event.metrics:
    let key = metric.key.strip().toLowerAscii()
    for name in names:
      if key == name:
        try:
          let value = parseFloat(metric.value.strip())
          if value >= 0.0:
            return value
        except ValueError:
          discard
  0.0

proc metricNatural(event: SurveyEvent; names: openArray[string]): Natural =
  let value = metricNumber(event, names)
  if value <= 0.0:
    return 0
  Natural(value.int)

proc percent(numerator, denominator: float): float =
  if denominator <= 0.0:
    return 0.0
  numerator / denominator * 100.0

proc operationalSummary*(events: openArray[SurveyEvent]): OperationalSummary =
  for event in events:
    requireValid(event)
    if event.nodeId.len > 0 and event.kind == sekNodeFinished:
      result.executionCount.inc
      result.totalCycleTimeMillis += event.durationMillis
      case event.status
      of fsSucceeded:
        result.succeededCount.inc
      of fsFailed:
        result.failedCount.inc
      of fsSkipped:
        result.skippedCount.inc
      else:
        discard

    if event.edgeId.len > 0:
      case event.kind
      of sekEdgeWaiting:
        result.totalWaitTimeMillis += event.durationMillis
      of sekEdgeBlocked:
        result.totalBlockedTimeMillis += event.durationMillis
      else:
        discard

    result.workUnits += metricNumber(event, ["work", "work_units", "units", "records", "items"])
    result.acceptedUnits += metricNumber(event, ["accepted", "accepted_units", "good", "good_units", "passed"])
    result.defectUnits += metricNumber(event, ["defects", "defect_units", "rejected", "rejected_units", "failed_units"])
    result.retryCount += metricNatural(event, ["retry", "retries", "retry_count", "attempt_retries", "retrycount"])

  result.totalObservedTimeMillis = result.totalCycleTimeMillis +
    result.totalWaitTimeMillis + result.totalBlockedTimeMillis
  if result.executionCount > 0:
    result.averageCycleTimeMillis = result.totalCycleTimeMillis.float /
      result.executionCount.float
    result.failureRate = percent(result.failedCount.float, result.executionCount.float)
    result.retryRate = percent(result.retryCount.float, result.executionCount.float)

  let completedAndDefect = result.acceptedUnits + result.defectUnits
  if completedAndDefect > 0.0:
    result.defectRate = percent(result.defectUnits, completedAndDefect)
    result.firstPassYield = percent(result.acceptedUnits, completedAndDefect)

  if result.totalObservedTimeMillis > 0:
    result.throughputPerHour = result.succeededCount.float /
      (result.totalObservedTimeMillis.float / 3600000.0)

proc survey*(graph: SurveyGraph; events: openArray[SurveyEvent];
    bottleneckLimit = 5): SurveyReport =
  requireValid(graph)
  result = SurveyReport(
    schemaVersion: ReportSchemaVersion,
    flowId: graph.id,
    variantId: graph.variantId,
    nodeStats: nodeStats(events),
    edgeStats: edgeStats(events),
    criticalPath: criticalPath(graph, events),
    bottlenecks: bottlenecks(graph, events, bottleneckLimit),
    waitInsights: waitInsights(graph, events, bottleneckLimit),
    parallelismOpportunities: parallelismOpportunities(graph, events, bottleneckLimit),
    failureImpacts: failureImpacts(events, bottleneckLimit),
    operationalSummary: operationalSummary(events),
    qualityIssues: eventQualityIssues(graph, events)
  )
  result.recommendations = recommendations(result)
