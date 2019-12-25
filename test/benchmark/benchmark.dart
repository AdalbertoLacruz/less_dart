library benchmark.test.less;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math_lib;
import 'package:less_dart/less.dart';
import 'package:path/path.dart' as path;
import 'vm_common.dart';

part 'full_benchmark.dart';

///
int totalruns;
///
int ignoreruns;
///
Less less;

Future<Null> main(List<String> args) async {
  if (args.isEmpty) return mainParserBig();

  final arg = args[0];
  switch (arg) {
    case 'parser':
    case '-p':
      return mainParser();
      break;
    case 'full':
    case '-f':
      return FullBenchmark(totalruns: 30, ignoreruns: 5).run();
    default:
      return help();
  }
}

///
Null help() {
  print ('benchmark                   : Parse big file');
  print ('benchmark parser (-p)        : Parse file several times and show max and min times');
  print ('benchmark full (-f)          : Parser + Render the file several times and show max and min times');
  return null;
}

///
/// big file parsing times
///
Future<Null> mainParserBig() async {
  final less = Less();
  final sampleFile1 = 'benchmark/big1.less';
  final content = readSampleFile(sampleFile1);

  const N = 1;
  for (var i = 0; i < N; i++) {
    final stopwatch = Stopwatch()..start();
    await less.parseLessFile(content);
    print('Time (Parser big1.less): ${stopwatch.elapsedMilliseconds}');
    if (less.stderr.isNotEmpty) {
      print('error: ${less.stderr}');
      print('----------------------');
    }
  }
}

// Less 2.7.1
///
/// Benchmark only for parser
///
Future<Null> mainParser() async {
  final file =  'benchmark/benchmark.less';
  final less = Less();
  final data = readSampleFile(file);
  print('Benchmarking Parser...\n${path.basename(file)} (${data.length / 1024} KB)');

  final benchMarkData = <int>[];

  final totalruns = 100;
  final ignoreruns = 30;

  for (var i = 0; i < totalruns; i++) {
    final start = DateTime.now();
    await less.parseLessFile(data);
    final end = DateTime.now();
    benchMarkData.add(end.difference(start).inMilliseconds);
//    if (err) {
//      less.writeError(err);
//      exit(3);
//    }
  }

  num totalTime = 0;
  num mintime = 9999999;
  num maxtime = 0;
  for (var i = ignoreruns; i < totalruns; i++) {
    totalTime += benchMarkData[i];
    mintime = math_lib.min(mintime, benchMarkData[i]);
    maxtime = math_lib.max(maxtime, benchMarkData[i]);
  }
  final avgtime = totalTime / (totalruns - ignoreruns);
  final variation = maxtime - mintime;
  final variationperc = (variation / avgtime) * 100;

  print('Min. Time: $mintime ms');
  print('Max. Time: $maxtime ms');
  print('Total Average Time: $avgtime ms (${1000 / avgtime *
          data.length / 1024} KB\/s)');
  print('+/- $variationperc%');
  print('${less.stderr.toString()}');
}
