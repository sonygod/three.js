package;

import js.three.Curve;
import js.three.Vector3;

class GrannyKnot extends Curve {
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t = 2.0 * Math.PI * t;
        var x = -0.22 * Math.cos(t) - 1.28 * Math.sin(t) - 0.44 * Math.cos(3.0 * t) - 0.78 * Math.sin(3.0 * t);
        var y = -0.1 * Math.cos(2.0 * t) - 0.27 * Math.sin(2.0 * t) + 0.38 * Math.cos(4.0 * t) + 0.46 * Math.sin(4.0 * t);
        var z = 0.7 * Math.cos(3.0 * t) - 0.4 * Math.sin(3.0 * t);
        return point.set(x, y, z).multiplyScalar(20.0);
    }
}

class HeartCurve extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 5.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t *= 2.0 * Math.PI;
        var x = 16.0 * Math.pow(Math.sin(t), 3.0);
        var y = 13.0 * Math.cos(t) - 5.0 * Math.cos(2.0 * t) - 2.0 * Math.cos(3.0 * t) - Math.cos(4.0 * t);
        var z = 0.0;
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class VivianiCurve extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 70.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t = t * 4.0 * Math.PI; // normalized to 0..1
        var a = this.scale / 2.0;
        var x = a * (1.0 + Math.cos(t));
        var y = a * Math.sin(t);
        var z = 2.0 * a * Math.sin(t / 2.0);
        return point.set(x, y, z);
    }
}

class KnotCurve extends Curve {
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t *= 2.0 * Math.PI;
        var R = 10.0;
        var s = 50.0;
        var x = s * Math.sin(t);
        var y = Math.cos(t) * (R + s * Math.cos(t));
        var z = Math.sin(t) * (R + s * Math.cos(t));
        return point.set(x, y, z);
    }
}

class HelixCurve extends Curve {
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var a = 30.0; // radius
        var b = 150.0; // height
        var t2 = 2.0 * Math.PI * t * b / 30.0;
        var x = Math.cos(t2) * a;
        var y = Math.sin(t2) * a;
        var z = b * t;
        return point.set(x, y, z);
    }
}

class TrefoilKnot extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 10.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t *= Math.PI * 2.0;
        var x = (2.0 + Math.cos(3.0 * t)) * Math.cos(2.0 * t);
        var y = (2.0 + Math.cos(3.0 * t)) * Math.sin(2.0 * t);
        var z = Math.sin(3.0 * t);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class TorusKnot extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 10.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var p = 3;
        var q = 4;
        t *= Math.PI * 2.0;
        var x = (2.0 + Math.cos(q * t)) * Math.cos(p * t);
        var y = (2.0 + Math.cos(q * t)) * Math.sin(p * t);
        var z = Math.sin(q * t);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class CinquefoilKnot extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 10.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var p = 2;
        var q = 5;
        t *= Math.PI * 2.0;
        var x = (2.0 + Math.cos(q * t)) * Math.cos(p * t);
        var y = (2.0 + Math.cos(q * t)) * Math.sin(p * t);
        var z = Math.sin(q * t);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class TrefoilPolynomialKnot extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 10.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t = t * 4.0 - 2.0;
        var x = Math.pow(t, 3.0) - 3.0 * t;
        var y = Math.pow(t, 4.0) - 4.0 * t * t;
        var z = 1.0 / 5.0 * Math.pow(t, 5.0) - 2.0 * t;
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

function scaleTo(x:Float, y:Float, t:Float):Float {
    var r = y - x;
    return t * r + x;
}

class FigureEightPolynomialKnot extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 1.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t = scaleTo(-4.0, 4.0, t);
        var x = 2.0 / 5.0 * t * (t * t - 7.0) * (t * t - 10.0);
        var y = Math.pow(t, 4.0) - 13.0 * t * t;
        var z = 1.0 / 10.0 * t * (t * t - 4.0) * (t * t - 9.0) * (t * t - 12.0);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class DecoratedTorusKnot4a extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 40.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t *= Math.PI * 2.0;
        var x = Math.cos(2.0 * t) * (1.0 + 0.6 * (Math.cos(5.0 * t) + 0.75 * Math.cos(10.0 * t)));
        var y = Math.sin(2.0 * t) * (1.0 + 0.6 * (Math.cos(5.0 * t) + 0.75 * Math.cos(10.0 * t)));
        var z = 0.35 * Math.sin(5.0 * t);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class DecoratedTorusKnot4b extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 40.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var fi = t * Math.PI * 2.0;
        var x = Math.cos(2.0 * fi) * (1.0 + 0.45 * Math.cos(3.0 * fi) + 0.4 * Math.cos(9.0 * fi));
        var y = Math.sin(2.0 * fi) * (1.0 + 0.45 * Math.cos(3.0 * fi) + 0.4 * Math.cos(9.0 * fi));
        var z = 0.2 * Math.sin(9.0 * fi);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class DecoratedTorusKnot5a extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 40.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var fi = t * Math.PI * 2.0;
        var x = Math.cos(3.0 * fi) * (1.0 + 0.3 * Math.cos(5.0 * fi) + 0.5 * Math.cos(10.0 * fi));
        var y = Math.sin(3.0 * fi) * (1.0 + 0.3 * Math.cos(5.0 * fi) + 0.5 * Math.cos(10.0 * fi));
        var z = 0.2 * Math.sin(20.0 * fi);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

class DecoratedTorusKnot5c extends Curve {
    var scale:Float;
    public function new(?scale:Float) {
        super();
        this.scale = scale ?? 40.0;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        var fi = t * Math.PI * 2.0;
        var x = Math.cos(4.0 * fi) * (1.0 + 0.5 * (Math.cos(5.0 * fi) + 0.4 * Math.cos(20.0 * fi)));
        var y = Math.sin(4.0 * fi) * (1.0 + 0.5 * (Math.cos(5.0 * fi) + 0.4 * Math.cos(20.0 * fi)));
        var z = 0.35 * Math.sin(15.0 * fi);
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}