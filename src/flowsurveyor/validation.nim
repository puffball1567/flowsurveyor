import std/sets
import std/strutils

import ./types

type
  ValidationResult* = object
    ok*: bool
    errors*: seq[string]

proc valid*(): ValidationResult =
  ValidationResult(ok: true)

proc invalid*(errors: seq[string]): ValidationResult =
  ValidationResult(ok: false, errors: errors)

proc validate*(graph: SurveyGraph): ValidationResult =
  var errors: seq[string]
  if graph.id.len == 0:
    errors.add("graph id is required")

  var nodeIds = initHashSet[string]()
  for node in graph.nodes:
    if node.id.len == 0:
      errors.add("node id is required")
    if node.id in nodeIds:
      errors.add("duplicate node id: " & node.id)
    nodeIds.incl(node.id)

  var edgeIds = initHashSet[string]()
  for edge in graph.edges:
    if edge.id.len == 0:
      errors.add("edge id is required")
    if edge.fromNode.len == 0:
      errors.add("edge fromNode is required")
    if edge.toNode.len == 0:
      errors.add("edge toNode is required")
    if edge.id in edgeIds:
      errors.add("duplicate edge id: " & edge.id)
    edgeIds.incl(edge.id)
    if edge.fromNode notin nodeIds:
      errors.add("edge references missing fromNode: " & edge.fromNode)
    if edge.toNode notin nodeIds:
      errors.add("edge references missing toNode: " & edge.toNode)

  if errors.len == 0:
    return valid()
  invalid(errors)

proc validate*(event: SurveyEvent): ValidationResult =
  var errors: seq[string]
  if event.id.len == 0:
    errors.add("event id is required")
  if event.flowId.len == 0:
    errors.add("event flowId is required")
  if event.runId.len == 0:
    errors.add("event runId is required")
  if event.kind != sekNote and event.nodeId.len == 0 and event.edgeId.len == 0:
    errors.add("event requires nodeId or edgeId unless it is a note")
  if errors.len == 0:
    return valid()
  invalid(errors)

proc requireValid*(graph: SurveyGraph) =
  let result = validate(graph)
  if not result.ok:
    raise newException(ValueError, result.errors.join("; "))

proc requireValid*(event: SurveyEvent) =
  let result = validate(event)
  if not result.ok:
    raise newException(ValueError, result.errors.join("; "))
