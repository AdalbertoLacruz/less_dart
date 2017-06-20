import 'dart:async';
import 'dart:io';
import 'dart:math' as Math;
import 'package:less_dart/less.dart';
import 'package:path/path.dart' as path;
import 'vm_common.dart';

///
int totalruns;
///
int ignoreruns;
///
Less less;

Future<Null> main(List<String> args) async {
  if (args.isEmpty)
      return mainParserBig();

  final String arg = args[0];
  switch (arg) {
    case 'parser':
    case 'p':
      return mainParser();
      break;
    case 'full':
    case 'f':
      return mainFull();
    default:
      return help();
  }
}

///
Null help() {
  print ('benchmark                   : Parse big file');
  print ('benchmark parser (p)        : Parse file several times and show max and min times');
  print ('benchmark full (f)          : Parser + Render the file several times and show max and min times');
  return null;
}

///
/// big file parsing times
///
Future<Null> mainParserBig() async {
  final Less less = new Less();
  final String sampleFile1 = "benchmark/big1.less";
  final String content = readSampleFile(sampleFile1);

  const int N = 1;
  for (int i = 0; i < N; i++) {
    final Stopwatch stopwatch = new Stopwatch()..start();
    await less.parseLessFile(content);
    print("Time (Parser big1.less): ${stopwatch.elapsedMilliseconds}");
    if (less.stderr.isNotEmpty) {
      print("error: ${less.stderr}");
      print("----------------------");
    }
  }
}

// Less 2.7.1
///
/// Benchmark only for parser
///
Future<Null> mainParser() async {
  final String file =  "benchmark/benchmark.less";
  final Less less = new Less();
  final String data = readSampleFile(file);
  print("Benchmarking Parser...\n${path.basename(file)} (${data.length / 1024} KB)");

  final List<int> benchMarkData = <int>[];

  final int totalruns = 100;
  final int ignoreruns = 30;

  for (int i = 0; i < totalruns; i++) {
    final DateTime start = new DateTime.now();
    await less.parseLessFile(data);
    final DateTime end = new DateTime.now();
    benchMarkData.add(end.difference(start).inMilliseconds);
//    if (err) {
//      less.writeError(err);
//      exit(3);
//    }
  }

  num totalTime = 0;
  num mintime = 9999999;
  num maxtime = 0;
  for (int i = ignoreruns; i < totalruns; i++) {
    totalTime += benchMarkData[i];
    mintime = Math.min(mintime, benchMarkData[i]);
    maxtime = Math.max(maxtime, benchMarkData[i]);
  }
  final double avgtime = totalTime / (totalruns - ignoreruns);
  final num variation = maxtime - mintime;
  final double variationperc = (variation / avgtime) * 100;

  print("Min. Time: $mintime ms");
  print("Max. Time: $maxtime ms");
  print("Total Average Time: $avgtime ms (${1000 / avgtime *
          data.length / 1024} KB\/s)");
  print("+/- $variationperc%");
  print('${less.stderr.toString()}');
}

///
/// full benchmark, calculating the times in
/// parsing, tree transforming and css generation
///
Future<Null> mainFull() async {
    totalruns = 30;
    ignoreruns = 5;

    final List<int> parserBenchmark = <int>[];
    final List<int> evalBenchmark = <int>[];
    final List<int> cssBenchmark = <int>[];
    final List<int> totalBenchmark = <int>[];

    DateTime start;
    DateTime parserEnd;
    DateTime evalEnd;
    DateTime totalEnd;

    bool isError = false;
    less = new Less(); //initialize options in cache and other environment

    final String file =  'benchmark/benchmark.less';

    final String data = readSampleFile(file);
    print('Benchmarking Full...\n${path.basename(file)} (${data.length / 1024} KB)');

    for (int i = 0; i < totalruns; i++) {
      stdout.write('*');
      start = new DateTime.now();
      final LessOptions options = Environment.cache[-1].options;
      final Contexts toCSSOptions = new Contexts()
                        ..dumpLineNumbers = ''
                        ..numPrecision = 8;
      final RenderResult result = new RenderResult();
      final Parser parser = new Parser(options);

      try {
        await parser.parse(data).then((Ruleset root) {
          parserEnd = new DateTime.now();
          final Ruleset evaldRoot = new TransformTree().call(root, options);
          evalEnd = new DateTime.now();
          result.css = evaldRoot.toCSS(toCSSOptions).toString();
          totalEnd = new DateTime.now();

          totalBenchmark.add(totalEnd.difference(start).inMilliseconds);
          parserBenchmark.add(parserEnd.difference(start).inMilliseconds);
          evalBenchmark.add(evalEnd.difference(parserEnd).inMilliseconds);
          cssBenchmark.add(totalEnd.difference(evalEnd).inMilliseconds);
        });
      } catch (e) {
        print('\n${e.toString()}');
        isError = true;
        break;
      }
    }

    if (!isError) {
      print('');
      analyze('Parsing', parserBenchmark, data.length);
      analyze('Tree Transforming', evalBenchmark, data.length);
      analyze('CSS Generation', cssBenchmark, data.length);
      analyze('Total Time', totalBenchmark, data.length);
    }
}

///
/// Calculate and print the results
///
void analyze(String benchmark, List<int> benchMarkData, int dataLength) {
  num totalTime = 0;
  num mintime = 9999999;
  num maxtime = 0;

  print('----------------------');
  print(benchmark);
  print('----------------------');

  for (int i = ignoreruns; i < totalruns; i++) {
      totalTime += benchMarkData[i];
      mintime = Math.min(mintime, benchMarkData[i]);
      maxtime = Math.max(maxtime, benchMarkData[i]);
  }
  final double avgtime = totalTime / (totalruns - ignoreruns);
  final num variation = maxtime - mintime;
  final double variationperc = (variation / avgtime) * 100;

  print("Min. Time: $mintime ms");
  print("Max. Time: $maxtime ms");
  print("Total Average Time: $avgtime ms (${1000 / avgtime * dataLength / 1024} KB\/s)");
  print("+/- $variationperc%");
}
