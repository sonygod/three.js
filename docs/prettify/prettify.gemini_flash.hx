class PR {
  static function createSimpleLexer(a:Array<Array<String>>, m:Array<Array<String>>):Dynamic {
    function e(a:Dynamic):Void {
      var l = a.d;
      var p = [l, "pln"];
      var d = 0;
      var g = a.a.match(y) || [];
      var r = new haxe.ds.StringMap();
      var n = 0;
      var z = g.length;
      while(n < z) {
        var f = g[n];
        var b = r.get(f);
        var o = null;
        var c:Bool;
        if(typeof b == "string") c = false;
        else {
          var i = h.get(f.charAt(0));
          if(i != null) {
            o = f.match(i[1]);
            b = i[0];
          } else {
            for(c = 0; c < t; c++) {
              var i = m[c];
              var o = f.match(i[1]);
              if(o != null) {
                b = i[0];
                break;
              }
            }
            if(o == null) b = "pln";
          }
          if((c = b.length >= 5 && b.substring(0, 5) == "lang-") && !(o != null && typeof o[1] == "string")) {
            c = false;
            b = "src";
          }
          if(!c) r.set(f, b);
        }
        i = d;
        d += f.length;
        if(c) {
          c = o[1];
          var j = f.indexOf(c);
          var k = j + c.length;
          if(o[2] != null) {
            k = f.length - o[2].length;
            j = k - c.length;
          }
          b = b.substring(5);
          B(l + i, f.substring(0, j), e, p);
          B(l + i + j, c, C(b, c), p);
          B(l + i + k, f.substring(k), e, p);
        } else p.push(l + i, b);
        n++;
      }
      a.e = p;
    }
    function h:haxe.ds.StringMap = new haxe.ds.StringMap();
    var y:EReg;
    (function() {
      var e = a.concat(m);
      var l = new Array();
      var p = new haxe.ds.StringMap();
      var d = 0;
      var g = e.length;
      while(d < g) {
        var r = e[d];
        var n = r[3];
        if(n != null) {
          var k = n.length;
          while(--k >= 0) h.set(n.charAt(k), r);
        }
        r = r[1];
        n = "" + r;
        if(!p.exists(n)) {
          l.push(r);
          p.set(n, null);
        }
        d++;
      }
      l.push(/[\S\s]/);
      y = L(l);
    })();
    var t = m.length;
    return e;
  }
  static function registerLangHandler(a:Dynamic, m:Array<String>):Void {
    var e = m.length;
    while(--e >= 0) {
      var h = m[e];
      if(A.exists(h)) {
        if(haxe.CallStack.last().get_name() == "console") {
          haxe.Log.trace("cannot override language handler " + h, haxe.CallStack.last());
        }
      } else A.set(h, a);
    }
  }
  static function sourceDecorator(a:Dynamic):Dynamic {
    var m = new Array();
    var e = new Array();
    if(a.tripleQuotedStrings) {
      m.push(["str", /^(?:'''(?:[^'\\]|\\[\S\s]|''?(?=[^']))*(?:'''|$)|"""(?:[^"\\]|\\[\S\s]|""?(?=[^"]))*(?:"""|$)|'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$))/, null, "'\"'"]);
    } else if(a.multiLineStrings) {
      m.push(["str", /^(?:'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$)|`(?:[^\\`]|\\[\S\s])*(?:`|$))/, null, "'\"`"]);
    } else {
      m.push(["str", /^(?:'(?:[^\n\r'\\]|\\.)*(?:'|$)|"(?:[^\n\r"\\]|\\.)*(?:"|$))/, null, "\"'"]);
    }
    if(a.verbatimStrings) {
      e.push(["str", /^@"(?:[^"]|"")*(?:"|$)/, null]);
    }
    var h = a.hashComments;
    if(h) {
      if(a.cStyleComments) {
        if(h > 1) {
          m.push(["com", /^#(?:##(?:[^#]|#(?!##))*(?:###|$)|.*)/, null, "#"]);
        } else {
          m.push(["com", /^#(?:(?:define|elif|else|endif|error|ifdef|include|ifndef|line|pragma|undef|warning)\b|[^\n\r]*)/, null, "#"]);
        }
        e.push(["str", /^<(?:(?:(?:\.\.\/)*|\/?)(?:[\w-]+(?:\/[\w-]+)+)?[\w-]+\.h|[a-z]\w*)>/, null]);
      } else {
        m.push(["com", /^#[^\n\r]*/, null, "#"]);
      }
    }
    if(a.cStyleComments) {
      e.push(["com", /^\/\/[^\n\r]*/, null]);
      e.push(["com", /^\/\*[\S\s]*?(?:\*\/|$)/, null]);
    }
    if(a.regexLiterals) {
      e.push(["lang-regex", /^(?:^^\.?|[!+-]|!=|!==|#|%|%=|&|&&|&&=|&=|\(|\*|\*=|\+=|,|-=|->|\/|\/=|:|::|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|[?@[^]|\^=|\^\^|\^\^=|{|\||\|=|\|\||\|\|=|~|break|case|continue|delete|do|else|finally|instanceof|return|throw|try|typeof)\s*(\/(?=[^*/])(?:[^/[\\]|\\[\S\s]|\[(?:[^\\\]]|\\[\S\s])*(?:]|$))+\/)/]);
    }
    var h = a.types;
    if(h != null) {
      e.push(["typ", h]);
    }
    a = "" + a.keywords;
    a = a.replace(/^ | $/g, "");
    if(a.length > 0) {
      e.push(["kwd", RegExp("^(?:" + a.replace(/[\s,]+/g, "|") + ")\\b"), null]);
    }
    m.push(["pln", /^\s+/, null, " \r\n\t\xa0"]);
    e.push(["lit", /^@[$_a-z][\w$@]*/i, null], ["typ", /^(?:[@_]?[A-Z]+[a-z][\w$@]*|\w+_t\b)/, null], ["pln", /^[$_a-z][\w$@]*/i, null], ["lit", /^(?:0x[\da-f]+|(?:\d(?:_\d+)*\d*(?:\.\d*)?|\.\d\+)(?:e[+-]?\d+)?)[a-z]*/i, null, "0123456789"], ["pln", /^\\[\S\s]?/, null], ["pun", /^.[^\s\w"-$'./@\\`]*/, null]);
    return x(m, e);
  }
  static function C(a:String, m:String):Dynamic {
    if(a == null || !A.exists(a)) {
      a = /^<\s*/.test(m) ? "default-markup" : "default-code";
    }
    return A.get(a);
  }
  static function E(a:Dynamic):Void {
    var m = a.g;
    try {
      var e = M(a.h);
      var h = e.a;
      a.a = h;
      a.c = e.c;
      a.d = 0;
      C(m, h)(a);
      var k = /\/\bMSIE\b/.test(haxe.Sys.get_userAgent());
      var m = /\n/g;
      var t = a.a;
      var s = t.length;
      var e = 0;
      var l = a.c;
      var p = l.length;
      var h = 0;
      var d = a.e;
      var g = d.length;
      a = 0;
      d[g] = s;
      var r:Int = 0;
      var n:Int = 0;
      while(n < g) {
        if(d[n] != d[n + 2]) {
          d[r++] = d[n++];
          d[r++] = d[n++];
        } else {
          n += 2;
        }
      }
      g = r;
      while(n < g) {
        var z = d[n];
        var f = d[n + 1];
        var b = n + 2;
        while(b + 2 <= g && d[b + 1] == f) {
          b += 2;
        }
        d[r++] = z;
        d[r++] = f;
        n = b;
      }
      d.length = r;
      while(h < p) {
        var o = l[h + 2] || s;
        var c = d[a + 2] || s;
        var b = Math.min(o, c);
        var i = l[h + 1];
        var j:String;
        if(i.nodeType != 1 && (j = t.substring(e, b))) {
          if(k) {
            j = j.replace(m, "\r");
          }
          i.nodeValue = j;
          var u = i.ownerDocument;
          var v = u.createElement("SPAN");
          v.className = d[a + 1];
          var x = i.parentNode;
          x.replaceChild(v, i);
          v.appendChild(i);
          if(e < o) {
            l[h + 1] = i = u.createTextNode(t.substring(b, o));
            x.insertBefore(i, v.nextSibling);
          }
        }
        e = b;
        if(e >= o) {
          h += 2;
        }
        if(e >= c) {
          a += 2;
        }
      }
    } catch(w) {
      if("console" in js.Lib.global) {
        if(w.stack != null) {
          haxe.Log.trace(w.stack, haxe.CallStack.last());
        } else {
          haxe.Log.trace(w, haxe.CallStack.last());
        }
      }
    }
  }
  static function M(a:Dynamic):Dynamic {
    function m(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(e.match(a.className)) {
            break;
          }
          var g:Dynamic = a.firstChild;
          while(g != null) {
            m(g);
            g = g.nextSibling;
          }
          g = a.nodeName;
          if(g == "BR" || g == "LI") {
            h[s] = "\n";
            t[s << 1] = y;
            t[s++ << 1 | 1] = a;
          }
          break;
        case 3:
        case 4:
          g = a.nodeValue;
          if(g.length > 0) {
            g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
            h[s] = g;
            t[s << 1] = y;
            y += g.length;
            t[s++ << 1 | 1] = a;
          }
          break;
      }
    }
    var e = /(?:^|\s)nocode(?:\s|$)/;
    var h = new Array();
    var y = 0;
    var t = new Array();
    var s = 0;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(js.Lib.global.getComputedStyle != null) {
        l = js.Lib.global.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    m(a);
    return {
      a: h.join("").replace(/\n$/, ""),
      c: t
    };
  }
  static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
    if(m != null) {
      a = {
        a: m,
        d: a
      };
      e(a);
      h.push.apply(h, a.e);
    }
  }
  static function L(a:Array<Dynamic>):EReg {
    function m(a:String):Int {
      var f = a.charCodeAt(0);
      if(f != 92) {
        return f;
      }
      var b = a.charAt(1);
      if(r.exists(b)) {
        return r.get(b);
      } else if("0" <= b && b <= "7") {
        return Std.parseInt(a.substring(1), 8);
      } else if(b == "u" || b == "x") {
        return Std.parseInt(a.substring(2), 16);
      } else {
        return a.charCodeAt(1);
      }
    }
    function e(a:Int):String {
      if(a < 32) {
        return (a < 16 ? "\\x0" : "\\x") + a.toString(16);
      }
      a = String.fromCharCode(a);
      if(a == "\\" || a == "-" || a == "[" || a == "]") {
        a = "\\" + a;
      }
      return a;
    }
    function h(a:String):String {
      var f = a.substring(1, a.length - 1).match(/\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\[0-3][0-7]{0,2}|\\[0-7]{1,2}|\\[\S\s]|[^\\]/g);
      var a = new Array();
      var b = new Array();
      var o = f[0] == "^";
      var c = o ? 1 : 0;
      var i = f.length;
      while(c < i) {
        var j = f[c];
        if(/\\[bdsw]/i.test(j)) {
          a.push(j);
        } else {
          var j = m(j);
          var d:Int;
          if(c + 2 < i && f[c + 1] == "-") {
            d = m(f[c + 2]);
            c += 2;
          } else {
            d = j;
          }
          b.push([j, d]);
          if(d < 65 || j > 122) {
            continue;
          }
          if(d < 65 || j > 90) {
            b.push([Math.max(65, j) | 32, Math.min(d, 90) | 32]);
          }
          if(d < 97 || j > 122) {
            b.push([Math.max(97, j) & -33, Math.min(d, 122) & -33]);
          }
        }
        c++;
      }
      b.sort(function(a:Array<Int>, f:Array<Int>):Int {
        return a[0] - f[0] || f[1] - a[1];
      });
      f = new Array();
      j = [NaN, NaN];
      for(c = 0; c < b.length; c++) {
        i = b[c];
        if(i[0] <= j[1] + 1) {
          j[1] = Math.max(j[1], i[1]);
        } else {
          f.push(j = i);
        }
      }
      b = ["["];
      if(o) {
        b.push("^");
      }
      b.push.apply(b, a);
      for(c = 0; c < f.length; c++) {
        i = f[c];
        b.push(e(i[0]));
        if(i[1] > i[0]) {
          if(i[1] + 1 > i[0]) {
            b.push("-");
          }
          b.push(e(i[1]));
        }
      }
      b.push("]");
      return b.join("");
    }
    function y(a:Dynamic):String {
      var f = a.source.match(/\[(?:[^\\\]]|\\[\S\s])*]|\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\\d+|\\[^\dux]|\(\?[!:=]|[()^]|[^()[\\^]+/g);
      var b = f.length;
      var d = new Array();
      var c = 0;
      var i = 0;
      while(c < b) {
        var j = f[c];
        if(j == "(") {
          i++;
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            d[j] = -1;
          }
        }
        c++;
      }
      for(c = 1; c < d.length; c++) {
        if(d[c] == -1) {
          d[c] = ++t;
        }
      }
      for(i = c = 0; c < b; c++) {
        j = f[c];
        if(j == "(") {
          i++;
          if(d[i] == null) {
            f[c] = "(?:";
          }
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            f[c] = "\\" + d[i];
          }
        }
      }
      for(i = c = 0; c < b; c++) {
        if(f[c] == "^" && f[c + 1] != "^") {
          f[c] = "";
        }
      }
      if(a.ignoreCase && s) {
        for(c = 0; c < b; c++) {
          j = f[c];
          a = j.charAt(0);
          if(j.length >= 2 && a == "[") {
            f[c] = h(j);
          } else if(a != "\\") {
            f[c] = j.replace(/[A-Za-z]/g, function(a:String):String {
              a = a.charCodeAt(0);
              return "[" + String.fromCharCode(a & -33, a | 32) + "]";
            });
          }
        }
      }
      return f.join("");
    }
    var t = 0;
    var s = false;
    var l = false;
    var p = 0;
    var d = a.length;
    while(p < d) {
      var g = a[p];
      if(g.ignoreCase) {
        l = true;
      } else if(/[a-z]/i.test(g.source.replace(/\\u[\da-f]{4}|\\x[\da-f]{2}|\\[^UXux]/gi, ""))) {
        s = true;
        l = false;
        break;
      }
      p++;
    }
    var r:haxe.ds.StringMap = new haxe.ds.StringMap();
    r.set("b", 8);
    r.set("t", 9);
    r.set("n", 10);
    r.set("v", 11);
    r.set("f", 12);
    r.set("r", 13);
    var n = new Array();
    p = 0;
    d = a.length;
    while(p < d) {
      g = a[p];
      if(g.global || g.multiline) {
        throw new Error("" + g);
      }
      n.push("(?:" + y(g) + ")");
      p++;
    }
    return RegExp(n.join("|"), l ? "gi" : "g");
  }
  static function D(a:Dynamic, m:Dynamic):Void {
    function e(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(k.match(a.className)) {
            break;
          }
          if(a.nodeName == "BR") {
            h(a);
            if(a.parentNode != null) {
              a.parentNode.removeChild(a);
            }
          } else {
            var a:Dynamic = a.firstChild;
            while(a != null) {
              e(a);
              a = a.nextSibling;
            }
          }
          break;
        case 3:
        case 4:
          if(p) {
            var b = a.nodeValue;
            var d = b.match(t);
            if(d != null) {
              var c = b.substring(0, d.index);
              a.nodeValue = c;
              var b = b.substring(d.index + d[0].length);
              if(b != null) {
                a.parentNode.insertBefore(s.createTextNode(b), a.nextSibling);
              }
              h(a);
              if(c == null) {
                a.parentNode.removeChild(a);
              }
            }
          }
          break;
      }
    }
    function h(a:Dynamic):Void {
      function b(a:Dynamic, d:Bool):Dynamic {
        var e = d ? a.cloneNode(false) : a;
        var f = a.parentNode;
        if(f != null) {
          var f = b(f, true);
          var g = a.nextSibling;
          f.appendChild(e);
          var h = g;
          while(h != null) {
            g = h.nextSibling;
            f.appendChild(h);
            h = g;
          }
        }
        return e;
      }
      while(a.nextSibling == null) {
        if(a = a.parentNode, a == null) {
          return;
        }
      }
      var a = b(a.nextSibling, false);
      var e:Dynamic;
      while((e = a.parentNode) != null && e.nodeType == 1) {
        a = e;
      }
      d.push(a);
    }
    var k = /(?:^|\s)nocode(?:\s|$)/;
    var t = /\r\n?|\n/;
    var s = a.ownerDocument;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(s.defaultView != null && s.defaultView.getComputedStyle != null) {
        l = s.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    var l = s.createElement("LI");
    while(a.firstChild != null) {
      l.appendChild(a.firstChild);
    }
    var d = new Array();
    d.push(l);
    var g = 0;
    var z = d.length;
    while(g < z) {
      e(d[g]);
      g++;
    }
    m = m | 0;
    if(m != 0) {
      d[0].setAttribute("value", m);
    }
    var r = s.createElement("OL");
    r.className = "linenums";
    var n = Math.max(0, m - 1 | 0) || 0;
    g = 0;
    z = d.length;
    while(g < z) {
      l = d[g];
      l.className = "L" + (g + n) % 10;
      if(l.firstChild == null) {
        l.appendChild(s.createTextNode("\xa0"));
      }
      r.appendChild(l);
      g++;
    }
    a.appendChild(r);
  }
  static function prettyPrintOne(a:String, m:String, e:Dynamic):String {
    var h = js.Lib.document.createElement("PRE");
    h.innerHTML = a;
    if(e != null) {
      D(h, e);
    }
    E({
      g: m,
      i: e,
      h: h
    });
    return h.innerHTML;
  }
  static function prettyPrint(a:Dynamic):Void {
    function m():Void {
      var e:Float = window.PR_SHOULD_USE_CONTINUATION ? Date.now() + 250 : Infinity;
      while(p < h.length && Date.now() < e) {
        var n = h[p];
        var k = n.className;
        if(k.indexOf("prettyprint") >= 0) {
          var k = k.match(g);
          var f:Dynamic;
          var b:Bool;
          if(b = !k) {
            b = n;
            var o:Dynamic = null;
            var c:Dynamic = b.firstChild;
            while(c != null) {
              var i = c.nodeType;
              o = i == 1 ? (o != null ? b : c) : (i == 3 ? (N.test(c.nodeValue) ? b : o) : o);
              c = c.nextSibling;
            }
            b = (f = o == b ? null : o) && f.tagName == "CODE";
          }
          if(b) {
            k = f.className.match(g);
          }
          if(k != null) {
            k = k[1];
          }
          b = false;
          var o:Dynamic = n.parentNode;
          while(o != null) {
            if((o.tagName == "pre" || o.tagName == "code" || o.tagName == "xmp") && o.className != null && o.className.indexOf("prettyprint") >= 0) {
              b = true;
              break;
            }
            o = o.parentNode;
          }
          if(!b) {
            b = (b = n.className.match(/\blinenums\b(?::(\d+))?/)) ? (b[1] != null && b[1].length > 0 ? Std.parseInt(b[1]) : true) : false;
            if(b) {
              D(n, b);
              d = {
                g: k,
                h: n,
                i: b
              };
              E(d);
            }
          }
        }
        p++;
      }
      if(p < h.length) {
        js.Lib.setTimeout(m, 250);
      } else if(a != null) {
        a();
      }
    }
    var e = new Array();
    e.push(js.Lib.document.getElementsByTagName("pre"));
    e.push(js.Lib.document.getElementsByTagName("code"));
    e.push(js.Lib.document.getElementsByTagName("xmp"));
    var h = new Array();
    var k = 0;
    var t = e.length;
    while(k < t) {
      var s = 0;
      var z = e[k].length;
      while(s < z) {
        h.push(e[k][s]);
        s++;
      }
      k++;
    }
    var e:Dynamic = q;
    var l:Dynamic = Date;
    if(l.now == null) {
      l = {
        now: function():Float {
          return Date.now();
        }
      };
    }
    var p = 0;
    var d:Dynamic;
    var g = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    m();
  }
  static var PR_ATTRIB_NAME:String = "atn";
  static var PR_ATTRIB_VALUE:String = "atv";
  static var PR_COMMENT:String = "com";
  static var PR_DECLARATION:String = "dec";
  static var PR_KEYWORD:String = "kwd";
  static var PR_LITERAL:String = "lit";
  static var PR_NOCODE:String = "nocode";
  static var PR_PLAIN:String = "pln";
  static var PR_PUNCTUATION:String = "pun";
  static var PR_SOURCE:String = "src";
  static var PR_STRING:String = "str";
  static var PR_TAG:String = "tag";
  static var PR_TYPE:String = "typ";
}
var q = null;
window.PR_SHOULD_USE_CONTINUATION = true;
function main() {
  var v = ["break", "continue", "do", "else", "for", "if", "return", "while"];
  var w = [[v, "auto,case,char,const,default,double,enum,extern,float,goto,int,long,register,short,signed,sizeof,static,struct,switch,typedef,union,unsigned,void,volatile"], "catch,class,delete,false,import,new,operator,private,protected,public,this,throw,true,try,typeof"];
  var F = [w, "alignof,align_union,asm,axiom,bool,concept,concept_map,const_cast,constexpr,decltype,dynamic_cast,explicit,export,friend,inline,late_check,mutable,namespace,nullptr,reinterpret_cast,static_assert,static_cast,template,typeid,typename,using,virtual,where"];
  var G = [w, "abstract,boolean,byte,extends,final,finally,implements,import,instanceof,null,native,package,strictfp,super,synchronized,throws,transient"];
  var H = [G, "as,base,by,checked,decimal,delegate,descending,dynamic,event,fixed,foreach,from,group,implicit,in,interface,internal,into,is,lock,object,out,override,orderby,params,partial,readonly,ref,sbyte,sealed,stackalloc,string,select,uint,ulong,unchecked,unsafe,ushort,var"];
  w = [w, "debugger,eval,export,function,get,null,set,undefined,var,with,Infinity,NaN"];
  var I = [v, "and,as,assert,class,def,del,elif,except,exec,finally,from,global,import,in,is,lambda,nonlocal,not,or,pass,print,raise,try,with,yield,False,True,None"];
  var J = [v, "alias,and,begin,case,class,def,defined,elsif,end,ensure,false,in,module,next,nil,not,or,redo,rescue,retry,self,super,then,true,undef,unless,until,when,yield,BEGIN,END"];
  v = [v, "case,done,elif,esac,eval,fi,function,in,local,set,then,until"];
  var K = /^(DIR|FILE|vector|(de|priority_)?queue|list|stack|(const_)?iterator|(multi)?(set|map)|bitset|u?(int|float)\d*)/;
  var N = /\S/;
  var O = PR.sourceDecorator({
    keywords: [F, H, w, "caller,delete,die,do,dump,elsif,eval,exit,foreach,for,goto,if,import,last,local,my,next,no,our,print,package,redo,require,sub,undef,unless,until,use,wantarray,while,BEGIN,END" + I, J, v],
    hashComments: true,
    c
class PR {
  static function createSimpleLexer(a:Array<Array<String>>, m:Array<Array<String>>):Dynamic {
    function e(a:Dynamic):Void {
      var l = a.d;
      var p = [l, "pln"];
      var d = 0;
      var g = a.a.match(y) || [];
      var r = new haxe.ds.StringMap();
      var n = 0;
      var z = g.length;
      while(n < z) {
        var f = g[n];
        var b = r.get(f);
        var o = null;
        var c:Bool;
        if(typeof b == "string") c = false;
        else {
          var i = h.get(f.charAt(0));
          if(i != null) {
            o = f.match(i[1]);
            b = i[0];
          } else {
            for(c = 0; c < t; c++) {
              var i = m[c];
              var o = f.match(i[1]);
              if(o != null) {
                b = i[0];
                break;
              }
            }
            if(o == null) b = "pln";
          }
          if((c = b.length >= 5 && b.substring(0, 5) == "lang-") && !(o != null && typeof o[1] == "string")) {
            c = false;
            b = "src";
          }
          if(!c) r.set(f, b);
        }
        i = d;
        d += f.length;
        if(c) {
          c = o[1];
          var j = f.indexOf(c);
          var k = j + c.length;
          if(o[2] != null) {
            k = f.length - o[2].length;
            j = k - c.length;
          }
          b = b.substring(5);
          B(l + i, f.substring(0, j), e, p);
          B(l + i + j, c, C(b, c), p);
          B(l + i + k, f.substring(k), e, p);
        } else p.push(l + i, b);
        n++;
      }
      a.e = p;
    }
    function h:haxe.ds.StringMap = new haxe.ds.StringMap();
    var y:EReg;
    (function() {
      var e = a.concat(m);
      var l = new Array();
      var p = new haxe.ds.StringMap();
      var d = 0;
      var g = e.length;
      while(d < g) {
        var r = e[d];
        var n = r[3];
        if(n != null) {
          var k = n.length;
          while(--k >= 0) h.set(n.charAt(k), r);
        }
        r = r[1];
        n = "" + r;
        if(!p.exists(n)) {
          l.push(r);
          p.set(n, null);
        }
        d++;
      }
      l.push(/[\S\s]/);
      y = L(l);
    })();
    var t = m.length;
    return e;
  }
  static function registerLangHandler(a:Dynamic, m:Array<String>):Void {
    var e = m.length;
    while(--e >= 0) {
      var h = m[e];
      if(A.exists(h)) {
        if(haxe.CallStack.last().get_name() == "console") {
          haxe.Log.trace("cannot override language handler " + h, haxe.CallStack.last());
        }
      } else A.set(h, a);
    }
  }
  static function sourceDecorator(a:Dynamic):Dynamic {
    var m = new Array();
    var e = new Array();
    if(a.tripleQuotedStrings) {
      m.push(["str", /^(?:'''(?:[^'\\]|\\[\S\s]|''?(?=[^']))*(?:'''|$)|"""(?:[^"\\]|\\[\S\s]|""?(?=[^"]))*(?:"""|$)|'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$))/, null, "'\"'"]);
    } else if(a.multiLineStrings) {
      m.push(["str", /^(?:'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$)|`(?:[^\\`]|\\[\S\s])*(?:`|$))/, null, "'\"`"]);
    } else {
      m.push(["str", /^(?:'(?:[^\n\r'\\]|\\.)*(?:'|$)|"(?:[^\n\r"\\]|\\.)*(?:"|$))/, null, "\"'"]);
    }
    if(a.verbatimStrings) {
      e.push(["str", /^@"(?:[^"]|"")*(?:"|$)/, null]);
    }
    var h = a.hashComments;
    if(h) {
      if(a.cStyleComments) {
        if(h > 1) {
          m.push(["com", /^#(?:##(?:[^#]|#(?!##))*(?:###|$)|.*)/, null, "#"]);
        } else {
          m.push(["com", /^#(?:(?:define|elif|else|endif|error|ifdef|include|ifndef|line|pragma|undef|warning)\b|[^\n\r]*)/, null, "#"]);
        }
        e.push(["str", /^<(?:(?:(?:\.\.\/)*|\/?)(?:[\w-]+(?:\/[\w-]+)+)?[\w-]+\.h|[a-z]\w*)>/, null]);
      } else {
        m.push(["com", /^#[^\n\r]*/, null, "#"]);
      }
    }
    if(a.cStyleComments) {
      e.push(["com", /^\/\/[^\n\r]*/, null]);
      e.push(["com", /^\/\*[\S\s]*?(?:\*\/|$)/, null]);
    }
    if(a.regexLiterals) {
      e.push(["lang-regex", /^(?:^^\.?|[!+-]|!=|!==|#|%|%=|&|&&|&&=|&=|\(|\*|\*=|\+=|,|-=|->|\/|\/=|:|::|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|[?@[^]|\^=|\^\^|\^\^=|{|\||\|=|\|\||\|\|=|~|break|case|continue|delete|do|else|finally|instanceof|return|throw|try|typeof)\s*(\/(?=[^*/])(?:[^/[\\]|\\[\S\s]|\[(?:[^\\\]]|\\[\S\s])*(?:]|$))+\/)/]);
    }
    var h = a.types;
    if(h != null) {
      e.push(["typ", h]);
    }
    a = "" + a.keywords;
    a = a.replace(/^ | $/g, "");
    if(a.length > 0) {
      e.push(["kwd", RegExp("^(?:" + a.replace(/[\s,]+/g, "|") + ")\\b"), null]);
    }
    m.push(["pln", /^\s+/, null, " \r\n\t\xa0"]);
    e.push(["lit", /^@[$_a-z][\w$@]*/i, null], ["typ", /^(?:[@_]?[A-Z]+[a-z][\w$@]*|\w+_t\b)/, null], ["pln", /^[$_a-z][\w$@]*/i, null], ["lit", /^(?:0x[\da-f]+|(?:\d(?:_\d+)*\d*(?:\.\d*)?|\.\d\+)(?:e[+-]?\d+)?)[a-z]*/i, null, "0123456789"], ["pln", /^\\[\S\s]?/, null], ["pun", /^.[^\s\w"-$'./@\\`]*/, null]);
    return x(m, e);
  }
  static function C(a:String, m:String):Dynamic {
    if(a == null || !A.exists(a)) {
      a = /^<\s*/.test(m) ? "default-markup" : "default-code";
    }
    return A.get(a);
  }
  static function E(a:Dynamic):Void {
    var m = a.g;
    try {
      var e = M(a.h);
      var h = e.a;
      a.a = h;
      a.c = e.c;
      a.d = 0;
      C(m, h)(a);
      var k = /\/\bMSIE\b/.test(haxe.Sys.get_userAgent());
      var m = /\n/g;
      var t = a.a;
      var s = t.length;
      var e = 0;
      var l = a.c;
      var p = l.length;
      var h = 0;
      var d = a.e;
      var g = d.length;
      a = 0;
      d[g] = s;
      var r:Int = 0;
      var n:Int = 0;
      while(n < g) {
        if(d[n] != d[n + 2]) {
          d[r++] = d[n++];
          d[r++] = d[n++];
        } else {
          n += 2;
        }
      }
      g = r;
      while(n < g) {
        var z = d[n];
        var f = d[n + 1];
        var b = n + 2;
        while(b + 2 <= g && d[b + 1] == f) {
          b += 2;
        }
        d[r++] = z;
        d[r++] = f;
        n = b;
      }
      d.length = r;
      while(h < p) {
        var o = l[h + 2] || s;
        var c = d[a + 2] || s;
        var b = Math.min(o, c);
        var i = l[h + 1];
        var j:String;
        if(i.nodeType != 1 && (j = t.substring(e, b))) {
          if(k) {
            j = j.replace(m, "\r");
          }
          i.nodeValue = j;
          var u = i.ownerDocument;
          var v = u.createElement("SPAN");
          v.className = d[a + 1];
          var x = i.parentNode;
          x.replaceChild(v, i);
          v.appendChild(i);
          if(e < o) {
            l[h + 1] = i = u.createTextNode(t.substring(b, o));
            x.insertBefore(i, v.nextSibling);
          }
        }
        e = b;
        if(e >= o) {
          h += 2;
        }
        if(e >= c) {
          a += 2;
        }
      }
    } catch(w) {
      if("console" in js.Lib.global) {
        if(w.stack != null) {
          haxe.Log.trace(w.stack, haxe.CallStack.last());
        } else {
          haxe.Log.trace(w, haxe.CallStack.last());
        }
      }
    }
  }
  static function M(a:Dynamic):Dynamic {
    function m(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(e.match(a.className)) {
            break;
          }
          var g:Dynamic = a.firstChild;
          while(g != null) {
            m(g);
            g = g.nextSibling;
          }
          g = a.nodeName;
          if(g == "BR" || g == "LI") {
            h[s] = "\n";
            t[s << 1] = y;
            t[s++ << 1 | 1] = a;
          }
          break;
        case 3:
        case 4:
          g = a.nodeValue;
          if(g.length > 0) {
            g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
            h[s] = g;
            t[s << 1] = y;
            y += g.length;
            t[s++ << 1 | 1] = a;
          }
          break;
      }
    }
    var e = /(?:^|\s)nocode(?:\s|$)/;
    var h = new Array();
    var y = 0;
    var t = new Array();
    var s = 0;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(js.Lib.global.getComputedStyle != null) {
        l = js.Lib.global.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    m(a);
    return {
      a: h.join("").replace(/\n$/, ""),
      c: t
    };
  }
  static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
    if(m != null) {
      a = {
        a: m,
        d: a
      };
      e(a);
      h.push.apply(h, a.e);
    }
  }
  static function L(a:Array<Dynamic>):EReg {
    function m(a:String):Int {
      var f = a.charCodeAt(0);
      if(f != 92) {
        return f;
      }
      var b = a.charAt(1);
      if(r.exists(b)) {
        return r.get(b);
      } else if("0" <= b && b <= "7") {
        return Std.parseInt(a.substring(1), 8);
      } else if(b == "u" || b == "x") {
        return Std.parseInt(a.substring(2), 16);
      } else {
        return a.charCodeAt(1);
      }
    }
    function e(a:Int):String {
      if(a < 32) {
        return (a < 16 ? "\\x0" : "\\x") + a.toString(16);
      }
      a = String.fromCharCode(a);
      if(a == "\\" || a == "-" || a == "[" || a == "]") {
        a = "\\" + a;
      }
      return a;
    }
    function h(a:String):String {
      var f = a.substring(1, a.length - 1).match(/\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\[0-3][0-7]{0,2}|\\[0-7]{1,2}|\\[\S\s]|[^\\]/g);
      var a = new Array();
      var b = new Array();
      var o = f[0] == "^";
      var c = o ? 1 : 0;
      var i = f.length;
      while(c < i) {
        var j = f[c];
        if(/\\[bdsw]/i.test(j)) {
          a.push(j);
        } else {
          var j = m(j);
          var d:Int;
          if(c + 2 < i && f[c + 1] == "-") {
            d = m(f[c + 2]);
            c += 2;
          } else {
            d = j;
          }
          b.push([j, d]);
          if(d < 65 || j > 122) {
            continue;
          }
          if(d < 65 || j > 90) {
            b.push([Math.max(65, j) | 32, Math.min(d, 90) | 32]);
          }
          if(d < 97 || j > 122) {
            b.push([Math.max(97, j) & -33, Math.min(d, 122) & -33]);
          }
        }
        c++;
      }
      b.sort(function(a:Array<Int>, f:Array<Int>):Int {
        return a[0] - f[0] || f[1] - a[1];
      });
      f = new Array();
      j = [NaN, NaN];
      for(c = 0; c < b.length; c++) {
        i = b[c];
        if(i[0] <= j[1] + 1) {
          j[1] = Math.max(j[1], i[1]);
        } else {
          f.push(j = i);
        }
      }
      b = ["["];
      if(o) {
        b.push("^");
      }
      b.push.apply(b, a);
      for(c = 0; c < f.length; c++) {
        i = f[c];
        b.push(e(i[0]));
        if(i[1] > i[0]) {
          if(i[1] + 1 > i[0]) {
            b.push("-");
          }
          b.push(e(i[1]));
        }
      }
      b.push("]");
      return b.join("");
    }
    function y(a:Dynamic):String {
      var f = a.source.match(/\[(?:[^\\\]]|\\[\S\s])*]|\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\\d+|\\[^\dux]|\(\?[!:=]|[()^]|[^()[\\^]+/g);
      var b = f.length;
      var d = new Array();
      var c = 0;
      var i = 0;
      while(c < b) {
        var j = f[c];
        if(j == "(") {
          i++;
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            d[j] = -1;
          }
        }
        c++;
      }
      for(c = 1; c < d.length; c++) {
        if(d[c] == -1) {
          d[c] = ++t;
        }
      }
      for(i = c = 0; c < b; c++) {
        j = f[c];
        if(j == "(") {
          i++;
          if(d[i] == null) {
            f[c] = "(?:";
          }
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            f[c] = "\\" + d[i];
          }
        }
      }
      for(i = c = 0; c < b; c++) {
        if(f[c] == "^" && f[c + 1] != "^") {
          f[c] = "";
        }
      }
      if(a.ignoreCase && s) {
        for(c = 0; c < b; c++) {
          j = f[c];
          a = j.charAt(0);
          if(j.length >= 2 && a == "[") {
            f[c] = h(j);
          } else if(a != "\\") {
            f[c] = j.replace(/[A-Za-z]/g, function(a:String):String {
              a = a.charCodeAt(0);
              return "[" + String.fromCharCode(a & -33, a | 32) + "]";
            });
          }
        }
      }
      return f.join("");
    }
    var t = 0;
    var s = false;
    var l = false;
    var p = 0;
    var d = a.length;
    while(p < d) {
      var g = a[p];
      if(g.ignoreCase) {
        l = true;
      } else if(/[a-z]/i.test(g.source.replace(/\\u[\da-f]{4}|\\x[\da-f]{2}|\\[^UXux]/gi, ""))) {
        s = true;
        l = false;
        break;
      }
      p++;
    }
    var r:haxe.ds.StringMap = new haxe.ds.StringMap();
    r.set("b", 8);
    r.set("t", 9);
    r.set("n", 10);
    r.set("v", 11);
    r.set("f", 12);
    r.set("r", 13);
    var n = new Array();
    p = 0;
    d = a.length;
    while(p < d) {
      g = a[p];
      if(g.global || g.multiline) {
        throw new Error("" + g);
      }
      n.push("(?:" + y(g) + ")");
      p++;
    }
    return RegExp(n.join("|"), l ? "gi" : "g");
  }
  static function D(a:Dynamic, m:Dynamic):Void {
    function e(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(k.match(a.className)) {
            break;
          }
          if(a.nodeName == "BR") {
            h(a);
            if(a.parentNode != null) {
              a.parentNode.removeChild(a);
            }
          } else {
            var a:Dynamic = a.firstChild;
            while(a != null) {
              e(a);
              a = a.nextSibling;
            }
          }
          break;
        case 3:
        case 4:
          if(p) {
            var b = a.nodeValue;
            var d = b.match(t);
            if(d != null) {
              var c = b.substring(0, d.index);
              a.nodeValue = c;
              var b = b.substring(d.index + d[0].length);
              if(b != null) {
                a.parentNode.insertBefore(s.createTextNode(b), a.nextSibling);
              }
              h(a);
              if(c == null) {
                a.parentNode.removeChild(a);
              }
            }
          }
          break;
      }
    }
    function h(a:Dynamic):Void {
      function b(a:Dynamic, d:Bool):Dynamic {
        var e = d ? a.cloneNode(false) : a;
        var f = a.parentNode;
        if(f != null) {
          var f = b(f, true);
          var g = a.nextSibling;
          f.appendChild(e);
          var h = g;
          while(h != null) {
            g = h.nextSibling;
            f.appendChild(h);
            h = g;
          }
        }
        return e;
      }
      while(a.nextSibling == null) {
        if(a = a.parentNode, a == null) {
          return;
        }
      }
      var a = b(a.nextSibling, false);
      var e:Dynamic;
      while((e = a.parentNode) != null && e.nodeType == 1) {
        a = e;
      }
      d.push(a);
    }
    var k = /(?:^|\s)nocode(?:\s|$)/;
    var t = /\r\n?|\n/;
    var s = a.ownerDocument;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(s.defaultView != null && s.defaultView.getComputedStyle != null) {
        l = s.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    var l = s.createElement("LI");
    while(a.firstChild != null) {
      l.appendChild(a.firstChild);
    }
    var d = new Array();
    d.push(l);
    var g = 0;
    var z = d.length;
    while(g < z) {
      e(d[g]);
      g++;
    }
    m = m | 0;
    if(m != 0) {
      d[0].setAttribute("value", m);
    }
    var r = s.createElement("OL");
    r.className = "linenums";
    var n = Math.max(0, m - 1 | 0) || 0;
    g = 0;
    z = d.length;
    while(g < z) {
      l = d[g];
      l.className = "L" + (g + n) % 10;
      if(l.firstChild == null) {
        l.appendChild(s.createTextNode("\xa0"));
      }
      r.appendChild(l);
      g++;
    }
    a.appendChild(r);
  }
  static function prettyPrintOne(a:String, m:String, e:Dynamic):String {
    var h = js.Lib.document.createElement("PRE");
    h.innerHTML = a;
    if(e != null) {
      D(h, e);
    }
    E({
      g: m,
      i: e,
      h: h
    });
    return h.innerHTML;
  }
  static function prettyPrint(a:Dynamic):Void {
    function m():Void {
      var e:Float = window.PR_SHOULD_USE_CONTINUATION ? Date.now() + 250 : Infinity;
      while(p < h.length && Date.now() < e) {
        var n = h[p];
        var k = n.className;
        if(k.indexOf("prettyprint") >= 0) {
          var k = k.match(g);
          var f:Dynamic;
          var b:Bool;
          if(b = !k) {
            b = n;
            var o:Dynamic = null;
            var c:Dynamic = b.firstChild;
            while(c != null) {
              var i = c.nodeType;
              o = i == 1 ? (o != null ? b : c) : (i == 3 ? (N.test(c.nodeValue) ? b : o) : o);
              c = c.nextSibling;
            }
            b = (f = o == b ? null : o) && f.tagName == "CODE";
          }
          if(b) {
            k = f.className.match(g);
          }
          if(k != null) {
            k = k[1];
          }
          b = false;
          var o:Dynamic = n.parentNode;
          while(o != null) {
            if((o.tagName == "pre" || o.tagName == "code" || o.tagName == "xmp") && o.className != null && o.className.indexOf("prettyprint") >= 0) {
              b = true;
              break;
            }
            o = o.parentNode;
          }
          if(!b) {
            b = (b = n.className.match(/\blinenums\b(?::(\d+))?/)) ? (b[1] != null && b[1].length > 0 ? Std.parseInt(b[1]) : true) : false;
            if(b) {
              D(n, b);
              d = {
                g: k,
                h: n,
                i: b
              };
              E(d);
            }
          }
        }
        p++;
      }
      if(p < h.length) {
        js.Lib.setTimeout(m, 250);
      } else if(a != null) {
        a();
      }
    }
    var e = new Array();
    e.push(js.Lib.document.getElementsByTagName("pre"));
    e.push(js.Lib.document.getElementsByTagName("code"));
    e.push(js.Lib.document.getElementsByTagName("xmp"));
    var h = new Array();
    var k = 0;
    var t = e.length;
    while(k < t) {
      var s = 0;
      var z = e[k].length;
      while(s < z) {
        h.push(e[k][s]);
        s++;
      }
      k++;
    }
    var e:Dynamic = q;
    var l:Dynamic = Date;
    if(l.now == null) {
      l = {
        now: function():Float {
          return Date.now();
        }
      };
    }
    var p = 0;
    var d:Dynamic;
    var g = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    m();
  }
  static var PR_ATTRIB_NAME:String = "atn";
  static var PR_ATTRIB_VALUE:String = "atv";
  static var PR_COMMENT:String = "com";
  static var PR_DECLARATION:String = "dec";
  static var PR_KEYWORD:String = "kwd";
  static var PR_LITERAL:String = "lit";
  static var PR_NOCODE:String = "nocode";
  static var PR_PLAIN:String = "pln";
  static var PR_PUNCTUATION:String = "pun";
  static var PR_SOURCE:String = "src";
  static var PR_STRING:String = "str";
  static var PR_TAG:String = "tag";
  static var PR_TYPE:String = "typ";
}
var q = null;
window.PR_SHOULD_USE_CONTINUATION = true;
function main() {
  var v = ["break", "continue", "do", "else", "for", "if", "return", "while"];
  var w = [[v, "auto,case,char,const,default,double,enum,extern,float,goto,int,long,register,short,signed,sizeof,static,struct,switch,typedef,union,unsigned,void,volatile"], "catch,class,delete,false,import,new,operator,private,protected,public,this,throw,true,try,typeof"];
  var F = [w, "alignof,align_union,asm,axiom,bool,concept,concept_map,const_cast,constexpr,decltype,dynamic_cast,explicit,export,friend,inline,late_check,mutable,namespace,nullptr,reinterpret_cast,static_assert,static_cast,template,typeid,typename,using,virtual,where"];
  var G = [w, "abstract,boolean,byte,extends,final,finally,implements,import,instanceof,null,native,package,strictfp,super,synchronized,throws,transient"];
  var H = [G, "as,base,by,checked,decimal,delegate,descending,dynamic,event,fixed,foreach,from,group,implicit,in,interface,internal,into,is,lock,object,out,override,orderby,params,partial,readonly,ref,sbyte,sealed,stackalloc,string,select,uint,ulong,unchecked,unsafe,ushort,var"];
  w = [w, "debugger,eval,export,function,get,null,set,undefined,var,with,Infinity,NaN"];
  var I = [v, "and,as,assert,class,def,del,elif,except,exec,finally,from,global,import,in,is,lambda,nonlocal,not,or,pass,print,raise,try,with,yield,False,True,None"];
  var J = [v, "alias,and,begin,case,class,def,defined,elsif,end,ensure,false,in,module,next,nil,not,or,redo,rescue,retry,self,super,then,true,undef,unless,until,when,yield,BEGIN,END"];
  v = [v, "case,done,elif,esac,eval,fi,function,in,local,set,then,until"];
  var K = /^(DIR|FILE|vector|(de|priority_)?queue|list|stack|(const_)?iterator|(multi)?(set|map)|bitset|u?(int|float)\d*)/;
  var N = /\S/;
  var O = PR.sourceDecorator({
    keywords: [F, H, w, "caller,delete,die,do,dump,elsif,eval,exit,foreach,for,goto,if,import,last,local,my,next,no,our,print,package,redo,require,sub,undef,unless,until,use,wantarray,while,BEGIN,END" + I, J, v],
    hashComments: true,
    c
class PR {
  static function createSimpleLexer(a:Array<Array<String>>, m:Array<Array<String>>):Dynamic {
    function e(a:Dynamic):Void {
      var l = a.d;
      var p = [l, "pln"];
      var d = 0;
      var g = a.a.match(y) || [];
      var r = new haxe.ds.StringMap();
      var n = 0;
      var z = g.length;
      while(n < z) {
        var f = g[n];
        var b = r.get(f);
        var o = null;
        var c:Bool;
        if(typeof b == "string") c = false;
        else {
          var i = h.get(f.charAt(0));
          if(i != null) {
            o = f.match(i[1]);
            b = i[0];
          } else {
            for(c = 0; c < t; c++) {
              var i = m[c];
              var o = f.match(i[1]);
              if(o != null) {
                b = i[0];
                break;
              }
            }
            if(o == null) b = "pln";
          }
          if((c = b.length >= 5 && b.substring(0, 5) == "lang-") && !(o != null && typeof o[1] == "string")) {
            c = false;
            b = "src";
          }
          if(!c) r.set(f, b);
        }
        i = d;
        d += f.length;
        if(c) {
          c = o[1];
          var j = f.indexOf(c);
          var k = j + c.length;
          if(o[2] != null) {
            k = f.length - o[2].length;
            j = k - c.length;
          }
          b = b.substring(5);
          B(l + i, f.substring(0, j), e, p);
          B(l + i + j, c, C(b, c), p);
          B(l + i + k, f.substring(k), e, p);
        } else p.push(l + i, b);
        n++;
      }
      a.e = p;
    }
    function h:haxe.ds.StringMap = new haxe.ds.StringMap();
    var y:EReg;
    (function() {
      var e = a.concat(m);
      var l = new Array();
      var p = new haxe.ds.StringMap();
      var d = 0;
      var g = e.length;
      while(d < g) {
        var r = e[d];
        var n = r[3];
        if(n != null) {
          var k = n.length;
          while(--k >= 0) h.set(n.charAt(k), r);
        }
        r = r[1];
        n = "" + r;
        if(!p.exists(n)) {
          l.push(r);
          p.set(n, null);
        }
        d++;
      }
      l.push(/[\S\s]/);
      y = L(l);
    })();
    var t = m.length;
    return e;
  }
  static function registerLangHandler(a:Dynamic, m:Array<String>):Void {
    var e = m.length;
    while(--e >= 0) {
      var h = m[e];
      if(A.exists(h)) {
        if(haxe.CallStack.last().get_name() == "console") {
          haxe.Log.trace("cannot override language handler " + h, haxe.CallStack.last());
        }
      } else A.set(h, a);
    }
  }
  static function sourceDecorator(a:Dynamic):Dynamic {
    var m = new Array();
    var e = new Array();
    if(a.tripleQuotedStrings) {
      m.push(["str", /^(?:'''(?:[^'\\]|\\[\S\s]|''?(?=[^']))*(?:'''|$)|"""(?:[^"\\]|\\[\S\s]|""?(?=[^"]))*(?:"""|$)|'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$))/, null, "'\"'"]);
    } else if(a.multiLineStrings) {
      m.push(["str", /^(?:'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$)|`(?:[^\\`]|\\[\S\s])*(?:`|$))/, null, "'\"`"]);
    } else {
      m.push(["str", /^(?:'(?:[^\n\r'\\]|\\.)*(?:'|$)|"(?:[^\n\r"\\]|\\.)*(?:"|$))/, null, "\"'"]);
    }
    if(a.verbatimStrings) {
      e.push(["str", /^@"(?:[^"]|"")*(?:"|$)/, null]);
    }
    var h = a.hashComments;
    if(h) {
      if(a.cStyleComments) {
        if(h > 1) {
          m.push(["com", /^#(?:##(?:[^#]|#(?!##))*(?:###|$)|.*)/, null, "#"]);
        } else {
          m.push(["com", /^#(?:(?:define|elif|else|endif|error|ifdef|include|ifndef|line|pragma|undef|warning)\b|[^\n\r]*)/, null, "#"]);
        }
        e.push(["str", /^<(?:(?:(?:\.\.\/)*|\/?)(?:[\w-]+(?:\/[\w-]+)+)?[\w-]+\.h|[a-z]\w*)>/, null]);
      } else {
        m.push(["com", /^#[^\n\r]*/, null, "#"]);
      }
    }
    if(a.cStyleComments) {
      e.push(["com", /^\/\/[^\n\r]*/, null]);
      e.push(["com", /^\/\*[\S\s]*?(?:\*\/|$)/, null]);
    }
    if(a.regexLiterals) {
      e.push(["lang-regex", /^(?:^^\.?|[!+-]|!=|!==|#|%|%=|&|&&|&&=|&=|\(|\*|\*=|\+=|,|-=|->|\/|\/=|:|::|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|[?@[^]|\^=|\^\^|\^\^=|{|\||\|=|\|\||\|\|=|~|break|case|continue|delete|do|else|finally|instanceof|return|throw|try|typeof)\s*(\/(?=[^*/])(?:[^/[\\]|\\[\S\s]|\[(?:[^\\\]]|\\[\S\s])*(?:]|$))+\/)/]);
    }
    var h = a.types;
    if(h != null) {
      e.push(["typ", h]);
    }
    a = "" + a.keywords;
    a = a.replace(/^ | $/g, "");
    if(a.length > 0) {
      e.push(["kwd", RegExp("^(?:" + a.replace(/[\s,]+/g, "|") + ")\\b"), null]);
    }
    m.push(["pln", /^\s+/, null, " \r\n\t\xa0"]);
    e.push(["lit", /^@[$_a-z][\w$@]*/i, null], ["typ", /^(?:[@_]?[A-Z]+[a-z][\w$@]*|\w+_t\b)/, null], ["pln", /^[$_a-z][\w$@]*/i, null], ["lit", /^(?:0x[\da-f]+|(?:\d(?:_\d+)*\d*(?:\.\d*)?|\.\d\+)(?:e[+-]?\d+)?)[a-z]*/i, null, "0123456789"], ["pln", /^\\[\S\s]?/, null], ["pun", /^.[^\s\w"-$'./@\\`]*/, null]);
    return x(m, e);
  }
  static function C(a:String, m:String):Dynamic {
    if(a == null || !A.exists(a)) {
      a = /^<\s*/.test(m) ? "default-markup" : "default-code";
    }
    return A.get(a);
  }
  static function E(a:Dynamic):Void {
    var m = a.g;
    try {
      var e = M(a.h);
      var h = e.a;
      a.a = h;
      a.c = e.c;
      a.d = 0;
      C(m, h)(a);
      var k = /\/\bMSIE\b/.test(haxe.Sys.get_userAgent());
      var m = /\n/g;
      var t = a.a;
      var s = t.length;
      var e = 0;
      var l = a.c;
      var p = l.length;
      var h = 0;
      var d = a.e;
      var g = d.length;
      a = 0;
      d[g] = s;
      var r:Int = 0;
      var n:Int = 0;
      while(n < g) {
        if(d[n] != d[n + 2]) {
          d[r++] = d[n++];
          d[r++] = d[n++];
        } else {
          n += 2;
        }
      }
      g = r;
      while(n < g) {
        var z = d[n];
        var f = d[n + 1];
        var b = n + 2;
        while(b + 2 <= g && d[b + 1] == f) {
          b += 2;
        }
        d[r++] = z;
        d[r++] = f;
        n = b;
      }
      d.length = r;
      while(h < p) {
        var o = l[h + 2] || s;
        var c = d[a + 2] || s;
        var b = Math.min(o, c);
        var i = l[h + 1];
        var j:String;
        if(i.nodeType != 1 && (j = t.substring(e, b))) {
          if(k) {
            j = j.replace(m, "\r");
          }
          i.nodeValue = j;
          var u = i.ownerDocument;
          var v = u.createElement("SPAN");
          v.className = d[a + 1];
          var x = i.parentNode;
          x.replaceChild(v, i);
          v.appendChild(i);
          if(e < o) {
            l[h + 1] = i = u.createTextNode(t.substring(b, o));
            x.insertBefore(i, v.nextSibling);
          }
        }
        e = b;
        if(e >= o) {
          h += 2;
        }
        if(e >= c) {
          a += 2;
        }
      }
    } catch(w) {
      if("console" in js.Lib.global) {
        if(w.stack != null) {
          haxe.Log.trace(w.stack, haxe.CallStack.last());
        } else {
          haxe.Log.trace(w, haxe.CallStack.last());
        }
      }
    }
  }
  static function M(a:Dynamic):Dynamic {
    function m(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(e.match(a.className)) {
            break;
          }
          var g:Dynamic = a.firstChild;
          while(g != null) {
            m(g);
            g = g.nextSibling;
          }
          g = a.nodeName;
          if(g == "BR" || g == "LI") {
            h[s] = "\n";
            t[s << 1] = y;
            t[s++ << 1 | 1] = a;
          }
          break;
        case 3:
        case 4:
          g = a.nodeValue;
          if(g.length > 0) {
            g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
            h[s] = g;
            t[s << 1] = y;
            y += g.length;
            t[s++ << 1 | 1] = a;
          }
          break;
      }
    }
    var e = /(?:^|\s)nocode(?:\s|$)/;
    var h = new Array();
    var y = 0;
    var t = new Array();
    var s = 0;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(js.Lib.global.getComputedStyle != null) {
        l = js.Lib.global.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    m(a);
    return {
      a: h.join("").replace(/\n$/, ""),
      c: t
    };
  }
  static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
    if(m != null) {
      a = {
        a: m,
        d: a
      };
      e(a);
      h.push.apply(h, a.e);
    }
  }
  static function L(a:Array<Dynamic>):EReg {
    function m(a:String):Int {
      var f = a.charCodeAt(0);
      if(f != 92) {
        return f;
      }
      var b = a.charAt(1);
      if(r.exists(b)) {
        return r.get(b);
      } else if("0" <= b && b <= "7") {
        return Std.parseInt(a.substring(1), 8);
      } else if(b == "u" || b == "x") {
        return Std.parseInt(a.substring(2), 16);
      } else {
        return a.charCodeAt(1);
      }
    }
    function e(a:Int):String {
      if(a < 32) {
        return (a < 16 ? "\\x0" : "\\x") + a.toString(16);
      }
      a = String.fromCharCode(a);
      if(a == "\\" || a == "-" || a == "[" || a == "]") {
        a = "\\" + a;
      }
      return a;
    }
    function h(a:String):String {
      var f = a.substring(1, a.length - 1).match(/\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\[0-3][0-7]{0,2}|\\[0-7]{1,2}|\\[\S\s]|[^\\]/g);
      var a = new Array();
      var b = new Array();
      var o = f[0] == "^";
      var c = o ? 1 : 0;
      var i = f.length;
      while(c < i) {
        var j = f[c];
        if(/\\[bdsw]/i.test(j)) {
          a.push(j);
        } else {
          var j = m(j);
          var d:Int;
          if(c + 2 < i && f[c + 1] == "-") {
            d = m(f[c + 2]);
            c += 2;
          } else {
            d = j;
          }
          b.push([j, d]);
          if(d < 65 || j > 122) {
            continue;
          }
          if(d < 65 || j > 90) {
            b.push([Math.max(65, j) | 32, Math.min(d, 90) | 32]);
          }
          if(d < 97 || j > 122) {
            b.push([Math.max(97, j) & -33, Math.min(d, 122) & -33]);
          }
        }
        c++;
      }
      b.sort(function(a:Array<Int>, f:Array<Int>):Int {
        return a[0] - f[0] || f[1] - a[1];
      });
      f = new Array();
      j = [NaN, NaN];
      for(c = 0; c < b.length; c++) {
        i = b[c];
        if(i[0] <= j[1] + 1) {
          j[1] = Math.max(j[1], i[1]);
        } else {
          f.push(j = i);
        }
      }
      b = ["["];
      if(o) {
        b.push("^");
      }
      b.push.apply(b, a);
      for(c = 0; c < f.length; c++) {
        i = f[c];
        b.push(e(i[0]));
        if(i[1] > i[0]) {
          if(i[1] + 1 > i[0]) {
            b.push("-");
          }
          b.push(e(i[1]));
        }
      }
      b.push("]");
      return b.join("");
    }
    function y(a:Dynamic):String {
      var f = a.source.match(/\[(?:[^\\\]]|\\[\S\s])*]|\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\\d+|\\[^\dux]|\(\?[!:=]|[()^]|[^()[\\^]+/g);
      var b = f.length;
      var d = new Array();
      var c = 0;
      var i = 0;
      while(c < b) {
        var j = f[c];
        if(j == "(") {
          i++;
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            d[j] = -1;
          }
        }
        c++;
      }
      for(c = 1; c < d.length; c++) {
        if(d[c] == -1) {
          d[c] = ++t;
        }
      }
      for(i = c = 0; c < b; c++) {
        j = f[c];
        if(j == "(") {
          i++;
          if(d[i] == null) {
            f[c] = "(?:";
          }
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            f[c] = "\\" + d[i];
          }
        }
      }
      for(i = c = 0; c < b; c++) {
        if(f[c] == "^" && f[c + 1] != "^") {
          f[c] = "";
        }
      }
      if(a.ignoreCase && s) {
        for(c = 0; c < b; c++) {
          j = f[c];
          a = j.charAt(0);
          if(j.length >= 2 && a == "[") {
            f[c] = h(j);
          } else if(a != "\\") {
            f[c] = j.replace(/[A-Za-z]/g, function(a:String):String {
              a = a.charCodeAt(0);
              return "[" + String.fromCharCode(a & -33, a | 32) + "]";
            });
          }
        }
      }
      return f.join("");
    }
    var t = 0;
    var s = false;
    var l = false;
    var p = 0;
    var d = a.length;
    while(p < d) {
      var g = a[p];
      if(g.ignoreCase) {
        l = true;
      } else if(/[a-z]/i.test(g.source.replace(/\\u[\da-f]{4}|\\x[\da-f]{2}|\\[^UXux]/gi, ""))) {
        s = true;
        l = false;
        break;
      }
      p++;
    }
    var r:haxe.ds.StringMap = new haxe.ds.StringMap();
    r.set("b", 8);
    r.set("t", 9);
    r.set("n", 10);
    r.set("v", 11);
    r.set("f", 12);
    r.set("r", 13);
    var n = new Array();
    p = 0;
    d = a.length;
    while(p < d) {
      g = a[p];
      if(g.global || g.multiline) {
        throw new Error("" + g);
      }
      n.push("(?:" + y(g) + ")");
      p++;
    }
    return RegExp(n.join("|"), l ? "gi" : "g");
  }
  static function D(a:Dynamic, m:Dynamic):Void {
    function e(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(k.match(a.className)) {
            break;
          }
          if(a.nodeName == "BR") {
            h(a);
            if(a.parentNode != null) {
              a.parentNode.removeChild(a);
            }
          } else {
            var a:Dynamic = a.firstChild;
            while(a != null) {
              e(a);
              a = a.nextSibling;
            }
          }
          break;
        case 3:
        case 4:
          if(p) {
            var b = a.nodeValue;
            var d = b.match(t);
            if(d != null) {
              var c = b.substring(0, d.index);
              a.nodeValue = c;
              var b = b.substring(d.index + d[0].length);
              if(b != null) {
                a.parentNode.insertBefore(s.createTextNode(b), a.nextSibling);
              }
              h(a);
              if(c == null) {
                a.parentNode.removeChild(a);
              }
            }
          }
          break;
      }
    }
    function h(a:Dynamic):Void {
      function b(a:Dynamic, d:Bool):Dynamic {
        var e = d ? a.cloneNode(false) : a;
        var f = a.parentNode;
        if(f != null) {
          var f = b(f, true);
          var g = a.nextSibling;
          f.appendChild(e);
          var h = g;
          while(h != null) {
            g = h.nextSibling;
            f.appendChild(h);
            h = g;
          }
        }
        return e;
      }
      while(a.nextSibling == null) {
        if(a = a.parentNode, a == null) {
          return;
        }
      }
      var a = b(a.nextSibling, false);
      var e:Dynamic;
      while((e = a.parentNode) != null && e.nodeType == 1) {
        a = e;
      }
      d.push(a);
    }
    var k = /(?:^|\s)nocode(?:\s|$)/;
    var t = /\r\n?|\n/;
    var s = a.ownerDocument;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(s.defaultView != null && s.defaultView.getComputedStyle != null) {
        l = s.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    var l = s.createElement("LI");
    while(a.firstChild != null) {
      l.appendChild(a.firstChild);
    }
    var d = new Array();
    d.push(l);
    var g = 0;
    var z = d.length;
    while(g < z) {
      e(d[g]);
      g++;
    }
    m = m | 0;
    if(m != 0) {
      d[0].setAttribute("value", m);
    }
    var r = s.createElement("OL");
    r.className = "linenums";
    var n = Math.max(0, m - 1 | 0) || 0;
    g = 0;
    z = d.length;
    while(g < z) {
      l = d[g];
      l.className = "L" + (g + n) % 10;
      if(l.firstChild == null) {
        l.appendChild(s.createTextNode("\xa0"));
      }
      r.appendChild(l);
      g++;
    }
    a.appendChild(r);
  }
  static function prettyPrintOne(a:String, m:String, e:Dynamic):String {
    var h = js.Lib.document.createElement("PRE");
    h.innerHTML = a;
    if(e != null) {
      D(h, e);
    }
    E({
      g: m,
      i: e,
      h: h
    });
    return h.innerHTML;
  }
  static function prettyPrint(a:Dynamic):Void {
    function m():Void {
      var e:Float = window.PR_SHOULD_USE_CONTINUATION ? Date.now() + 250 : Infinity;
      while(p < h.length && Date.now() < e) {
        var n = h[p];
        var k = n.className;
        if(k.indexOf("prettyprint") >= 0) {
          var k = k.match(g);
          var f:Dynamic;
          var b:Bool;
          if(b = !k) {
            b = n;
            var o:Dynamic = null;
            var c:Dynamic = b.firstChild;
            while(c != null) {
              var i = c.nodeType;
              o = i == 1 ? (o != null ? b : c) : (i == 3 ? (N.test(c.nodeValue) ? b : o) : o);
              c = c.nextSibling;
            }
            b = (f = o == b ? null : o) && f.tagName == "CODE";
          }
          if(b) {
            k = f.className.match(g);
          }
          if(k != null) {
            k = k[1];
          }
          b = false;
          var o:Dynamic = n.parentNode;
          while(o != null) {
            if((o.tagName == "pre" || o.tagName == "code" || o.tagName == "xmp") && o.className != null && o.className.indexOf("prettyprint") >= 0) {
              b = true;
              break;
            }
            o = o.parentNode;
          }
          if(!b) {
            b = (b = n.className.match(/\blinenums\b(?::(\d+))?/)) ? (b[1] != null && b[1].length > 0 ? Std.parseInt(b[1]) : true) : false;
            if(b) {
              D(n, b);
              d = {
                g: k,
                h: n,
                i: b
              };
              E(d);
            }
          }
        }
        p++;
      }
      if(p < h.length) {
        js.Lib.setTimeout(m, 250);
      } else if(a != null) {
        a();
      }
    }
    var e = new Array();
    e.push(js.Lib.document.getElementsByTagName("pre"));
    e.push(js.Lib.document.getElementsByTagName("code"));
    e.push(js.Lib.document.getElementsByTagName("xmp"));
    var h = new Array();
    var k = 0;
    var t = e.length;
    while(k < t) {
      var s = 0;
      var z = e[k].length;
      while(s < z) {
        h.push(e[k][s]);
        s++;
      }
      k++;
    }
    var e:Dynamic = q;
    var l:Dynamic = Date;
    if(l.now == null) {
      l = {
        now: function():Float {
          return Date.now();
        }
      };
    }
    var p = 0;
    var d:Dynamic;
    var g = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    m();
  }
  static var PR_ATTRIB_NAME:String = "atn";
  static var PR_ATTRIB_VALUE:String = "atv";
  static var PR_COMMENT:String = "com";
  static var PR_DECLARATION:String = "dec";
  static var PR_KEYWORD:String = "kwd";
  static var PR_LITERAL:String = "lit";
  static var PR_NOCODE:String = "nocode";
  static var PR_PLAIN:String = "pln";
  static var PR_PUNCTUATION:String = "pun";
  static var PR_SOURCE:String = "src";
  static var PR_STRING:String = "str";
  static var PR_TAG:String = "tag";
  static var PR_TYPE:String = "typ";
}
var q = null;
window.PR_SHOULD_USE_CONTINUATION = true;
function main() {
  var v = ["break", "continue", "do", "else", "for", "if", "return", "while"];
  var w = [[v, "auto,case,char,const,default,double,enum,extern,float,goto,int,long,register,short,signed,sizeof,static,struct,switch,typedef,union,unsigned,void,volatile"], "catch,class,delete,false,import,new,operator,private,protected,public,this,throw,true,try,typeof"];
  var F = [w, "alignof,align_union,asm,axiom,bool,concept,concept_map,const_cast,constexpr,decltype,dynamic_cast,explicit,export,friend,inline,late_check,mutable,namespace,nullptr,reinterpret_cast,static_assert,static_cast,template,typeid,typename,using,virtual,where"];
  var G = [w, "abstract,boolean,byte,extends,final,finally,implements,import,instanceof,null,native,package,strictfp,super,synchronized,throws,transient"];
  var H = [G, "as,base,by,checked,decimal,delegate,descending,dynamic,event,fixed,foreach,from,group,implicit,in,interface,internal,into,is,lock,object,out,override,orderby,params,partial,readonly,ref,sbyte,sealed,stackalloc,string,select,uint,ulong,unchecked,unsafe,ushort,var"];
  w = [w, "debugger,eval,export,function,get,null,set,undefined,var,with,Infinity,NaN"];
  var I = [v, "and,as,assert,class,def,del,elif,except,exec,finally,from,global,import,in,is,lambda,nonlocal,not,or,pass,print,raise,try,with,yield,False,True,None"];
  var J = [v, "alias,and,begin,case,class,def,defined,elsif,end,ensure,false,in,module,next,nil,not,or,redo,rescue,retry,self,super,then,true,undef,unless,until,when,yield,BEGIN,END"];
  v = [v, "case,done,elif,esac,eval,fi,function,in,local,set,then,until"];
  var K = /^(DIR|FILE|vector|(de|priority_)?queue|list|stack|(const_)?iterator|(multi)?(set|map)|bitset|u?(int|float)\d*)/;
  var N = /\S/;
  var O = PR.sourceDecorator({
    keywords: [F, H, w, "caller,delete,die,do,dump,elsif,eval,exit,foreach,for,goto,if,import,last,local,my,next,no,our,print,package,redo,require,sub,undef,unless,until,use,wantarray,while,BEGIN,END" + I, J, v],
    hashComments: true,
    c
class PR {
  static function createSimpleLexer(a:Array<Array<String>>, m:Array<Array<String>>):Dynamic {
    function e(a:Dynamic):Void {
      var l = a.d;
      var p = [l, "pln"];
      var d = 0;
      var g = a.a.match(y) || [];
      var r = new haxe.ds.StringMap();
      var n = 0;
      var z = g.length;
      while(n < z) {
        var f = g[n];
        var b = r.get(f);
        var o = null;
        var c:Bool;
        if(typeof b == "string") c = false;
        else {
          var i = h.get(f.charAt(0));
          if(i != null) {
            o = f.match(i[1]);
            b = i[0];
          } else {
            for(c = 0; c < t; c++) {
              var i = m[c];
              var o = f.match(i[1]);
              if(o != null) {
                b = i[0];
                break;
              }
            }
            if(o == null) b = "pln";
          }
          if((c = b.length >= 5 && b.substring(0, 5) == "lang-") && !(o != null && typeof o[1] == "string")) {
            c = false;
            b = "src";
          }
          if(!c) r.set(f, b);
        }
        i = d;
        d += f.length;
        if(c) {
          c = o[1];
          var j = f.indexOf(c);
          var k = j + c.length;
          if(o[2] != null) {
            k = f.length - o[2].length;
            j = k - c.length;
          }
          b = b.substring(5);
          B(l + i, f.substring(0, j), e, p);
          B(l + i + j, c, C(b, c), p);
          B(l + i + k, f.substring(k), e, p);
        } else p.push(l + i, b);
        n++;
      }
      a.e = p;
    }
    function h:haxe.ds.StringMap = new haxe.ds.StringMap();
    var y:EReg;
    (function() {
      var e = a.concat(m);
      var l = new Array();
      var p = new haxe.ds.StringMap();
      var d = 0;
      var g = e.length;
      while(d < g) {
        var r = e[d];
        var n = r[3];
        if(n != null) {
          var k = n.length;
          while(--k >= 0) h.set(n.charAt(k), r);
        }
        r = r[1];
        n = "" + r;
        if(!p.exists(n)) {
          l.push(r);
          p.set(n, null);
        }
        d++;
      }
      l.push(/[\S\s]/);
      y = L(l);
    })();
    var t = m.length;
    return e;
  }
  static function registerLangHandler(a:Dynamic, m:Array<String>):Void {
    var e = m.length;
    while(--e >= 0) {
      var h = m[e];
      if(A.exists(h)) {
        if(haxe.CallStack.last().get_name() == "console") {
          haxe.Log.trace("cannot override language handler " + h, haxe.CallStack.last());
        }
      } else A.set(h, a);
    }
  }
  static function sourceDecorator(a:Dynamic):Dynamic {
    var m = new Array();
    var e = new Array();
    if(a.tripleQuotedStrings) {
      m.push(["str", /^(?:'''(?:[^'\\]|\\[\S\s]|''?(?=[^']))*(?:'''|$)|"""(?:[^"\\]|\\[\S\s]|""?(?=[^"]))*(?:"""|$)|'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$))/, null, "'\"'"]);
    } else if(a.multiLineStrings) {
      m.push(["str", /^(?:'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$)|`(?:[^\\`]|\\[\S\s])*(?:`|$))/, null, "'\"`"]);
    } else {
      m.push(["str", /^(?:'(?:[^\n\r'\\]|\\.)*(?:'|$)|"(?:[^\n\r"\\]|\\.)*(?:"|$))/, null, "\"'"]);
    }
    if(a.verbatimStrings) {
      e.push(["str", /^@"(?:[^"]|"")*(?:"|$)/, null]);
    }
    var h = a.hashComments;
    if(h) {
      if(a.cStyleComments) {
        if(h > 1) {
          m.push(["com", /^#(?:##(?:[^#]|#(?!##))*(?:###|$)|.*)/, null, "#"]);
        } else {
          m.push(["com", /^#(?:(?:define|elif|else|endif|error|ifdef|include|ifndef|line|pragma|undef|warning)\b|[^\n\r]*)/, null, "#"]);
        }
        e.push(["str", /^<(?:(?:(?:\.\.\/)*|\/?)(?:[\w-]+(?:\/[\w-]+)+)?[\w-]+\.h|[a-z]\w*)>/, null]);
      } else {
        m.push(["com", /^#[^\n\r]*/, null, "#"]);
      }
    }
    if(a.cStyleComments) {
      e.push(["com", /^\/\/[^\n\r]*/, null]);
      e.push(["com", /^\/\*[\S\s]*?(?:\*\/|$)/, null]);
    }
    if(a.regexLiterals) {
      e.push(["lang-regex", /^(?:^^\.?|[!+-]|!=|!==|#|%|%=|&|&&|&&=|&=|\(|\*|\*=|\+=|,|-=|->|\/|\/=|:|::|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|[?@[^]|\^=|\^\^|\^\^=|{|\||\|=|\|\||\|\|=|~|break|case|continue|delete|do|else|finally|instanceof|return|throw|try|typeof)\s*(\/(?=[^*/])(?:[^/[\\]|\\[\S\s]|\[(?:[^\\\]]|\\[\S\s])*(?:]|$))+\/)/]);
    }
    var h = a.types;
    if(h != null) {
      e.push(["typ", h]);
    }
    a = "" + a.keywords;
    a = a.replace(/^ | $/g, "");
    if(a.length > 0) {
      e.push(["kwd", RegExp("^(?:" + a.replace(/[\s,]+/g, "|") + ")\\b"), null]);
    }
    m.push(["pln", /^\s+/, null, " \r\n\t\xa0"]);
    e.push(["lit", /^@[$_a-z][\w$@]*/i, null], ["typ", /^(?:[@_]?[A-Z]+[a-z][\w$@]*|\w+_t\b)/, null], ["pln", /^[$_a-z][\w$@]*/i, null], ["lit", /^(?:0x[\da-f]+|(?:\d(?:_\d+)*\d*(?:\.\d*)?|\.\d\+)(?:e[+-]?\d+)?)[a-z]*/i, null, "0123456789"], ["pln", /^\\[\S\s]?/, null], ["pun", /^.[^\s\w"-$'./@\\`]*/, null]);
    return x(m, e);
  }
  static function C(a:String, m:String):Dynamic {
    if(a == null || !A.exists(a)) {
      a = /^<\s*/.test(m) ? "default-markup" : "default-code";
    }
    return A.get(a);
  }
  static function E(a:Dynamic):Void {
    var m = a.g;
    try {
      var e = M(a.h);
      var h = e.a;
      a.a = h;
      a.c = e.c;
      a.d = 0;
      C(m, h)(a);
      var k = /\/\bMSIE\b/.test(haxe.Sys.get_userAgent());
      var m = /\n/g;
      var t = a.a;
      var s = t.length;
      var e = 0;
      var l = a.c;
      var p = l.length;
      var h = 0;
      var d = a.e;
      var g = d.length;
      a = 0;
      d[g] = s;
      var r:Int = 0;
      var n:Int = 0;
      while(n < g) {
        if(d[n] != d[n + 2]) {
          d[r++] = d[n++];
          d[r++] = d[n++];
        } else {
          n += 2;
        }
      }
      g = r;
      while(n < g) {
        var z = d[n];
        var f = d[n + 1];
        var b = n + 2;
        while(b + 2 <= g && d[b + 1] == f) {
          b += 2;
        }
        d[r++] = z;
        d[r++] = f;
        n = b;
      }
      d.length = r;
      while(h < p) {
        var o = l[h + 2] || s;
        var c = d[a + 2] || s;
        var b = Math.min(o, c);
        var i = l[h + 1];
        var j:String;
        if(i.nodeType != 1 && (j = t.substring(e, b))) {
          if(k) {
            j = j.replace(m, "\r");
          }
          i.nodeValue = j;
          var u = i.ownerDocument;
          var v = u.createElement("SPAN");
          v.className = d[a + 1];
          var x = i.parentNode;
          x.replaceChild(v, i);
          v.appendChild(i);
          if(e < o) {
            l[h + 1] = i = u.createTextNode(t.substring(b, o));
            x.insertBefore(i, v.nextSibling);
          }
        }
        e = b;
        if(e >= o) {
          h += 2;
        }
        if(e >= c) {
          a += 2;
        }
      }
    } catch(w) {
      if("console" in js.Lib.global) {
        if(w.stack != null) {
          haxe.Log.trace(w.stack, haxe.CallStack.last());
        } else {
          haxe.Log.trace(w, haxe.CallStack.last());
        }
      }
    }
  }
  static function M(a:Dynamic):Dynamic {
    function m(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(e.match(a.className)) {
            break;
          }
          var g:Dynamic = a.firstChild;
          while(g != null) {
            m(g);
            g = g.nextSibling;
          }
          g = a.nodeName;
          if(g == "BR" || g == "LI") {
            h[s] = "\n";
            t[s << 1] = y;
            t[s++ << 1 | 1] = a;
          }
          break;
        case 3:
        case 4:
          g = a.nodeValue;
          if(g.length > 0) {
            g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
            h[s] = g;
            t[s << 1] = y;
            y += g.length;
            t[s++ << 1 | 1] = a;
          }
          break;
      }
    }
    var e = /(?:^|\s)nocode(?:\s|$)/;
    var h = new Array();
    var y = 0;
    var t = new Array();
    var s = 0;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(js.Lib.global.getComputedStyle != null) {
        l = js.Lib.global.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    m(a);
    return {
      a: h.join("").replace(/\n$/, ""),
      c: t
    };
  }
  static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
    if(m != null) {
      a = {
        a: m,
        d: a
      };
      e(a);
      h.push.apply(h, a.e);
    }
  }
  static function L(a:Array<Dynamic>):EReg {
    function m(a:String):Int {
      var f = a.charCodeAt(0);
      if(f != 92) {
        return f;
      }
      var b = a.charAt(1);
      if(r.exists(b)) {
        return r.get(b);
      } else if("0" <= b && b <= "7") {
        return Std.parseInt(a.substring(1), 8);
      } else if(b == "u" || b == "x") {
        return Std.parseInt(a.substring(2), 16);
      } else {
        return a.charCodeAt(1);
      }
    }
    function e(a:Int):String {
      if(a < 32) {
        return (a < 16 ? "\\x0" : "\\x") + a.toString(16);
      }
      a = String.fromCharCode(a);
      if(a == "\\" || a == "-" || a == "[" || a == "]") {
        a = "\\" + a;
      }
      return a;
    }
    function h(a:String):String {
      var f = a.substring(1, a.length - 1).match(/\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\[0-3][0-7]{0,2}|\\[0-7]{1,2}|\\[\S\s]|[^\\]/g);
      var a = new Array();
      var b = new Array();
      var o = f[0] == "^";
      var c = o ? 1 : 0;
      var i = f.length;
      while(c < i) {
        var j = f[c];
        if(/\\[bdsw]/i.test(j)) {
          a.push(j);
        } else {
          var j = m(j);
          var d:Int;
          if(c + 2 < i && f[c + 1] == "-") {
            d = m(f[c + 2]);
            c += 2;
          } else {
            d = j;
          }
          b.push([j, d]);
          if(d < 65 || j > 122) {
            continue;
          }
          if(d < 65 || j > 90) {
            b.push([Math.max(65, j) | 32, Math.min(d, 90) | 32]);
          }
          if(d < 97 || j > 122) {
            b.push([Math.max(97, j) & -33, Math.min(d, 122) & -33]);
          }
        }
        c++;
      }
      b.sort(function(a:Array<Int>, f:Array<Int>):Int {
        return a[0] - f[0] || f[1] - a[1];
      });
      f = new Array();
      j = [NaN, NaN];
      for(c = 0; c < b.length; c++) {
        i = b[c];
        if(i[0] <= j[1] + 1) {
          j[1] = Math.max(j[1], i[1]);
        } else {
          f.push(j = i);
        }
      }
      b = ["["];
      if(o) {
        b.push("^");
      }
      b.push.apply(b, a);
      for(c = 0; c < f.length; c++) {
        i = f[c];
        b.push(e(i[0]));
        if(i[1] > i[0]) {
          if(i[1] + 1 > i[0]) {
            b.push("-");
          }
          b.push(e(i[1]));
        }
      }
      b.push("]");
      return b.join("");
    }
    function y(a:Dynamic):String {
      var f = a.source.match(/\[(?:[^\\\]]|\\[\S\s])*]|\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\\d+|\\[^\dux]|\(\?[!:=]|[()^]|[^()[\\^]+/g);
      var b = f.length;
      var d = new Array();
      var c = 0;
      var i = 0;
      while(c < b) {
        var j = f[c];
        if(j == "(") {
          i++;
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            d[j] = -1;
          }
        }
        c++;
      }
      for(c = 1; c < d.length; c++) {
        if(d[c] == -1) {
          d[c] = ++t;
        }
      }
      for(i = c = 0; c < b; c++) {
        j = f[c];
        if(j == "(") {
          i++;
          if(d[i] == null) {
            f[c] = "(?:";
          }
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            f[c] = "\\" + d[i];
          }
        }
      }
      for(i = c = 0; c < b; c++) {
        if(f[c] == "^" && f[c + 1] != "^") {
          f[c] = "";
        }
      }
      if(a.ignoreCase && s) {
        for(c = 0; c < b; c++) {
          j = f[c];
          a = j.charAt(0);
          if(j.length >= 2 && a == "[") {
            f[c] = h(j);
          } else if(a != "\\") {
            f[c] = j.replace(/[A-Za-z]/g, function(a:String):String {
              a = a.charCodeAt(0);
              return "[" + String.fromCharCode(a & -33, a | 32) + "]";
            });
          }
        }
      }
      return f.join("");
    }
    var t = 0;
    var s = false;
    var l = false;
    var p = 0;
    var d = a.length;
    while(p < d) {
      var g = a[p];
      if(g.ignoreCase) {
        l = true;
      } else if(/[a-z]/i.test(g.source.replace(/\\u[\da-f]{4}|\\x[\da-f]{2}|\\[^UXux]/gi, ""))) {
        s = true;
        l = false;
        break;
      }
      p++;
    }
    var r:haxe.ds.StringMap = new haxe.ds.StringMap();
    r.set("b", 8);
    r.set("t", 9);
    r.set("n", 10);
    r.set("v", 11);
    r.set("f", 12);
    r.set("r", 13);
    var n = new Array();
    p = 0;
    d = a.length;
    while(p < d) {
      g = a[p];
      if(g.global || g.multiline) {
        throw new Error("" + g);
      }
      n.push("(?:" + y(g) + ")");
      p++;
    }
    return RegExp(n.join("|"), l ? "gi" : "g");
  }
  static function D(a:Dynamic, m:Dynamic):Void {
    function e(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(k.match(a.className)) {
            break;
          }
          if(a.nodeName == "BR") {
            h(a);
            if(a.parentNode != null) {
              a.parentNode.removeChild(a);
            }
          } else {
            var a:Dynamic = a.firstChild;
            while(a != null) {
              e(a);
              a = a.nextSibling;
            }
          }
          break;
        case 3:
        case 4:
          if(p) {
            var b = a.nodeValue;
            var d = b.match(t);
            if(d != null) {
              var c = b.substring(0, d.index);
              a.nodeValue = c;
              var b = b.substring(d.index + d[0].length);
              if(b != null) {
                a.parentNode.insertBefore(s.createTextNode(b), a.nextSibling);
              }
              h(a);
              if(c == null) {
                a.parentNode.removeChild(a);
              }
            }
          }
          break;
      }
    }
    function h(a:Dynamic):Void {
      function b(a:Dynamic, d:Bool):Dynamic {
        var e = d ? a.cloneNode(false) : a;
        var f = a.parentNode;
        if(f != null) {
          var f = b(f, true);
          var g = a.nextSibling;
          f.appendChild(e);
          var h = g;
          while(h != null) {
            g = h.nextSibling;
            f.appendChild(h);
            h = g;
          }
        }
        return e;
      }
      while(a.nextSibling == null) {
        if(a = a.parentNode, a == null) {
          return;
        }
      }
      var a = b(a.nextSibling, false);
      var e:Dynamic;
      while((e = a.parentNode) != null && e.nodeType == 1) {
        a = e;
      }
      d.push(a);
    }
    var k = /(?:^|\s)nocode(?:\s|$)/;
    var t = /\r\n?|\n/;
    var s = a.ownerDocument;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(s.defaultView != null && s.defaultView.getComputedStyle != null) {
        l = s.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    var l = s.createElement("LI");
    while(a.firstChild != null) {
      l.appendChild(a.firstChild);
    }
    var d = new Array();
    d.push(l);
    var g = 0;
    var z = d.length;
    while(g < z) {
      e(d[g]);
      g++;
    }
    m = m | 0;
    if(m != 0) {
      d[0].setAttribute("value", m);
    }
    var r = s.createElement("OL");
    r.className = "linenums";
    var n = Math.max(0, m - 1 | 0) || 0;
    g = 0;
    z = d.length;
    while(g < z) {
      l = d[g];
      l.className = "L" + (g + n) % 10;
      if(l.firstChild == null) {
        l.appendChild(s.createTextNode("\xa0"));
      }
      r.appendChild(l);
      g++;
    }
    a.appendChild(r);
  }
  static function prettyPrintOne(a:String, m:String, e:Dynamic):String {
    var h = js.Lib.document.createElement("PRE");
    h.innerHTML = a;
    if(e != null) {
      D(h, e);
    }
    E({
      g: m,
      i: e,
      h: h
    });
    return h.innerHTML;
  }
  static function prettyPrint(a:Dynamic):Void {
    function m():Void {
      var e:Float = window.PR_SHOULD_USE_CONTINUATION ? Date.now() + 250 : Infinity;
      while(p < h.length && Date.now() < e) {
        var n = h[p];
        var k = n.className;
        if(k.indexOf("prettyprint") >= 0) {
          var k = k.match(g);
          var f:Dynamic;
          var b:Bool;
          if(b = !k) {
            b = n;
            var o:Dynamic = null;
            var c:Dynamic = b.firstChild;
            while(c != null) {
              var i = c.nodeType;
              o = i == 1 ? (o != null ? b : c) : (i == 3 ? (N.test(c.nodeValue) ? b : o) : o);
              c = c.nextSibling;
            }
            b = (f = o == b ? null : o) && f.tagName == "CODE";
          }
          if(b) {
            k = f.className.match(g);
          }
          if(k != null) {
            k = k[1];
          }
          b = false;
          var o:Dynamic = n.parentNode;
          while(o != null) {
            if((o.tagName == "pre" || o.tagName == "code" || o.tagName == "xmp") && o.className != null && o.className.indexOf("prettyprint") >= 0) {
              b = true;
              break;
            }
            o = o.parentNode;
          }
          if(!b) {
            b = (b = n.className.match(/\blinenums\b(?::(\d+))?/)) ? (b[1] != null && b[1].length > 0 ? Std.parseInt(b[1]) : true) : false;
            if(b) {
              D(n, b);
              d = {
                g: k,
                h: n,
                i: b
              };
              E(d);
            }
          }
        }
        p++;
      }
      if(p < h.length) {
        js.Lib.setTimeout(m, 250);
      } else if(a != null) {
        a();
      }
    }
    var e = new Array();
    e.push(js.Lib.document.getElementsByTagName("pre"));
    e.push(js.Lib.document.getElementsByTagName("code"));
    e.push(js.Lib.document.getElementsByTagName("xmp"));
    var h = new Array();
    var k = 0;
    var t = e.length;
    while(k < t) {
      var s = 0;
      var z = e[k].length;
      while(s < z) {
        h.push(e[k][s]);
        s++;
      }
      k++;
    }
    var e:Dynamic = q;
    var l:Dynamic = Date;
    if(l.now == null) {
      l = {
        now: function():Float {
          return Date.now();
        }
      };
    }
    var p = 0;
    var d:Dynamic;
    var g = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    m();
  }
  static var PR_ATTRIB_NAME:String = "atn";
  static var PR_ATTRIB_VALUE:String = "atv";
  static var PR_COMMENT:String = "com";
  static var PR_DECLARATION:String = "dec";
  static var PR_KEYWORD:String = "kwd";
  static var PR_LITERAL:String = "lit";
  static var PR_NOCODE:String = "nocode";
  static var PR_PLAIN:String = "pln";
  static var PR_PUNCTUATION:String = "pun";
  static var PR_SOURCE:String = "src";
  static var PR_STRING:String = "str";
  static var PR_TAG:String = "tag";
  static var PR_TYPE:String = "typ";
}
var q = null;
window.PR_SHOULD_USE_CONTINUATION = true;
function main() {
  var v = ["break", "continue", "do", "else", "for", "if", "return", "while"];
  var w = [[v, "auto,case,char,const,default,double,enum,extern,float,goto,int,long,register,short,signed,sizeof,static,struct,switch,typedef,union,unsigned,void,volatile"], "catch,class,delete,false,import,new,operator,private,protected,public,this,throw,true,try,typeof"];
  var F = [w, "alignof,align_union,asm,axiom,bool,concept,concept_map,const_cast,constexpr,decltype,dynamic_cast,explicit,export,friend,inline,late_check,mutable,namespace,nullptr,reinterpret_cast,static_assert,static_cast,template,typeid,typename,using,virtual,where"];
  var G = [w, "abstract,boolean,byte,extends,final,finally,implements,import,instanceof,null,native,package,strictfp,super,synchronized,throws,transient"];
  var H = [G, "as,base,by,checked,decimal,delegate,descending,dynamic,event,fixed,foreach,from,group,implicit,in,interface,internal,into,is,lock,object,out,override,orderby,params,partial,readonly,ref,sbyte,sealed,stackalloc,string,select,uint,ulong,unchecked,unsafe,ushort,var"];
  w = [w, "debugger,eval,export,function,get,null,set,undefined,var,with,Infinity,NaN"];
  var I = [v, "and,as,assert,class,def,del,elif,except,exec,finally,from,global,import,in,is,lambda,nonlocal,not,or,pass,print,raise,try,with,yield,False,True,None"];
  var J = [v, "alias,and,begin,case,class,def,defined,elsif,end,ensure,false,in,module,next,nil,not,or,redo,rescue,retry,self,super,then,true,undef,unless,until,when,yield,BEGIN,END"];
  v = [v, "case,done,elif,esac,eval,fi,function,in,local,set,then,until"];
  var K = /^(DIR|FILE|vector|(de|priority_)?queue|list|stack|(const_)?iterator|(multi)?(set|map)|bitset|u?(int|float)\d*)/;
  var N = /\S/;
  var O = PR.sourceDecorator({
    keywords: [F, H, w, "caller,delete,die,do,dump,elsif,eval,exit,foreach,for,goto,if,import,last,local,my,next,no,our,print,package,redo,require,sub,undef,unless,until,use,wantarray,while,BEGIN,END" + I, J, v],
    hashComments: true,
    c
class PR {
  static function createSimpleLexer(a:Array<Array<String>>, m:Array<Array<String>>):Dynamic {
    function e(a:Dynamic):Void {
      var l = a.d;
      var p = [l, "pln"];
      var d = 0;
      var g = a.a.match(y) || [];
      var r = new haxe.ds.StringMap();
      var n = 0;
      var z = g.length;
      while(n < z) {
        var f = g[n];
        var b = r.get(f);
        var o = null;
        var c:Bool;
        if(typeof b == "string") c = false;
        else {
          var i = h.get(f.charAt(0));
          if(i != null) {
            o = f.match(i[1]);
            b = i[0];
          } else {
            for(c = 0; c < t; c++) {
              var i = m[c];
              var o = f.match(i[1]);
              if(o != null) {
                b = i[0];
                break;
              }
            }
            if(o == null) b = "pln";
          }
          if((c = b.length >= 5 && b.substring(0, 5) == "lang-") && !(o != null && typeof o[1] == "string")) {
            c = false;
            b = "src";
          }
          if(!c) r.set(f, b);
        }
        i = d;
        d += f.length;
        if(c) {
          c = o[1];
          var j = f.indexOf(c);
          var k = j + c.length;
          if(o[2] != null) {
            k = f.length - o[2].length;
            j = k - c.length;
          }
          b = b.substring(5);
          B(l + i, f.substring(0, j), e, p);
          B(l + i + j, c, C(b, c), p);
          B(l + i + k, f.substring(k), e, p);
        } else p.push(l + i, b);
        n++;
      }
      a.e = p;
    }
    function h:haxe.ds.StringMap = new haxe.ds.StringMap();
    var y:EReg;
    (function() {
      var e = a.concat(m);
      var l = new Array();
      var p = new haxe.ds.StringMap();
      var d = 0;
      var g = e.length;
      while(d < g) {
        var r = e[d];
        var n = r[3];
        if(n != null) {
          var k = n.length;
          while(--k >= 0) h.set(n.charAt(k), r);
        }
        r = r[1];
        n = "" + r;
        if(!p.exists(n)) {
          l.push(r);
          p.set(n, null);
        }
        d++;
      }
      l.push(/[\S\s]/);
      y = L(l);
    })();
    var t = m.length;
    return e;
  }
  static function registerLangHandler(a:Dynamic, m:Array<String>):Void {
    var e = m.length;
    while(--e >= 0) {
      var h = m[e];
      if(A.exists(h)) {
        if(haxe.CallStack.last().get_name() == "console") {
          haxe.Log.trace("cannot override language handler " + h, haxe.CallStack.last());
        }
      } else A.set(h, a);
    }
  }
  static function sourceDecorator(a:Dynamic):Dynamic {
    var m = new Array();
    var e = new Array();
    if(a.tripleQuotedStrings) {
      m.push(["str", /^(?:'''(?:[^'\\]|\\[\S\s]|''?(?=[^']))*(?:'''|$)|"""(?:[^"\\]|\\[\S\s]|""?(?=[^"]))*(?:"""|$)|'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$))/, null, "'\"'"]);
    } else if(a.multiLineStrings) {
      m.push(["str", /^(?:'(?:[^'\\]|\\[\S\s])*(?:'|$)|"(?:[^"\\]|\\[\S\s])*(?:"|$)|`(?:[^\\`]|\\[\S\s])*(?:`|$))/, null, "'\"`"]);
    } else {
      m.push(["str", /^(?:'(?:[^\n\r'\\]|\\.)*(?:'|$)|"(?:[^\n\r"\\]|\\.)*(?:"|$))/, null, "\"'"]);
    }
    if(a.verbatimStrings) {
      e.push(["str", /^@"(?:[^"]|"")*(?:"|$)/, null]);
    }
    var h = a.hashComments;
    if(h) {
      if(a.cStyleComments) {
        if(h > 1) {
          m.push(["com", /^#(?:##(?:[^#]|#(?!##))*(?:###|$)|.*)/, null, "#"]);
        } else {
          m.push(["com", /^#(?:(?:define|elif|else|endif|error|ifdef|include|ifndef|line|pragma|undef|warning)\b|[^\n\r]*)/, null, "#"]);
        }
        e.push(["str", /^<(?:(?:(?:\.\.\/)*|\/?)(?:[\w-]+(?:\/[\w-]+)+)?[\w-]+\.h|[a-z]\w*)>/, null]);
      } else {
        m.push(["com", /^#[^\n\r]*/, null, "#"]);
      }
    }
    if(a.cStyleComments) {
      e.push(["com", /^\/\/[^\n\r]*/, null]);
      e.push(["com", /^\/\*[\S\s]*?(?:\*\/|$)/, null]);
    }
    if(a.regexLiterals) {
      e.push(["lang-regex", /^(?:^^\.?|[!+-]|!=|!==|#|%|%=|&|&&|&&=|&=|\(|\*|\*=|\+=|,|-=|->|\/|\/=|:|::|;|<|<<|<<=|<=|=|==|===|>|>=|>>|>>=|>>>|>>>=|[?@[^]|\^=|\^\^|\^\^=|{|\||\|=|\|\||\|\|=|~|break|case|continue|delete|do|else|finally|instanceof|return|throw|try|typeof)\s*(\/(?=[^*/])(?:[^/[\\]|\\[\S\s]|\[(?:[^\\\]]|\\[\S\s])*(?:]|$))+\/)/]);
    }
    var h = a.types;
    if(h != null) {
      e.push(["typ", h]);
    }
    a = "" + a.keywords;
    a = a.replace(/^ | $/g, "");
    if(a.length > 0) {
      e.push(["kwd", RegExp("^(?:" + a.replace(/[\s,]+/g, "|") + ")\\b"), null]);
    }
    m.push(["pln", /^\s+/, null, " \r\n\t\xa0"]);
    e.push(["lit", /^@[$_a-z][\w$@]*/i, null], ["typ", /^(?:[@_]?[A-Z]+[a-z][\w$@]*|\w+_t\b)/, null], ["pln", /^[$_a-z][\w$@]*/i, null], ["lit", /^(?:0x[\da-f]+|(?:\d(?:_\d+)*\d*(?:\.\d*)?|\.\d\+)(?:e[+-]?\d+)?)[a-z]*/i, null, "0123456789"], ["pln", /^\\[\S\s]?/, null], ["pun", /^.[^\s\w"-$'./@\\`]*/, null]);
    return x(m, e);
  }
  static function C(a:String, m:String):Dynamic {
    if(a == null || !A.exists(a)) {
      a = /^<\s*/.test(m) ? "default-markup" : "default-code";
    }
    return A.get(a);
  }
  static function E(a:Dynamic):Void {
    var m = a.g;
    try {
      var e = M(a.h);
      var h = e.a;
      a.a = h;
      a.c = e.c;
      a.d = 0;
      C(m, h)(a);
      var k = /\/\bMSIE\b/.test(haxe.Sys.get_userAgent());
      var m = /\n/g;
      var t = a.a;
      var s = t.length;
      var e = 0;
      var l = a.c;
      var p = l.length;
      var h = 0;
      var d = a.e;
      var g = d.length;
      a = 0;
      d[g] = s;
      var r:Int = 0;
      var n:Int = 0;
      while(n < g) {
        if(d[n] != d[n + 2]) {
          d[r++] = d[n++];
          d[r++] = d[n++];
        } else {
          n += 2;
        }
      }
      g = r;
      while(n < g) {
        var z = d[n];
        var f = d[n + 1];
        var b = n + 2;
        while(b + 2 <= g && d[b + 1] == f) {
          b += 2;
        }
        d[r++] = z;
        d[r++] = f;
        n = b;
      }
      d.length = r;
      while(h < p) {
        var o = l[h + 2] || s;
        var c = d[a + 2] || s;
        var b = Math.min(o, c);
        var i = l[h + 1];
        var j:String;
        if(i.nodeType != 1 && (j = t.substring(e, b))) {
          if(k) {
            j = j.replace(m, "\r");
          }
          i.nodeValue = j;
          var u = i.ownerDocument;
          var v = u.createElement("SPAN");
          v.className = d[a + 1];
          var x = i.parentNode;
          x.replaceChild(v, i);
          v.appendChild(i);
          if(e < o) {
            l[h + 1] = i = u.createTextNode(t.substring(b, o));
            x.insertBefore(i, v.nextSibling);
          }
        }
        e = b;
        if(e >= o) {
          h += 2;
        }
        if(e >= c) {
          a += 2;
        }
      }
    } catch(w) {
      if("console" in js.Lib.global) {
        if(w.stack != null) {
          haxe.Log.trace(w.stack, haxe.CallStack.last());
        } else {
          haxe.Log.trace(w, haxe.CallStack.last());
        }
      }
    }
  }
  static function M(a:Dynamic):Dynamic {
    function m(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(e.match(a.className)) {
            break;
          }
          var g:Dynamic = a.firstChild;
          while(g != null) {
            m(g);
            g = g.nextSibling;
          }
          g = a.nodeName;
          if(g == "BR" || g == "LI") {
            h[s] = "\n";
            t[s << 1] = y;
            t[s++ << 1 | 1] = a;
          }
          break;
        case 3:
        case 4:
          g = a.nodeValue;
          if(g.length > 0) {
            g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
            h[s] = g;
            t[s << 1] = y;
            y += g.length;
            t[s++ << 1 | 1] = a;
          }
          break;
      }
    }
    var e = /(?:^|\s)nocode(?:\s|$)/;
    var h = new Array();
    var y = 0;
    var t = new Array();
    var s = 0;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(js.Lib.global.getComputedStyle != null) {
        l = js.Lib.global.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    m(a);
    return {
      a: h.join("").replace(/\n$/, ""),
      c: t
    };
  }
  static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
    if(m != null) {
      a = {
        a: m,
        d: a
      };
      e(a);
      h.push.apply(h, a.e);
    }
  }
  static function L(a:Array<Dynamic>):EReg {
    function m(a:String):Int {
      var f = a.charCodeAt(0);
      if(f != 92) {
        return f;
      }
      var b = a.charAt(1);
      if(r.exists(b)) {
        return r.get(b);
      } else if("0" <= b && b <= "7") {
        return Std.parseInt(a.substring(1), 8);
      } else if(b == "u" || b == "x") {
        return Std.parseInt(a.substring(2), 16);
      } else {
        return a.charCodeAt(1);
      }
    }
    function e(a:Int):String {
      if(a < 32) {
        return (a < 16 ? "\\x0" : "\\x") + a.toString(16);
      }
      a = String.fromCharCode(a);
      if(a == "\\" || a == "-" || a == "[" || a == "]") {
        a = "\\" + a;
      }
      return a;
    }
    function h(a:String):String {
      var f = a.substring(1, a.length - 1).match(/\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\[0-3][0-7]{0,2}|\\[0-7]{1,2}|\\[\S\s]|[^\\]/g);
      var a = new Array();
      var b = new Array();
      var o = f[0] == "^";
      var c = o ? 1 : 0;
      var i = f.length;
      while(c < i) {
        var j = f[c];
        if(/\\[bdsw]/i.test(j)) {
          a.push(j);
        } else {
          var j = m(j);
          var d:Int;
          if(c + 2 < i && f[c + 1] == "-") {
            d = m(f[c + 2]);
            c += 2;
          } else {
            d = j;
          }
          b.push([j, d]);
          if(d < 65 || j > 122) {
            continue;
          }
          if(d < 65 || j > 90) {
            b.push([Math.max(65, j) | 32, Math.min(d, 90) | 32]);
          }
          if(d < 97 || j > 122) {
            b.push([Math.max(97, j) & -33, Math.min(d, 122) & -33]);
          }
        }
        c++;
      }
      b.sort(function(a:Array<Int>, f:Array<Int>):Int {
        return a[0] - f[0] || f[1] - a[1];
      });
      f = new Array();
      j = [NaN, NaN];
      for(c = 0; c < b.length; c++) {
        i = b[c];
        if(i[0] <= j[1] + 1) {
          j[1] = Math.max(j[1], i[1]);
        } else {
          f.push(j = i);
        }
      }
      b = ["["];
      if(o) {
        b.push("^");
      }
      b.push.apply(b, a);
      for(c = 0; c < f.length; c++) {
        i = f[c];
        b.push(e(i[0]));
        if(i[1] > i[0]) {
          if(i[1] + 1 > i[0]) {
            b.push("-");
          }
          b.push(e(i[1]));
        }
      }
      b.push("]");
      return b.join("");
    }
    function y(a:Dynamic):String {
      var f = a.source.match(/\[(?:[^\\\]]|\\[\S\s])*]|\\u[\dA-Fa-f]{4}|\\x[\dA-Fa-f]{2}|\\\d+|\\[^\dux]|\(\?[!:=]|[()^]|[^()[\\^]+/g);
      var b = f.length;
      var d = new Array();
      var c = 0;
      var i = 0;
      while(c < b) {
        var j = f[c];
        if(j == "(") {
          i++;
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            d[j] = -1;
          }
        }
        c++;
      }
      for(c = 1; c < d.length; c++) {
        if(d[c] == -1) {
          d[c] = ++t;
        }
      }
      for(i = c = 0; c < b; c++) {
        j = f[c];
        if(j == "(") {
          i++;
          if(d[i] == null) {
            f[c] = "(?:";
          }
        } else if(j.charAt(0) == "\\") {
          j = +j.substring(1);
          if(j <= i) {
            f[c] = "\\" + d[i];
          }
        }
      }
      for(i = c = 0; c < b; c++) {
        if(f[c] == "^" && f[c + 1] != "^") {
          f[c] = "";
        }
      }
      if(a.ignoreCase && s) {
        for(c = 0; c < b; c++) {
          j = f[c];
          a = j.charAt(0);
          if(j.length >= 2 && a == "[") {
            f[c] = h(j);
          } else if(a != "\\") {
            f[c] = j.replace(/[A-Za-z]/g, function(a:String):String {
              a = a.charCodeAt(0);
              return "[" + String.fromCharCode(a & -33, a | 32) + "]";
            });
          }
        }
      }
      return f.join("");
    }
    var t = 0;
    var s = false;
    var l = false;
    var p = 0;
    var d = a.length;
    while(p < d) {
      var g = a[p];
      if(g.ignoreCase) {
        l = true;
      } else if(/[a-z]/i.test(g.source.replace(/\\u[\da-f]{4}|\\x[\da-f]{2}|\\[^UXux]/gi, ""))) {
        s = true;
        l = false;
        break;
      }
      p++;
    }
    var r:haxe.ds.StringMap = new haxe.ds.StringMap();
    r.set("b", 8);
    r.set("t", 9);
    r.set("n", 10);
    r.set("v", 11);
    r.set("f", 12);
    r.set("r", 13);
    var n = new Array();
    p = 0;
    d = a.length;
    while(p < d) {
      g = a[p];
      if(g.global || g.multiline) {
        throw new Error("" + g);
      }
      n.push("(?:" + y(g) + ")");
      p++;
    }
    return RegExp(n.join("|"), l ? "gi" : "g");
  }
  static function D(a:Dynamic, m:Dynamic):Void {
    function e(a:Dynamic):Void {
      switch(a.nodeType) {
        case 1:
          if(k.match(a.className)) {
            break;
          }
          if(a.nodeName == "BR") {
            h(a);
            if(a.parentNode != null) {
              a.parentNode.removeChild(a);
            }
          } else {
            var a:Dynamic = a.firstChild;
            while(a != null) {
              e(a);
              a = a.nextSibling;
            }
          }
          break;
        case 3:
        case 4:
          if(p) {
            var b = a.nodeValue;
            var d = b.match(t);
            if(d != null) {
              var c = b.substring(0, d.index);
              a.nodeValue = c;
              var b = b.substring(d.index + d[0].length);
              if(b != null) {
                a.parentNode.insertBefore(s.createTextNode(b), a.nextSibling);
              }
              h(a);
              if(c == null) {
                a.parentNode.removeChild(a);
              }
            }
          }
          break;
      }
    }
    function h(a:Dynamic):Void {
      function b(a:Dynamic, d:Bool):Dynamic {
        var e = d ? a.cloneNode(false) : a;
        var f = a.parentNode;
        if(f != null) {
          var f = b(f, true);
          var g = a.nextSibling;
          f.appendChild(e);
          var h = g;
          while(h != null) {
            g = h.nextSibling;
            f.appendChild(h);
            h = g;
          }
        }
        return e;
      }
      while(a.nextSibling == null) {
        if(a = a.parentNode, a == null) {
          return;
        }
      }
      var a = b(a.nextSibling, false);
      var e:Dynamic;
      while((e = a.parentNode) != null && e.nodeType == 1) {
        a = e;
      }
      d.push(a);
    }
    var k = /(?:^|\s)nocode(?:\s|$)/;
    var t = /\r\n?|\n/;
    var s = a.ownerDocument;
    var l:String;
    if(a.currentStyle != null) {
      l = a.currentStyle.whiteSpace;
    } else {
      if(s.defaultView != null && s.defaultView.getComputedStyle != null) {
        l = s.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
      }
    }
    var p = l != null && l.substring(0, 3) == "pre";
    var l = s.createElement("LI");
    while(a.firstChild != null) {
      l.appendChild(a.firstChild);
    }
    var d = new Array();
    d.push(l);
    var g = 0;
    var z = d.length;
    while(g < z) {
      e(d[g]);
      g++;
    }
    m = m | 0;
    if(m != 0) {
      d[0].setAttribute("value", m);
    }
    var r = s.createElement("OL");
    r.className = "linenums";
    var n = Math.max(0, m - 1 | 0) || 0;
    g = 0;
    z = d.length;
    while(g < z) {
      l = d[g];
      l.className = "L" + (g + n) % 10;
      if(l.firstChild == null) {
        l.appendChild(s.createTextNode("\xa0"));
      }
      r.appendChild(l);
      g++;
    }
    a.appendChild(r);
  }
  static function prettyPrintOne(a:String, m:String, e:Dynamic):String {
    var h = js.Lib.document.createElement("PRE");
    h.innerHTML = a;
    if(e != null) {
      D(h, e);
    }
    E({
      g: m,
      i: e,
      h: h
    });
    return h.innerHTML;
  }
  static function prettyPrint(a:Dynamic):Void {
    function m():Void {
      var e:Float = window.PR_SHOULD_USE_CONTINUATION ? Date.now() + 250 : Infinity;
      while(p < h.length && Date.now() < e) {
        var n = h[p];
        var k = n.className;
        if(k.indexOf("prettyprint") >= 0) {
          var k = k.match(g);
          var f:Dynamic;
          var b:Bool;
          if(b = !k) {
            b = n;
            var o:Dynamic = null;
            var c:Dynamic = b.firstChild;
            while(c != null) {
              var i = c.nodeType;
              o = i == 1 ? (o != null ? b : c) : (i == 3 ? (N.test(c.nodeValue) ? b : o) : o);
              c = c.nextSibling;
            }
            b = (f = o == b ? null : o) && f.tagName == "CODE";
          }
          if(b) {
            k = f.className.match(g);
          }
          if(k != null) {
            k = k[1];
          }
          b = false;
          var o:Dynamic = n.parentNode;
          while(o != null) {
            if((o.tagName == "pre" || o.tagName == "code" || o.tagName == "xmp") && o.className != null && o.className.indexOf("prettyprint") >= 0) {
              b = true;
              break;
            }
            o = o.parentNode;
          }
          if(!b) {
            b = (b = n.className.match(/\blinenums\b(?::(\d+))?/)) ? (b[1] != null && b[1].length > 0 ? Std.parseInt(b[1]) : true) : false;
            if(b) {
              D(n, b);
              d = {
                g: k,
                h: n,
                i: b
              };
              E(d);
            }
          }
        }
        p++;
      }
      if(p < h.length) {
        js.Lib.setTimeout(m, 250);
      } else if(a != null) {
        a();
      }
    }
    var e = new Array();
    e.push(js.Lib.document.getElementsByTagName("pre"));
    e.push(js.Lib.document.getElementsByTagName("code"));
    e.push(js.Lib.document.getElementsByTagName("xmp"));
    var h = new Array();
    var k = 0;
    var t = e.length;
    while(k < t) {
      var s = 0;
      var z = e[k].length;
      while(s < z) {
        h.push(e[k][s]);
        s++;
      }
      k++;
    }
    var e:Dynamic = q;
    var l:Dynamic = Date;
    if(l.now == null) {
      l = {
        now: function():Float {
          return Date.now();
        }
      };
    }
    var p = 0;
    var d:Dynamic;
    var g = /\blang(?:uage)?-([\w.]+)(?!\S)/;
    m();
  }
  static var PR_ATTRIB_NAME:String = "atn";
  static var PR_ATTRIB_VALUE:String = "atv";
  static var PR_COMMENT:String = "com";
  static var PR_DECLARATION:String = "dec";
  static var PR_KEYWORD:String = "kwd";
  static var PR_LITERAL:String = "lit";
  static var PR_NOCODE:String = "nocode";
  static var PR_PLAIN:String = "pln";
  static var PR_PUNCTUATION:String = "pun";
  static var PR_SOURCE:String = "src";
  static var PR_STRING:String = "str";
  static var PR_TAG:String = "tag";
  static var PR_TYPE:String = "typ";
}
var q = null;
window.PR_SHOULD_USE_CONTINUATION = true;
function main() {
  var v = ["break", "continue", "do", "else", "for", "if", "return", "while"];
  var w = [[v, "auto,case,char,const,default,double,enum,extern,float,goto,int,long,register,short,signed,sizeof,static,struct,switch,typedef,union,unsigned,void,volatile"], "catch,class,delete,false,import,new,operator,private,protected,public,this,throw,true,try,typeof"];
  var F = [w, "alignof,align_union,asm,axiom,bool,concept,concept_map,const_cast,constexpr,decltype,dynamic_cast,explicit,export,friend,inline,late_check,mutable,namespace,nullptr,reinterpret_cast,static_assert,static_cast,template,typeid,typename,using,virtual,where"];
  var G = [w, "abstract,boolean,byte,extends,final,finally,implements,import,instanceof,null,native,package,strictfp,super,synchronized,throws,transient"];
  var H = [G, "as,base,by,checked,decimal,delegate,descending,dynamic,event,fixed,foreach,from,group,implicit,in,interface,internal,into,is,lock,object,out,override,orderby,params,partial,readonly,ref,sbyte,sealed,stackalloc,string,select,uint,ulong,unchecked,unsafe,ushort,var"];
  w = [w, "debugger,eval,export,function,get,null,set,undefined,var,with,Infinity,NaN"];
  var I = [v, "and,as,assert,class,def,del,elif,except,exec,finally,from,global,import,in,is,lambda,nonlocal,not,or,pass,print,raise,try,with,yield,False,True,None"];
  var J = [v, "alias,and,begin,case,class,def,defined,elsif,end,ensure,false,in,module,next,nil,not,or,redo,rescue,retry,self,super,then,true,undef,unless,until,when,yield,BEGIN,END"];
  v = [v, "case,done,elif,esac,eval,fi,function,in,local,set,then,until"];
  var K = /^(DIR|FILE|vector|(de|priority_)?queue|list|stack|(const_)?iterator|(multi)?(set|map)|bitset|u?(int|float)\d*)/;
  var N = /\S/;
  var O = PR.sourceDecorator({
    keywords: [F, H, w, "caller,delete,die,do,dump,elsif,eval,exit,foreach,for,goto,if,import,last,local,my,next,no,our,print,package,redo,require,sub,undef,unless,until,use,wantarray,while,BEGIN,END" + I, J, v],
    hashComments: true,
    c