version       = "0.1.0"
author        = "flowsurveyor contributors"
description   = "Flow analysis primitives for FlowBrigade Toolkit graphs and events."
license       = "Apache-2.0"
srcDir        = "src"
installExt    = @["nim"]
skipDirs      = @[
  ".github",
  "benchmarks",
  "docs",
  "examples",
  "tests"
]

requires "nim >= 2.2.0"

task test, "Run the test suite":
  exec "nim r --nimcache:/tmp/flowsurveyor-test-nimcache -p:src tests/all.nim"

task examples, "Check examples":
  exec "nim check --nimcache:/tmp/flowsurveyor-nimcache -p:src examples/basic_analysis.nim"

task bench, "Run basic local benchmarks":
  exec "nim r -d:release --nimcache:/tmp/flowsurveyor-bench-nimcache -p:src benchmarks/basic_analysis.nim"
