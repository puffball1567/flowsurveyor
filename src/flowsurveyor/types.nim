const
  ReportSchemaVersion* = 1

type
  FlowStatus* = enum
    fsUnknown,
    fsPending,
    fsRunning,
    fsSucceeded,
    fsFailed,
    fsSkipped

  KeyValue* = object
    key*: string
    value*: string

  SurveyNode* = object
    id*: string
    label*: string
    variantId*: string
    metadata*: seq[KeyValue]

  SurveyEdge* = object
    id*: string
    fromNode*: string
    toNode*: string
    variantId*: string
    weight*: float
    expectedDurationMillis*: Natural
    metadata*: seq[KeyValue]

  SurveyGraph* = object
    id*: string
    variantId*: string
    nodes*: seq[SurveyNode]
    edges*: seq[SurveyEdge]

  SurveyEventKind* = enum
    sekNodeStarted,
    sekNodeFinished,
    sekEdgeWaiting,
    sekEdgeSatisfied,
    sekEdgeBlocked,
    sekMetric,
    sekNote

  SurveyEvent* = object
    id*: string
    source*: string
    flowId*: string
    runId*: string
    variantId*: string
    nodeId*: string
    edgeId*: string
    kind*: SurveyEventKind
    status*: FlowStatus
    durationMillis*: Natural
    metrics*: seq[KeyValue]
    message*: string

  AggregateStats* = object
    id*: string
    count*: Natural
    successCount*: Natural
    failureCount*: Natural
    totalDurationMillis*: Natural
    maxDurationMillis*: Natural
    averageDurationMillis*: float

  CriticalPath* = object
    nodeIds*: seq[string]
    edgeIds*: seq[string]
    totalDurationMillis*: Natural

  Bottleneck* = object
    id*: string
    kind*: string
    score*: float
    reason*: string

  WaitInsight* = object
    edgeId*: string
    fromNode*: string
    toNode*: string
    count*: Natural
    blockedCount*: Natural
    totalWaitMillis*: Natural
    averageWaitMillis*: float
    reason*: string

  ParallelismOpportunity* = object
    nodeId*: string
    fanIn*: Natural
    fanOut*: Natural
    observedDurationMillis*: Natural
    onCriticalPath*: bool
    score*: float
    reason*: string

  FailureImpact* = object
    targetId*: string
    kind*: string
    failureCount*: Natural
    retryCount*: Natural
    failedDurationMillis*: Natural
    retryDurationMillis*: Natural
    score*: float
    reason*: string

  RecommendationKind* = enum
    rkIncreaseParallelism,
    rkInvestigateFailures,
    rkReduceWait,
    rkReviewCriticalPath

  Recommendation* = object
    id*: string
    kind*: RecommendationKind
    targetId*: string
    confidence*: float
    reason*: string

  EventQualityIssueKind* = enum
    eqikMissingGraphNode,
    eqikMissingGraphEdge,
    eqikDuplicateEventId,
    eqikMissingDuration,
    eqikUnknownStatus

  EventQualityIssue* = object
    kind*: EventQualityIssueKind
    eventId*: string
    targetId*: string
    message*: string



  OperationalSummary* = object
    executionCount*: Natural
    succeededCount*: Natural
    failedCount*: Natural
    skippedCount*: Natural
    retryCount*: Natural
    workUnits*: float
    acceptedUnits*: float
    defectUnits*: float
    totalCycleTimeMillis*: Natural
    averageCycleTimeMillis*: float
    totalWaitTimeMillis*: Natural
    totalBlockedTimeMillis*: Natural
    totalObservedTimeMillis*: Natural
    throughputPerHour*: float
    failureRate*: float
    defectRate*: float
    retryRate*: float
    firstPassYield*: float

  VariantSummary* = object
    variantId*: string
    totalDurationMillis*: Natural
    failureCount*: Natural
    eventCount*: Natural

  VariantComparison* = object
    baseVariant*: string
    targetVariant*: string
    base*: VariantSummary
    target*: VariantSummary
    durationDeltaMillis*: int
    failureDelta*: int
    summary*: string
    improvements*: seq[string]
    regressions*: seq[string]

  SurveyReport* = object
    schemaVersion*: Natural
    flowId*: string
    variantId*: string
    nodeStats*: seq[AggregateStats]
    edgeStats*: seq[AggregateStats]
    criticalPath*: CriticalPath
    bottlenecks*: seq[Bottleneck]
    waitInsights*: seq[WaitInsight]
    parallelismOpportunities*: seq[ParallelismOpportunity]
    failureImpacts*: seq[FailureImpact]
    operationalSummary*: OperationalSummary
    recommendations*: seq[Recommendation]
    qualityIssues*: seq[EventQualityIssue]

proc kv*(key, value: string): KeyValue =
  KeyValue(key: key, value: value)

proc surveyNode*(id: string; label = ""; variantId = "";
    metadata: openArray[KeyValue] = []): SurveyNode =
  SurveyNode(id: id, label: label, variantId: variantId, metadata: @metadata)

proc surveyEdge*(id, fromNode, toNode: string; variantId = ""; weight = 1.0;
    expectedDurationMillis: Natural = 0;
    metadata: openArray[KeyValue] = []): SurveyEdge =
  SurveyEdge(
    id: id,
    fromNode: fromNode,
    toNode: toNode,
    variantId: variantId,
    weight: weight,
    expectedDurationMillis: expectedDurationMillis,
    metadata: @metadata
  )

proc initSurveyGraph*(id: string; variantId = ""): SurveyGraph =
  SurveyGraph(id: id, variantId: variantId)

proc surveyEvent*(id, source, flowId, runId: string; kind: SurveyEventKind;
    variantId = ""; nodeId = ""; edgeId = ""; status = fsUnknown;
    durationMillis: Natural = 0; metrics: openArray[KeyValue] = [];
    message = ""): SurveyEvent =
  SurveyEvent(
    id: id,
    source: source,
    flowId: flowId,
    runId: runId,
    variantId: variantId,
    nodeId: nodeId,
    edgeId: edgeId,
    kind: kind,
    status: status,
    durationMillis: durationMillis,
    metrics: @metrics,
    message: message
  )
