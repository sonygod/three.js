package;

import js.html.PreElement;
import js.html.Element;
import js.html.Node;
import js.html.Text;
import js.Browser;

class Prettify {
  static var q:Null<Dynamic> = null;
  static inline var PR_SHOULD_USE_CONTINUATION = true;

  static function L(a:Array<Dynamic>) {
    // ...
  }

  static function M(a:Dynamic) {
    // ...
  }

  static function B(a:Dynamic, m:Dynamic, e:Dynamic, h:Array<Dynamic>) {
    // ...
  }

  static function x(m:Array<Dynamic>, e:Array<Dynamic>) {
    // ...
  }

  static function u(a:Dynamic) {
    // ...
  }

  static function D(a:Element, m:Dynamic) {
    // ...
  }

  static function k(a:Dynamic, m:Array<String>) {
    // ...
  }

  static function C(a:Dynamic, m:Dynamic) {
    // ...
  }

  static function E(a:Dynamic) {
    // ...
  }

  static function prettyPrintOne(a:String, m:Dynamic, e:Dynamic) {
    var h = Browser.document.createElement("PRE");
    h.innerHTML = a;
    if (e != null) D(h, e);
    E({ g: m, i: e, h: h });
    return h.innerHTML;
  }

  static function prettyPrint(a:Dynamic) {
    var p = 0;
    var h:Array<Element> = [];
    for (e in Browser.document.getElementsByTagName("pre")) {
      h.push(e);
    }
    for (e in Browser.document.getElementsByTagName("code")) {
      h.push(e);
    }
    for (e in Browser.document.getElementsByTagName("xmp")) {
      h.push(e);
    }
    function m() {
      while (p < h.length) {
        var n = h[p];
        var k = n.className.match(~/(?:^|\s)nocode(?:\s|$)/);
        if (k != null) {
          // ...
        }
        p++;
      }
      if (p < h.length) {
        Browser.window.setTimeout(m, 250);
      } else {
        a();
      }
    }
    m();
  }
}