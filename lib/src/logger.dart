library logger.less;

import 'dart:async';

// The amount of logging to the console (stderr).
const int logLevelDebug = 4; // Debug, Info, Warns and Errors
const int logLevelInfo  = 3; // Info, Warns and Errors
const int logLevelWarn  = 2; // Warns and Errors - DEFAULT
const int logLevelError = 1; // Errors
const int logLevelNone  = 0; // None

class Logger {
  int id;
  int logLevel;
  StringBuffer stderr;

  static Map<int, StringBuffer> cache = new Map();
  static Map<int, int> cacheLogLevel = {};

  /*
   * If not runZoned, #id == null. Example:
   * runZoned((){...
   *   StringBuffer b = new StringBuffer();
   *   Logger logger = new Logger(b);
   * },
   * zoneValues: {#id: new Random().nextInt(10000)});
   */
  factory Logger([buffer]) {
    int id = Zone.current[#id];
    if (id == null) id = -1;

    if(buffer != null && cache[id] != null) {
      throw new StateError('Console buffer yet initialized');
    }
    if(buffer != null) cache[id] = buffer;
    if(cache[id] == null) cache[id] = new StringBuffer();

    return new Logger._internal(cache[id], id);
  }

  Logger._internal(this.stderr, this.id){
    if (cacheLogLevel[id] == null) cacheLogLevel[id] = logLevelWarn;
    logLevel = cacheLogLevel[id];
  }

  ///
  void log(String msg){
    if (stderr.isNotEmpty)stderr.write('\n');
    stderr.write('$msg');
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
  void setLogLevel(logLevel) {
    this.logLevel = logLevel;
    cacheLogLevel[id] = logLevel;
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