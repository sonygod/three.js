package three.math;

import three.math.Vector3;

class Triangle {
    public var a:Vector3;
    public var b:Vector3;
    public var c:Vector3;

    public function new(a:Vector3 = null, b:Vector3 = null, c:Vector3 = null) {
        if (a == null) a = new Vector3();
        if (b == null) b = new Vector3();
        if (c == null) c = new Vector3();

        this.a = a;
        this.b = b;
        this.c = c;
    }

    static public function getNormal(a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
        _v0.subVectors(c, b);
        _v1.subVectors(a, b);
        target.cross(_v0);

        var targetLengthSq = target.lengthSq();
        if (targetLengthSq > 0) {
            return target.multiplyScalar(1 / Math.sqrt(targetLengthSq));
        }

        return target.set(0, 0, 0);
    }

    static public function getBarycoord(point:Vector3, a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
        _v0.subVectors(c, a);
        _v1.subVectors(b, a);
        _v2.subVectors(point, a);

        var dot00 = _v0.dot(_v0);
        var dot01 = _v0.dot(_v1);
        var dot02 = _v0.dot(_v2);
        var dot11 = _v1.dot(_v1);
        var dot12 = _v1.dot(_v2);

        var denom = (dot00 * dot11 - dot01 * dot01);

        if (denom == 0) {
            target.set(0, 0, 0);
            return null;
        }

        var invDenom = 1 / denom;
        var u = (dot11 * dot02 - dot01 * dot12) * invDenom;
        var v = (dot00 * dot12 - dot01 * dot02) * invDenom;

        return target.set(1 - u - v, v, u);
    }

    static public function containsPoint(point:Vector3, a:Vector3, b:Vector3, c:Vector3):Bool {
        if (getBarycoord(point, a, b, c, _v3) == null) {
            return false;
        }

        return (_v3.x >= 0) && (_v3.y >= 0) && ((_v3.x + _v3.y) <= 1);
    }

    static public function getInterpolation(point:Vector3, p1:Vector3, p2:Vector3, p3:Vector3, v1:Vector3, v2:Vector3, v3:Vector3, target:Vector3):Vector3 {
        if (getBarycoord(point, p1, p2, p3, _v3) == null) {
            target.x = 0;
            target.y = 0;
            if (target.z != null) target.z = 0;
            if (target.w != null) target.w = 0;
            return null;
        }

        target.setScalar(0);
        target.addScaledVector(v1, _v3.x);
        target.addScaledVector(v2, _v3.y);
        target.addScaledVector(v3, _v3.z);

        return target;
    }

    static public function isFrontFacing(a:Vector3, b:Vector3, c:Vector3, direction:Vector3):Bool {
        _v0.subVectors(c, b);
        _v1.subVectors(a, b);

        return (_v0.cross(_v1).dot(direction) < 0);
    }

    public function set(a:Vector3, b:Vector3, c:Vector3):Triangle {
        this.a.copy(a);
        this.b.copy(b);
        this.c.copy(c);

        return this;
    }

    public function setFromPointsAndIndices(points:Array<Vector3>, i0:Int, i1:Int, i2:Int):Triangle {
        this.a.copy(points[i0]);
        this.b.copy(points[i1]);
        this.c.copy(points[i2]);

        return this;
    }

    public function setFromAttributeAndIndices(attribute:Array<Float>, i0:Int, i1:Int, i2:Int):Triangle {
        this.a.fromBufferAttribute(attribute, i0);
        this.b.fromBufferAttribute(attribute, i1);
        this.c.fromBufferAttribute(attribute, i2);

        return this;
    }

    public function clone():Triangle {
        return new Triangle().copy(this);
    }

    public function copy(triangle:Triangle):Triangle {
        this.a.copy(triangle.a);
        this.b.copy(triangle.b);
        this.c.copy(triangle.c);

        return this;
    }

    public function getArea():Float {
        _v0.subVectors(this.c, this.b);
        _v1.subVectors(this.a, this.b);

        return _v0.cross(_v1).length() * 0.5;
    }

    public function getMidpoint(target:Vector3):Vector3 {
        return target.addVectors(this.a, this.b).add(this.c).multiplyScalar(1 / 3);
    }

    public function getNormal(target:Vector3):Vector3 {
        return getNormal(this.a, this.b, this.c, target);
    }

    public function getPlane(target:Vector3):Vector3 {
        return target.setFromCoplanarPoints(this.a, this.b, this.c);
    }

    public function getBarycoord(point:Vector3, target:Vector3):Vector3 {
        return getBarycoord(point, this.a, this.b, this.c, target);
    }

    public function getInterpolation(point:Vector3, v1:Vector3, v2:Vector3, v3:Vector3, target:Vector3):Vector3 {
        return getInterpolation(point, this.a, this.b, this.c, v1, v2, v3, target);
    }

    public function containsPoint(point:Vector3):Bool {
        return containsPoint(point, this.a, this.b, this.c);
    }

    public function isFrontFacing(direction:Vector3):Bool {
        return isFrontFacing(this.a, this.b, this.c, direction);
    }

    public function intersectsBox(box:{ intersectsTriangle:Triangle->Bool }):Bool {
        return box.intersectsTriangle(this);
    }

    public function closestPointToPoint(p:Vector3, target:Vector3):Vector3 {
        var a = this.a;
        var b = this.b;
        var c = this.c;
        var v:Vector3;
        var w:Vector3;

        _vab.subVectors(b, a);
        _vac.subVectors(c, a);
        _vap.subVectors(p, a);
        var d1 = _vab.dot(_vap);
        var d2 = _vac.dot(_vap);
        if (d1 <= 0 && d2 <= 0) {
            return target.copy(a);
        }

        _vbp.subVectors(p, b);
        var d3 = _vab.dot(_vbp);
        var d4 = _vac.dot(_vbp);
        if (d3 >= 0 && d4 <= d3) {
            return target.copy(b);
        }

        var vc = d1 * d4 - d3 * d2;
        if (vc <= 0 && d1 >= 0 && d3 <= 0) {
            v = d1 / (d1 - d3);
            return target.copy(a).addScaledVector(_vab, v);
        }

        _vcp.subVectors(p, c);
        var d5 = _vab.dot(_vcp);
        var d6 = _vac.dot(_vcp);
        if (d6 >= 0 && d5 <= d6) {
            return target.copy(c);
        }

        var vb = d5 * d2 - d1 * d6;
        if (vb <= 0 && d2 >= 0 && d6 <= 0) {
            w = d2 / (d2 - d6);
            return target.copy(a).addScaledVector(_vac, w);
        }

        var va = d3 * d6 - d5 * d4;
        if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
            _vbc.subVectors(c, b);
            w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
            return target.copy(b).addScaledVector(_vbc, w);
        }

        var denom = 1 / (va + vb + vc);
        v = vb * denom;
        w = vc * denom;

        return target.copy(a).addScaledVector(_vab, v).addScaledVector(_vac, w);
    }

    public function equals(triangle:Triangle):Bool {
        return triangle.a.equals(this.a) && triangle.b.equals(this.b) && triangle.c.equals(this.c);
    }
}

// Static variables
static var _v0 = new Vector3();
static var _v1 = new Vector3();
static var _v2 = new Vector3();
static var _v3 = new Vector3();
static var _vab = new Vector3();
static var _vac = new Vector3();
static var _vbc = new Vector3();
static var _vap = new Vector3();
static var _vbp = new Vector3();
static var _vcp = new Vector3();