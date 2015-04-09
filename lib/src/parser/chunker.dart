// source: parser/chunker.js 2.5.0

part of parser.less;

class Chunker {
  String input;
  Contexts env;

  int chunkerCurrentIndex;
  List<String> chunks = [];
  int currentChunkStartIndex;
  int emitFrom = 0;

  Chunker(String this.input, this.env);

  ///
  /// throw Parse error
  ///
  fail (String message, int index) {
    LessError error = new LessError(
        index: index,
        type: 'Parse',
        message: message,
        filename: env.currentFileInfo.filename,
        context: env);
    throw new LessExceptionError(error);
  }

  ///
  /// Split a new chunk from input
  ///
  void emitChunk([bool force=false]) {
    int len = chunkerCurrentIndex - emitFrom;
    if (((len < 512) && !force) || len == 0) return;
    chunks.add(input.substring(emitFrom, chunkerCurrentIndex + 1));
    emitFrom = chunkerCurrentIndex + 1;
  }

  ///
  /// Split the input into chunks.
  ///
  List<String> getChunks(){
    int cc;  //character
    int cc2; //character
    int lastMultiComment = 0;
    int lastMultiCommentEndBrace = 0;
    int lastOpening = 0;
    int lastOpeningParen = 0;
    int len = input.length;
    int level = 0;
    bool matched;
    int parenLevel = 0;

    for (chunkerCurrentIndex = 0; chunkerCurrentIndex < len; chunkerCurrentIndex++) {
      cc = input.codeUnitAt(chunkerCurrentIndex);
      if (((cc >= Charcode.a_97)
          && (cc <= Charcode.z_122)) || (cc < Charcode.DOUBLE_QUOTE_34)) {
        // a-z or whitespace
        continue;
      }

      switch (cc) {
        case Charcode.OPEN_PARENTHESIS_40:  // (
          parenLevel++;
          lastOpeningParen = chunkerCurrentIndex;
          continue;

        case Charcode.CLOSE_PARENTHESIS_41: // )
          if (--parenLevel < 0) return fail("missing opening `(`", chunkerCurrentIndex);
          continue;

        case Charcode.SEMICOLON_59:         // ;
          if (parenLevel == 0) emitChunk();
          continue;

        case Charcode.OPEN_BRACE_123:       // {
          level++;
          lastOpening = chunkerCurrentIndex;
          continue;

        case Charcode.CLOSE_BRACE_125:      // }
          if (--level < 0) return fail("missing opening `{`", chunkerCurrentIndex);
          if (level == 0 && parenLevel == 0) emitChunk();
          continue;

        case Charcode.BACK_SLASH_92:        // \
          if (chunkerCurrentIndex < len - 1) {
            chunkerCurrentIndex++;
            continue;
          }
          return fail("unescaped `\\`", chunkerCurrentIndex);

        case Charcode.DOUBLE_QUOTE_34:
        case Charcode.QUOTE_39:
        case Charcode.BACK_QUOTE_96:         // ", ' and `
          matched = false;
          currentChunkStartIndex = chunkerCurrentIndex;
          for (chunkerCurrentIndex = chunkerCurrentIndex + 1;
              chunkerCurrentIndex < len;
              chunkerCurrentIndex++){
            cc2 = input.codeUnitAt(chunkerCurrentIndex);
            if (cc2 > Charcode.BACK_QUOTE_96) continue;
            if (cc2 == cc) {
              matched = true;
              break;
            }
            if (cc2 == Charcode.BACK_SLASH_92) { // \
              if (chunkerCurrentIndex == len - 1) return fail("unescaped `\\`", chunkerCurrentIndex);
              chunkerCurrentIndex++;
            }
          }
          if (matched) continue;
          return fail('unmatched `${input[currentChunkStartIndex]}`', currentChunkStartIndex);

        case Charcode.SLASH_47:               // /, check for comment
          if ((parenLevel != 0) || (chunkerCurrentIndex == len - 1 )) continue;
          cc2 = input.codeUnitAt(chunkerCurrentIndex + 1);
          if (cc2 == Charcode.SLASH_47) {
            // //, find lnfeed
            for (chunkerCurrentIndex = chunkerCurrentIndex + 2;
                chunkerCurrentIndex < len;
                chunkerCurrentIndex++) {
              cc2 = input.codeUnitAt(chunkerCurrentIndex);
              if ((cc2 <= Charcode.CR_13)
                  && ((cc2 == Charcode.LF_10) || (cc2 == Charcode.CR_13))) break;
            }
          } else if (cc2 == Charcode.ASTERISK_42) {
            // /*, find */
            lastMultiComment = currentChunkStartIndex = chunkerCurrentIndex;
            for (chunkerCurrentIndex = chunkerCurrentIndex + 2;
                chunkerCurrentIndex < len - 1;
                chunkerCurrentIndex++) {
              cc2 = input.codeUnitAt(chunkerCurrentIndex);
              if (cc2 == Charcode.CLOSE_BRACE_125) {
                lastMultiCommentEndBrace = chunkerCurrentIndex;
              }
              if (cc2 != Charcode.ASTERISK_42) continue;
              if (input.codeUnitAt(chunkerCurrentIndex + 1) == Charcode.SLASH_47) {
                break;
              }
            }
            if (chunkerCurrentIndex == len - 1) {
              return fail("missing closing `*/`", currentChunkStartIndex);
            }
            chunkerCurrentIndex++;
          }
          continue;

        case Charcode.ASTERISK_42:           // *, check for unmatched */
          if ((chunkerCurrentIndex < len - 1)
              && (input.codeUnitAt(chunkerCurrentIndex + 1) == Charcode.SLASH_47)) {
            return fail("unmatched `/*`", chunkerCurrentIndex);
          }
          continue;
      }
    }

    chunkerCurrentIndex = len - 1; // for exit value is len
    if (level != 0) {
      if ((lastMultiComment > lastOpening)
          && (lastMultiCommentEndBrace > lastMultiComment)) {
        return fail("missing closing `}` or `*/`", lastOpening);
      } else {
        return fail("missing closing `}`", lastOpening);
      }
    } else if (parenLevel != 0){
        return fail("missing closing `)`", lastOpeningParen);
    }

    emitChunk(true);
    return chunks;
  }
}