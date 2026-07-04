import std/sets

import ./types
import ./validation

proc eventQualityIssues*(graph: SurveyGraph;
    events: openArray[SurveyEvent]): seq[EventQualityIssue] =
  requireValid(graph)

  var nodeIds = initHashSet[string]()
  var edgeIds = initHashSet[string]()
  var eventIds = initHashSet[string]()

  for node in graph.nodes:
    nodeIds.incl(node.id)
  for edge in graph.edges:
    edgeIds.incl(edge.id)

  for event in events:
    requireValid(event)

    if event.id in eventIds:
      result.add(EventQualityIssue(
        kind: eqikDuplicateEventId,
        eventId: event.id,
        message: "duplicate event id"
      ))
    eventIds.incl(event.id)

    if event.nodeId.len > 0 and event.nodeId notin nodeIds:
      result.add(EventQualityIssue(
        kind: eqikMissingGraphNode,
        eventId: event.id,
        targetId: event.nodeId,
        message: "event references a node that is not present in the graph"
      ))

    if event.edgeId.len > 0 and event.edgeId notin edgeIds:
      result.add(EventQualityIssue(
        kind: eqikMissingGraphEdge,
        eventId: event.id,
        targetId: event.edgeId,
        message: "event references an edge that is not present in the graph"
      ))

    if event.durationMillis == 0 and
        event.kind in {sekNodeFinished, sekEdgeSatisfied, sekEdgeBlocked}:
      result.add(EventQualityIssue(
        kind: eqikMissingDuration,
        eventId: event.id,
        targetId:
          if event.nodeId.len > 0: event.nodeId else: event.edgeId,
        message: "finished or resolved event has no duration"
      ))

    if event.status == fsUnknown and
        event.kind in {sekNodeFinished, sekEdgeSatisfied, sekEdgeBlocked}:
      result.add(EventQualityIssue(
        kind: eqikUnknownStatus,
        eventId: event.id,
        targetId:
          if event.nodeId.len > 0: event.nodeId else: event.edgeId,
        message: "finished or resolved event has unknown status"
      ))
