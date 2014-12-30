part of nodejs.less;

class NodeConsole {
  StringBuffer stderr;
  static Map<int,StringBuffer> cache = new Map();

  /*
   * If not runZoned, #id == null. Example:
   * runZoned((){...
   *   StringBuffer b = new StringBuffer();
   *   Console console = new Console(b);
   * },
   * zoneValues: {#id: new Random().nextInt(10000)});
   */
  factory NodeConsole([buffer]) {
    int id = Zone.current[#id];
    if (id == null) id = -1;

    if(buffer != null && cache[id] != null) {
      throw new StateError('Console buffer yet initialized');
    }
    if(buffer != null) cache[id] = buffer;
    if(cache[id] == null) cache[id] = new StringBuffer();
    return new NodeConsole._internal(cache[id]);
  }

  NodeConsole._internal(this.stderr);

  ///
  void log (String msg){
    if (stderr.isNotEmpty)stderr.write('\n');
    stderr.write('$msg');
  }

  ///
  void warn(String msg) {
    if (stderr.isNotEmpty)stderr.write('\n');
    stderr.write('$msg');
  }
}
/*
class Console {
  static StringBuffer stderr;

  factory Console([buffer]) {
    print('zone id: ${Zone.current[#id]}');
    if(buffer != null && stderr != null) {
      throw new StateError('Console buffer yet initialized');
    }
    if(buffer != null) stderr = buffer;
    if(stderr == null) stderr = new StringBuffer();
    return new Console._internal();
  }

  Console._internal();

  log (msg){
    stderr.write('\n$msg');
  }
}
 *
 */