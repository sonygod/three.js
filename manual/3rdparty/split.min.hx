package three.js.manual.thirdparty;

class Split {
    private static var exports:Dynamic = {};

    public static function init(u:Array<Dynamic>, c:Dynamic = null):Dynamic {
        if (c == null) c = {};
        var e:Dynamic = js.Browser.window;
        var t:Dynamic = e.document;
        var n:String = "addEventListener";
        var i:String = "removeEventListener";
        var r:String = "getBoundingClientRect";
        var s:Void->Bool = function() { return false; };
        var o:Bool = e.attachEvent != null && e[n] != null;
        var a:String = ["", "-webkit-", "-moz-", "-o-"].filter(function(e:String) {
            var n:Dynamic = t.createElement("div");
            n.style.cssText = "width:" + e + "calc(9px)";
            return n.style.length > 0;
        }).shift() + "calc";
        var l:Dynamic->Dynamic = function(e:Dynamic) {
            return if (Std.isOfType(e, String)) {
                t.querySelector(e);
            } else {
                e;
            }
        }

        var z:Dynamic->Dynamic->Void = function(e:Dynamic, t:Dynamic, n:Dynamic) {
            var i:A = y(t, n);
            for (key in i.keys()) {
                e.style[key] = i[key];
            }
        }

        var h:Dynamic->Dynamic->Void = function(e:Dynamic, t:Dynamic) {
            var n:B = y(t);
            for (key in n.keys()) {
                e.style[key] = n[key];
            }
        }

        var f:Dynamic->Void = function(e:Dynamic) {
            var t:E = this.a;
            var n:E = this.b;
            var i:Float = t.size + n.size;
            t.size = e / this.size * i;
            n.size = i - e / this.size * i;
            z(t.element, t.size, this.aGutterSize);
            z(n.element, n.size, this.bGutterSize);
        }

        var m:Dynamic->Void = function(e:Dynamic) {
            var t:Float;
            if (this.dragging) {
                var start:Float = if (Reflect.hasField(e, "touches")) {
                    e.touches[0][b] - this.start;
                } else {
                    e[b] - this.start;
                }
                if (start <= E[this.a].minSize + M + this.aGutterSize) {
                    t = E[this.a].minSize + this.aGutterSize;
                } else if (start >= this.size - (E[this.b].minSize + M + this.bGutterSize)) {
                    t = this.size - (E[this.b].minSize + M + this.bGutterSize);
                } else {
                    t = start;
                }
                f.call(this, t);
                if (c.onDrag != null) c.onDrag();
            }
        }

        var g:Void->Void = function() {
            var e:E = this.a;
            var t:E = this.b;
            this.size = e[r]()[y] + t[r]()[y] + this.aGutterSize + this.bGutterSize;
            this.start = e[r]()[G];
        }

        var d:Void->Void = function() {
            var t:Split = this;
            if (this.dragging) {
                if (c.onDragEnd != null) c.onDragEnd();
                this.dragging = false;
                e[i](n, this.stop);
                e[i]("touchend", this.stop);
                e[i]("touchcancel", this.stop);
                t.parent[i]("mousemove", this.move);
                t.parent[i]("touchmove", this.move);
                delete this.stop;
                delete this.move;
                var n:E = E[t.a];
                var r:E = E[t.b];
                n[i]("selectstart", s);
                n[i]("dragstart", s);
                r[i]("selectstart", s);
                r[i]("dragstart", s);
                n.style.userSelect = "";
                n.style.webkitUserSelect = "";
                n.style.MozUserSelect = "";
                n.style.pointerEvents = "";
                r.style.userSelect = "";
                r.style.webkitUserSelect = "";
                r.style.MozUserSelect = "";
                r.style.pointerEvents = "";
                t.gutter.style.cursor = "";
                t.parent.style.cursor = "";
            }
        }

        var S:Dynamic->Void = function(t:Dynamic) {
            var i:Split = this;
            if (!this.dragging) {
                if (c.onDragStart != null) c.onDragStart();
                t.preventDefault();
                this.dragging = true;
                this.move = m.bind(this);
                this.stop = d.bind(this);
                e[n]("mouseup", this.stop);
                e[n]("touchend", this.stop);
                e[n]("touchcancel", this.stop);
                this.parent[n]("mousemove", this.move);
                this.parent[n]("touchmove", this.move);
                var r:E = E[this.a];
                var o:E = E[this.b];
                r[n]("selectstart", s);
                r[n]("dragstart", s);
                o[n]("selectstart", s);
                o[n]("dragstart", s);
                r.style.userSelect = "none";
                r.style.webkitUserSelect = "none";
                r.style.MozUserSelect = "none";
                r.style.pointerEvents = "none";
                o.style.userSelect = "none";
                o.style.webkitUserSelect = "none";
                o.style.MozUserSelect = "none";
                o.style.pointerEvents = "none";
                i.gutter.style.cursor = j;
                this.parent.style.cursor = j;
                g.call(this);
            }
        }

        var v:Array<Dynamic>->Void = function(e:Array<Dynamic>) {
            e.forEach(function(t:Dynamic, n:Int) {
                if (n > 0) {
                    var i:F = F[n - 1];
                    var r:E = E[i.a];
                    var s:E = E[i.b];
                    r.size = e[n - 1];
                    s.size = t;
                    z(r.element, r.size, i.aGutterSize);
                    z(s.element, s.size, i.bGutterSize);
                }
            });
        }

        var p:Void->Void = function() {
            F.forEach(function(e:F) {
                e.parent.removeChild(e.gutter);
                E[e.a].element.style[y] = "";
                E[e.b].element.style[y] = "";
            });
        }

        if (c == null) c = {};
        var y:String, b:String, G:String, E:Array<E>, w:Dynamic, D:String, U:Array<Float>, k:Array<Float>, L:Float, M:Float, O:String, j:String, C:Dynamic->Dynamic->Dynamic, A:Dynamic->Dynamic->Dynamic, B:Dynamic->Dynamic->Dynamic;

        if (u.length > 0) {
            w = l(u[0]).parentNode;
            D = e.getComputedStyle(w).flexDirection;
            U = if (c.sizes != null) c.sizes else u.map(function(e) { return 100 / u.length; });
            k = if (c.minSize != null) c.minSize else u.map(function(e) { return 100; });
            x = if (c.minSize != null) c.minSize else u.map(function(e) { return 100; });
            L = if (c.gutterSize != null) c.gutterSize else 10;
            M = if (c.snapOffset != null) c.snapOffset else 30;
            O = if (c.direction != null) c.direction else "horizontal";
            j = if (c.cursor != null) c.cursor else (O == "horizontal" ? "ew-resize" : "ns-resize");
            C = if (c.gutter != null) c.gutter else function(e:Dynamic, n:Dynamic) {
                var i:Dynamic = t.createElement("div");
                i.className = "gutter gutter-" + n;
                return i;
            };
            A = if (c.elementStyle != null) c.elementStyle else function(e:Dynamic, t:Dynamic, n:Dynamic) {
                var i:Dynamic = {};
                i[e] = if (Std.isOfType(t, String)) t else o ? t + "%" : a + "(" + t + "% - " + n + "px)";
                return i;
            };
            B = if (c.gutterStyle != null) c.gutterStyle else function(e:Dynamic, t:Dynamic) {
                var n:Dynamic = {};
                n[e] = t + "px";
                return n;
            };

            if (O == "horizontal") {
                y = "width";
                b = "clientX";
                G = "left";
            } else {
                y = "height";
                b = "clientY";
                G = "top";
            }

            var F:Array<F> = [];

            E = u.map(function(e:Dynamic, t:Int) {
                var i:F = {
                    element: l(e),
                    size: U[t],
                    minSize: x[t],
                    a: t - 1,
                    b: t,
                    dragging: false,
                    isFirst: t == 0,
                    isLast: t == u.length - 1,
                    direction: O,
                    parent: w
                };
                i.aGutterSize = L;
                i.bGutterSize = L;
                if (i.isFirst) i.aGutterSize = L / 2;
                if (i.isLast) i.bGutterSize = L / 2;
                if (!o && t > 0) {
                    var c:Dynamic = C(t, O);
                    h(c, L);
                    c[n]("mousedown", S.bind(i));
                    c[n]("touchstart", S.bind(i));
                    w.insertBefore(c, i.element);
                    i.gutter = c;
                }
                if (t == 0 || t == u.length - 1) {
                    z(i.element, i.size, L / 2);
                } else {
                    z(i.element, i.size, L);
                }
                var f:Float = i.element[r]()[y];
                if (f < i.minSize) i.minSize = f;
                if (t > 0) F.push(i);
                return i;
            });

            if (o) {
                return { setSizes: v };
            } else {
                return {
                    setSizes: v,
                    getSizes: function() {
                        return E.map(function(e:E) { return e.size; });
                    },
                    collapse: function(e:Int) {
                        if (e == F.length) {
                            var t:F = F[e - 1];
                            g.call(t);
                            f.call(t, t.size - t.bGutterSize);
                        } else {
                            var n:F = F[e];
                            g.call(n);
                            f.call(n, n.aGutterSize);
                        }
                    },
                    destroy: p
                };
            }
        }
    }
}