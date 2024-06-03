package three.js.editor.js.libs.ternjs;

import js.html.Compat;

class Comment {
  public static function isSpace(ch:Int):Bool {
    return (ch < 14 && ch > 8) || ch === 32 || ch === 160;
  }

  public static function onOwnLine(text:String, pos:Int):Bool {
    while (pos > 0) {
      pos--;
      var ch = text.charCodeAt(pos);
      if (ch == 10) break;
      if (!isSpace(ch)) return false;
    }
    return true;
  }

  public static function commentsBefore(text:String, pos:Int):Array<String> {
    var found:Array<String> = null;
    var emptyLines = 0;
    var topIsLineComment = false;
    out: while (pos > 0) {
      var prev = text.charCodeAt(pos - 1);
      if (prev == 10) {
        var scan = --pos;
        var sawNonWS = false;
        while (scan > 0) {
          scan--;
          prev = text.charCodeAt(scan);
          if (prev == 47 && text.charCodeAt(scan - 1) == 47) {
            if (!onOwnLine(text, scan - 1)) break out;
            var content = text.substring(scan, pos);
            if (emptyLines == 0 && topIsLineComment) {
              found[0] = content + "\n" + found[0];
            } else {
              if (found == null) found = new Array<String>();
              found.unshift(content);
            }
            topIsLineComment = true;
            emptyLines = 0;
            pos = scan - 1;
            break;
          } else if (prev == 10) {
            if (!sawNonWS && ++emptyLines > 1) break out;
            break;
          } else if (!sawNonWS && !isSpace(prev)) {
            sawNonWS = true;
          }
        }
      } else if (prev == 47 && text.charCodeAt(pos - 2) == 42) {
        var scan = pos - 2;
        while (scan > 1) {
          scan--;
          if (text.charCodeAt(scan) == 42 && text.charCodeAt(scan - 1) == 47) {
            if (!onOwnLine(text, scan - 1)) break out;
            if (found == null) found = new Array<String>();
            found.unshift(text.substring(scan, pos - 2));
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

  public static function commentAfter(text:String, pos:Int):String {
    while (pos < text.length) {
      var next = text.charCodeAt(pos);
      if (next == 47) {
        var after = text.charCodeAt(pos + 1);
        var end = -1;
        if (after == 47) // line comment
          end = text.indexOf("\n", pos + 2);
        else if (after == 42) // block comment
          end = text.indexOf("*/", pos + 2);
        else
          return null;
        if (end < 0) end = text.length;
        return text.substring(pos + 2, end);
      } else if (isSpace(next)) {
        ++pos;
      }
    }
    return null;
  }

  public static function ensureCommentsBefore(text:String, node:Dynamic):Array<String> {
    if (Std.hasField(node, "commentsBefore")) return Reflect.field(node, "commentsBefore");
    return Reflect.setField(node, "commentsBefore", commentsBefore(text, Std.int(Reflect.field(node, "start"))));
  }
}