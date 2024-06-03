import js.Browser;
import js.html.HTMLElement;

class PrettyPrint {
    static var q:Dynamic = null;
    static var PR_SHOULD_USE_CONTINUATION:Bool = true;
    static var h:Array<String> = [];
    static var y:Int = 0;
    static var t:Array<Dynamic> = [];
    static var s:Int = 0;
    static var r:haxe.ds.StringMap<Int> = new haxe.ds.StringMap();
    static var n:Array<String> = [];
    static var p:Int = 0;
    static var d:Int = 0;
    static var g:String = "";
    static var l:String = "";
    static var b:Int = 0;
    static var c:Int = 0;
    static var i:Int = 0;
    static var j:Int = 0;
    static var k:Int = 0;
    static var z:Int = 0;
    static var f:String = "";
    static var o:Dynamic = null;
    static var a:Array<Dynamic> = [];
    static var e:Dynamic = null;
    static var m:Dynamic = null;

    static function L(a:Array<EReg>):EReg {
        var regSource:String = "";
        for (i in 0...a.length) {
            g = a[i].source;
            regSource += "(?:" + y(g) + ")";
        }
        return new EReg(regSource, "g");
    }

    static function M(a:HTMLElement):Dynamic {
        var e = /(?:^|\s)nocode(?:\s|$)/;
        h = [];
        y = 0;
        t = [];
        s = 0;
        l = Browser.document.defaultView.getComputedStyle(a, q).getPropertyValue("white-space");
        var p = l && "pre" == l.substring(0, 3);
        m(a);
        return {a: h.join("").replace(/\n$/, ""), c: t};
    }

    static function m(a:HTMLElement):Void {
        var e = a.nodeType;
        if (e == 1) {
            if (e.test(a.className)) return;
            var g = a.firstChild;
            while (g != null) {
                m(g);
                g = g.nextSibling;
            }
            g = a.nodeName;
            if ("BR" == g || "LI" == g) {
                h[s] = "\n";
                t[s<<1] = y++;
                t[s++<<1|1] = a;
            }
        } else if (e == 3 || e == 4) {
            g = a.nodeValue;
            if (g.length != 0) {
                g = p ? g.replace(/\r\n?/g, "\n") : g.replace(/[\t\n\r ]+/g, " ");
                h[s] = g;
                t[s<<1] = y;
                y += g.length;
                t[s++<<1|1] = a;
            }
        }
    }

    static function B(a:Int, m:String, e:Dynamic, h:Array<Dynamic>):Void {
        if (m != null) {
            a = {a: m, d: a};
            e(a);
            h.push(...a.e);
        }
    }

    // ... (other methods)
}