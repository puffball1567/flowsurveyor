import std/algorithm
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
    qualityIssues: eventQualityIssues(graph, events)
  )
  result.recommendations = recommendations(result)
