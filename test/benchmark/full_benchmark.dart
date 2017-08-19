//source: benchmark/index.js 3.0.0 20160714

part of benchmark.test.less;

///
/// full benchmark, calculating the times in
/// parsing, tree transforming and css generation
///
class FullBenchmark {
  /// Run the test several times to get the average time
  int totalruns;
  /// ignore the first runs
  int ignoreruns;

  // error in one run
  bool _isError;

  // To initialize the environment
  // ignore: unused_field
  Less _less;

  // file content
  String _data;

  //filename
  String _file = 'benchmark/benchmark.less';

  // parser time: parserEnd - start
  List<num> _parserBenchmark = <num>[];
  // transformTree time: evalEnd - parserEnd
  List<num> _evalBenchmark = <num>[];
  // toCSS time: totalEnd - evalEnd
  List<num> _cssBenchmark = <num>[];
  // total time: totalEnd - start
  List<num> _totalBenchmark = <num>[];

  // _start -> _parserEnd -> _evalEnd -> _totalEnd
  DateTime _start;
  DateTime _parserEnd;
  DateTime _evalEnd;
  DateTime _totalEnd;

  ///
  FullBenchmark({this.totalruns = 0, this.ignoreruns = 0}) {
    _less = new Less(); //initialize options in cache and other environment
    _data = readSampleFile(_file);
  }

  ///
  Future<Null> run() async {
    _isError = false;
    print('Benchmarking Full...\n${path.basename(_file)} (${_data.length / 1024} KB)');
    return nextRun();

//3.0.0 20160714
// var file = path.join(__dirname, 'benchmark.less');
//
// if (process.argv[2]) { file = path.join(process.cwd(), process.argv[2]) }
//
// fs.readFile(file, 'utf8', function (e, data) {
//     var start, total;
//
//     console.log("Benchmarking...\n", path.basename(file) + " (" +
//              parseInt(data.length / 1024) + " KB)", "");
//
//     var renderBenchmark = []
//       , parserBenchmark = []
//       , evalBenchmark = [];
//
//     var totalruns = 30;
//     var ignoreruns = 5;
//
//     var i = 0;
//
//     nextRun();
// }
  }

  ///
  Future<Null> nextRun() async {
    for (int i = 0; i < totalruns; i++) {
      stdout.write('*');
      _start = new DateTime.now();
      final LessOptions options = Environment.cache[-1].options;
      final Contexts toCSSOptions = new Contexts()
                        ..dumpLineNumbers = ''
                        ..numPrecision = 8;
      final RenderResult result = new RenderResult();
      final Parser parser = new Parser(options);

      try {
        await parser.parse(_data).then((Ruleset root) {
          _parserEnd = new DateTime.now();
          final Ruleset evaldRoot = new TransformTree().call(root, options);
          _evalEnd = new DateTime.now();
          result.css = evaldRoot.toCSS(toCSSOptions).toString();
          _totalEnd = new DateTime.now();

          //difference in milliseconds
          _totalBenchmark.add(_totalEnd.difference(_start).inMilliseconds);
          _parserBenchmark.add(_parserEnd.difference(_start).inMilliseconds);
          _evalBenchmark.add(_evalEnd.difference(_parserEnd).inMilliseconds);
          _cssBenchmark.add(_totalEnd.difference(_evalEnd).inMilliseconds);
        });
      } catch (e) {
        print('\n${e.toString()}');
        _isError = true;
        break;
      }
    }

    if (!_isError)
      finish();

///3.0.0 20160714
// function nextRun() {
//     var start, renderEnd, parserEnd;
//
//     start = now();
//
//     less.parse(data, {}, function(err, root, imports, options) {
//         if (err) {
//             less.writeError(err);
//             process.exit(3);
//         }
//         parserEnd = now();
//
//         var tree, result;
//         tree = new less.ParseTree(root, imports);
//         result = tree.toCSS(options);
//
//         renderEnd = now();
//
//         renderBenchmark.push(renderEnd - start);
//         parserBenchmark.push(parserEnd - start);
//         evalBenchmark.push(renderEnd - parserEnd);
//
//         i += 1;
//         //console.log('Less Run #: ' + i);
//         if(i < totalruns) {
//             nextRun();
//         }
//         else {
//             finish();
//         }
//     });
// }
  }

  ///
  /// Show results
  ///
  void finish() {
    print('');
    analyze('Parsing', _parserBenchmark, _data.length);
    analyze('Tree Transforming', _evalBenchmark, _data.length);
    analyze('CSS Generation', _cssBenchmark, _data.length);
    analyze('Total Time', _totalBenchmark, _data.length);

//3.0.0 20160714
// function finish() {
//     analyze('Parsing', parserBenchmark);
//     analyze('Evaluation', evalBenchmark);
//     analyze('Render Time', renderBenchmark);
// }
  }

  ///
  /// Calculate and print the results
  /// benchMarkData List<miliseconds>
  ///
  void analyze(String benchmark, List<num> benchMarkData, int dataLength) {
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

      print('Min. Time: $mintime ms');
      print('Max. Time: $maxtime ms');
      print('Total Average Time: ${avgtime.round()} ms (${1000 / avgtime * dataLength / 1024} KB\/s)');
      print('+/- ${variationperc.round()}%');

//3.0.0 20160714
// function analyze(benchmark, benchMarkData) {
//     console.log('----------------------');
//     console.log(benchmark);
//     console.log('----------------------');
//     var totalTime = 0;
//     var mintime = Infinity;
//     var maxtime = 0;
//     for(var i = ignoreruns; i < totalruns; i++) {
//         totalTime += benchMarkData[i];
//         mintime = Math.min(mintime, benchMarkData[i]);
//         maxtime = Math.max(maxtime, benchMarkData[i]);
//     }
//     var avgtime = totalTime / (totalruns - ignoreruns);
//     var variation = maxtime - mintime;
//     var variationperc = (variation / avgtime) * 100;
//
//     console.log("Min. Time: " + Math.round(mintime) + " ms");
//     console.log("Max. Time: " + Math.round(maxtime) + " ms");
//     console.log("Total Average Time: " + Math.round(avgtime) + " ms (" +
//         parseInt(1000 / avgtime *
//         data.length / 1024) + " KB\/s)");
//     console.log("+/- " + Math.round(variationperc) + "%");
//     console.log("");
// }
  }
}
