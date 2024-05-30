package three.js.editor.js.libs.ternjs;

class Comment {
  static function isSpace(ch:Int):Bool {
    return (ch < 14 && ch > 8) || ch == 32 || ch == 160;
  }

  static function onOwnLine(text:String, pos:Int):Bool {
    for (pos--; pos > 0; pos--) {
      var ch = text.charCodeAt(pos - 1);
      if (ch == 10) break;
      if (!isSpace(ch)) return false;
    }
    return true;
  }

  static function commentsBefore(text:String, pos:Int):Array<String> {
    var found:Array<String> = null, emptyLines:Int = 0, topIsLineComment:Bool;
    while (pos > 0) {
      var prev:Int = text.charCodeAt(pos - 1);
      if (prev == 10) {
        for (var scan = --pos, sawNonWS:Bool = false; scan > 0; --scan) {
          prev = text.charCodeAt(scan - 1);
          if (prev == 47 && text.charCodeAt(scan - 2) == 47) {
            if (!onOwnLine(text, scan - 2)) break;
            var content = text.slice(scan, pos);
            if (!emptyLines && topIsLineComment) found.unshift(content + "\n" + found[0]);
            else (found == null ? found = [content] : found.unshift(content));
            topIsLineComment = true;
            emptyLines = 0;
            pos = scan - 2;
            break;
          } else if (prev == 10) {
            if (!sawNonWS && ++emptyLines > 1) break;
            break;
          } else if (!sawNonWS && !isSpace(prev)) {
            sawNonWS = true;
          }
        }
      } else if (prev == 47 && text.charCodeAt(pos - 2) == 42) {
        for (var scan = pos - 2; scan > 1; --scan) {
          if (text.charCodeAt(scan - 1) == 42 && text.charCodeAt(scan - 2) == 47) {
            if (!onOwnLine(text, scan - 2)) break;
            (found == null ? found = [text.slice(scan, pos - 2)] : found.unshift(text.slice(scan, pos - 2)));
            topIsLineComment = false;
            emptyLines = 0;
            break;
          }
        }
        pos = scan - 2;
      } else if (isSpace(prev)) {
        --pos;
      } else {
        break;
      }
    }
    return found;
  }

  static function commentAfter(text:String, pos:Int):String {
    while (pos < text.length) {
      var next:Int = text.charCodeAt(pos);
      if (next == 47) {
        var after:Int = text.charCodeAt(pos + 1), end:Int;
        if (after == 47) // line comment
          end = text.indexOf("\n", pos + 2);
        else if (after == 42) // block comment
          end = text.indexOf("*/", pos + 2);
        else
          return null;
        return text.slice(pos + 2, end < 0 ? text.length : end);
      } else if (isSpace(next)) {
        ++pos;
      }
    }
    return null;
  }

  static function ensureCommentsBefore(text:String, node:Dynamic):Array<String> {
    if (Reflect.hasField(node, "commentsBefore")) return node.commentsBefore;
    return node.commentsBefore = commentsBefore(text, node.start);
  }
}