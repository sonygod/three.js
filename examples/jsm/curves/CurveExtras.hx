package three.js.examples.jsm.curves;

import three.js Curve;
import three.js.Vector3;

/**
 * A bunch of parametric curves
 *
 * Formulas collected from various sources
 * http://mathworld.wolfram.com/HeartCurve.html
 * http://en.wikipedia.org/wiki/Viviani%27s_curve
 * http://www.mi.sanu.ac.rs/vismath/taylorapril2011/Taylor.pdf
 * https://prideout.net/blog/old/blog/index.html@p=44.html
 */

// GrannyKnot

class GrannyKnot extends Curve {
    public function new() { super(); }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= 2 * Math.PI;

        var x:Float = -0.22 * Math.cos(t) - 1.28 * Math.sin(t) - 0.44 * Math.cos(3 * t) - 0.78 * Math.sin(3 * t);
        var y:Float = -0.1 * Math.cos(2 * t) - 0.27 * Math.sin(2 * t) + 0.38 * Math.cos(4 * t) + 0.46 * Math.sin(4 * t);
        var z:Float = 0.7 * Math.cos(3 * t) - 0.4 * Math.sin(3 * t);

        return point.set(x, y, z).multiplyScalar(20);
    }
}

// HeartCurve

class HeartCurve extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 5) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= 2 * Math.PI;

        var x:Float = 16 * Math.pow(Math.sin(t), 3);
        var y:Float = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
        var z:Float = 0;

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// Viviani's Curve

class VivianiCurve extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 70) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= 4 * Math.PI; // normalized to 0..1
        var a:Float = this.scale / 2;

        var x:Float = a * (1 + Math.cos(t));
        var y:Float = a * Math.sin(t);
        var z:Float = 2 * a * Math.sin(t / 2);

        return point.set(x, y, z);
    }
}

// KnotCurve

class KnotCurve extends Curve {
    public function new() { super(); }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= 2 * Math.PI;

        var R:Float = 10;
        var s:Float = 50;

        var x:Float = s * Math.sin(t);
        var y:Float = Math.cos(t) * (R + s * Math.cos(t));
        var z:Float = Math.sin(t) * (R + s * Math.cos(t));

        return point.set(x, y, z);
    }
}

// HelixCurve

class HelixCurve extends Curve {
    public function new() { super(); }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();

        var a:Float = 30; // radius
        var b:Float = 150; // height

        var t2:Float = 2 * Math.PI * t * b / 30;

        var x:Float = Math.cos(t2) * a;
        var y:Float = Math.sin(t2) * a;
        var z:Float = b * t;

        return point.set(x, y, z);
    }
}

// TrefoilKnot

class TrefoilKnot extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 10) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= Math.PI * 2;

        var x:Float = (2 + Math.cos(3 * t)) * Math.cos(2 * t);
        var y:Float = (2 + Math.cos(3 * t)) * Math.sin(2 * t);
        var z:Float = Math.sin(3 * t);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// TorusKnot

class TorusKnot extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 10) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var p:Int = 3;
        var q:Int = 4;

        t *= Math.PI * 2;

        var x:Float = (2 + Math.cos(q * t)) * Math.cos(p * t);
        var y:Float = (2 + Math.cos(q * t)) * Math.sin(p * t);
        var z:Float = Math.sin(q * t);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// CinquefoilKnot

class CinquefoilKnot extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 10) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var p:Int = 2;
        var q:Int = 5;

        t *= Math.PI * 2;

        var x:Float = (2 + Math.cos(q * t)) * Math.cos(p * t);
        var y:Float = (2 + Math.cos(q * t)) * Math.sin(p * t);
        var z:Float = Math.sin(q * t);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// TrefoilPolynomialKnot

class TrefoilPolynomialKnot extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 10) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t = t * 4 - 2;

        var x:Float = Math.pow(t, 3) - 3 * t;
        var y:Float = Math.pow(t, 4) - 4 * t * t;
        var z:Float = 1 / 5 * Math.pow(t, 5) - 2 * t;

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

inline function scaleTo(x:Float, y:Float, t:Float):Float {
    var r:Float = y - x;
    return t * r + x;
}

// FigureEightPolynomialKnot

class FigureEightPolynomialKnot extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 1) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t = scaleTo(-4, 4, t);

        var x:Float = 2 / 5 * t * (t * t - 7) * (t * t - 10);
        var y:Float = Math.pow(t, 4) - 13 * t * t;
        var z:Float = 1 / 10 * t * (t * t - 4) * (t * t - 9) * (t * t - 12);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// DecoratedTorusKnot4a

class DecoratedTorusKnot4a extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 40) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        t *= Math.PI * 2;

        var x:Float = Math.cos(2 * t) * (1 + 0.6 * (Math.cos(5 * t) + 0.75 * Math.cos(10 * t)));
        var y:Float = Math.sin(2 * t) * (1 + 0.6 * (Math.cos(5 * t) + 0.75 * Math.cos(10 * t)));
        var z:Float = 0.35 * Math.sin(5 * t);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// DecoratedTorusKnot4b

class DecoratedTorusKnot4b extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 40) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var fi:Float = t * Math.PI * 2;

        var x:Float = Math.cos(2 * fi) * (1 + 0.45 * Math.cos(3 * fi) + 0.4 * Math.cos(9 * fi));
        var y:Float = Math.sin(2 * fi) * (1 + 0.45 * Math.cos(3 * fi) + 0.4 * Math.cos(9 * fi));
        var z:Float = 0.2 * Math.sin(9 * fi);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// DecoratedTorusKnot5a

class DecoratedTorusKnot5a extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 40) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var fi:Float = t * Math.PI * 2;

        var x:Float = Math.cos(3 * fi) * (1 + 0.3 * Math.cos(5 * fi) + 0.5 * Math.cos(10 * fi));
        var y:Float = Math.sin(3 * fi) * (1 + 0.3 * Math.cos(5 * fi) + 0.5 * Math.cos(10 * fi));
        var z:Float = 0.2 * Math.sin(20 * fi);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// DecoratedTorusKnot5c

class DecoratedTorusKnot5c extends Curve {
    private var scale:Float;

    public function new(?scale:Float = 40) {
        super();
        this.scale = scale;
    }

    public function getPoint(t:Float, ?optionalTarget:Vector3):Vector3 {
        var point:Vector3 = optionalTarget != null ? optionalTarget : new Vector3();
        var fi:Float = t * Math.PI * 2;

        var x:Float = Math.cos(4 * fi) * (1 + 0.5 * (Math.cos(5 * fi) + 0.4 * Math.cos(20 * fi)));
        var y:Float = Math.sin(4 * fi) * (1 + 0.5 * (Math.cos(5 * fi) + 0.4 * Math.cos(20 * fi)));
        var z:Float = 0.35 * Math.sin(15 * fi);

        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}