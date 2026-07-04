import std/monotimes
import std/strformat
import std/times

import flowsurveyor

const NodeCount = 5_000

proc elapsedMs(started: MonoTime): float =
  let elapsed = getMonoTime() - started
  elapsed.inNanoseconds.float / 1_000_000.0

var graph = initSurveyGraph("large")
var events: seq[SurveyEvent]

for i in 0 ..< NodeCount:
  let nodeId = "n" & $i
  graph.nodes.add(surveyNode(nodeId))
  events.add(surveyEvent("node-" & $i, "bench", "large", "run-1",
    sekNodeFinished, nodeId = nodeId, status = fsSucceeded,
    durationMillis = Natural((i mod 17) + 1)))

for i in 0 ..< NodeCount - 1:
  let edgeId = "e" & $i
  graph.edges.add(surveyEdge(edgeId, "n" & $i, "n" & $(i + 1)))
  events.add(surveyEvent("edge-" & $i, "bench", "large", "run-1",
    sekEdgeSatisfied, edgeId = edgeId, status = fsSucceeded,
    durationMillis = 1))

let started = getMonoTime()
let report = survey(graph, events)
let ms = elapsedMs(started)

doAssert report.nodeStats.len == NodeCount
doAssert report.edgeStats.len == NodeCount - 1

echo &"survey: {NodeCount} nodes, {NodeCount - 1} edges, {events.len} events in {ms:.2f} ms"
