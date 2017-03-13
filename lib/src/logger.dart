library logger.less;

import 'dart:async';

// The amount of logging to the console (stderr).
const int logLevelDebug = 4; // Debug, Info, Warns and Errors
const int logLevelInfo  = 3; // Info, Warns and Errors
const int logLevelWarn  = 2; // Warns and Errors - DEFAULT
const int logLevelError = 1; // Errors
const int logLevelNone  = 0; // None

class Logger {
  int logLevel;
  StringBuffer stderr;
  StringBuffer capture;

  static Map<int, Logger> cache = <int, Logger>{};

  Logger._(this.stderr){
    if (this.stderr == null) this.stderr = new StringBuffer();
    this.logLevel = logLevelWarn;
  }

  /*
   * If not runZoned, #id == null. Example:
   * runZoned((){...
   *   StringBuffer b = new StringBuffer();
   *   Logger logger = new Logger(b);
   * },
   * zoneValues: {#id: new Random().nextInt(10000)});
   */
  factory Logger([StringBuffer buffer]) {
    int id = Zone.current[#id];
    if (id == null) id = -1;

    if(buffer != null && cache[id] != null) {
      throw new StateError('Console buffer yet initialized');
    }

    if(cache[id] == null) cache[id] = new Logger._(buffer);

    return cache[id];
  }

  /// remove cache for this id
  void reset() {
    int id = Zone.current[#id];
    cache[id] = null;
  }

  ///
  /// route the messages to capture buffer
  ///
  void captureStart() {
    capture = new StringBuffer();
  }

  ///
  /// Returns captured messages and goes to normal log mode
  ///
  String captureStop() {
    String result = capture.toString();
    capture = null;
    return result;
  }

  ///
  void log(String msg){
    StringBuffer buffer = capture == null ? stderr : capture;

    if (buffer.isNotEmpty)buffer.write('\n');
    buffer.write('$msg');
  }

  ///
  void error(String msg) {
    if (logLevel >= logLevelError) log(msg);
  }

  ///
  void warn(String msg) {
    if (logLevel >= logLevelWarn) log(msg);
  }

  ///
  void info(String msg) {
    if (logLevel >= logLevelInfo) log(msg);
  }

  ///
  void debug(String msg) {
    if (logLevel >= logLevelDebug) log(msg);
  }

  ///
  void setLogLevel(int logLevel) {
    this.logLevel = logLevel;
    //cacheLogLevel[id] = logLevel;
  }

  /// Sets the log level to silence
  void silence() {
    setLogLevel(logLevelNone);
  }

  /// Sets the log level to verbose
  void verbose() {
    setLogLevel(logLevelInfo);
  }
}
