import ./analysis
import ./types
import ./validation

type
  SurveyOptions* = object
    bottleneckLimit*: Natural

  SurveyInput* = object
    graph*: SurveyGraph
    events*: seq[SurveyEvent]
    options*: SurveyOptions

  SurveyOutcome* = object
    ok*: bool
    report*: SurveyReport
    errors*: seq[string]

proc defaultSurveyOptions*(): SurveyOptions =
  SurveyOptions(bottleneckLimit: 5)

proc initSurveyInput*(graph: SurveyGraph;
    events: openArray[SurveyEvent];
    options = defaultSurveyOptions()): SurveyInput =
  SurveyInput(graph: graph, events: @events, options: options)

proc validate*(input: SurveyInput): ValidationResult =
  var errors: seq[string]

  let graphResult = validate(input.graph)
  if not graphResult.ok:
    for item in graphResult.errors:
      errors.add("graph: " & item)

  for index, event in input.events:
    let eventResult = validate(event)
    if not eventResult.ok:
      for item in eventResult.errors:
        errors.add("event[" & $index & "]: " & item)

  if errors.len == 0:
    return valid()
  invalid(errors)

proc analyze*(input: SurveyInput): SurveyOutcome =
  let validation = validate(input)
  if not validation.ok:
    return SurveyOutcome(ok: false, errors: validation.errors)

  let limit =
    if input.options.bottleneckLimit == 0: 5
    else: int(input.options.bottleneckLimit)

  SurveyOutcome(
    ok: true,
    report: survey(input.graph, input.events, bottleneckLimit = limit)
  )

proc analyze*(graph: SurveyGraph; events: openArray[SurveyEvent];
    options = defaultSurveyOptions()): SurveyOutcome =
  analyze(initSurveyInput(graph, events, options))
