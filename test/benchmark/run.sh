#!/bin/bash
npm install less
echo "Benchmark.less"
echo "NodeJs"
time nodejs ./node_modules/less/bin/lessc ./benchmark.less >/dev/null
echo " ----------------- "
echo "Dart"
time dart ../../bin/lessc.dart ./benchmark.less >/dev/null
echo " "
echo "big1.less"
echo "NodeJs"
time nodejs ./node_modules/less/bin/lessc ./big1.less >/dev/null
echo " ----------------- "
echo "Dart"
time dart ../../bin/lessc.dart ./big1.less >/dev/null

