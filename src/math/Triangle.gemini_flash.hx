import kha.math.Vector3;

class Triangle {
	public var a: Vector3;
	public var b: Vector3;
	public var c: Vector3;

	static var _v0:Vector3 = new Vector3();
	static var _v1:Vector3 = new Vector3();
	static var _v2:Vector3 = new Vector3();
	static var _v3:Vector3 = new Vector3();

	static var _vab:Vector3 = new Vector3();
	static var _vac:Vector3 = new Vector3();
	static var _vbc:Vector3 = new Vector3();
	static var _vap:Vector3 = new Vector3();
	static var _vbp:Vector3 = new Vector3();
	static var _vcp:Vector3 = new Vector3();

	public function new(a:Vector3 = null, b:Vector3 = null, c:Vector3 = null) {
		if (a == null) a = new Vector3();
		if (b == null) b = new Vector3();
		if (c == null) c = new Vector3();
		this.a = a;
		this.b = b;
		this.c = c;
	}

	public static function getNormal(a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
		target.sub(c, b);
		_v0.sub(a, b);
		target.cross(target, _v0);

		var targetLengthSq = target.lengthSq();
		if (targetLengthSq > 0) {
			return target.multiply(1 / Math.sqrt(targetLengthSq));
		}

		return target.set(0, 0, 0);
	}

	public static function getBarycoord(point:Vector3, a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
		_v0.sub(c, a);
		_v1.sub(b, a);
		_v2.sub(point, a);

		var dot00 = _v0.dot(_v0);
		var dot01 = _v0.dot(_v1);
		var dot02 = _v0.dot(_v2);
		var dot11 = _v1.dot(_v1);
		var dot12 = _v1.dot(_v2);

		var denom = (dot00 * dot11 - dot01 * dot01);

		// collinear or singular triangle
		if (denom == 0) {
			target.set(0, 0, 0);
			return null;
		}

		var invDenom = 1 / denom;
		var u = (dot11 * dot02 - dot01 * dot12) * invDenom;
		var v = (dot00 * dot12 - dot01 * dot02) * invDenom;

		// barycentric coordinates must always sum to 1
		return target.set(1 - u - v, v, u);
	}

	public static function containsPoint(point:Vector3, a:Vector3, b:Vector3, c:Vector3):Bool {
		// if the triangle is degenerate then we can't contain a point
		if (getBarycoord(point, a, b, c, _v3) == null) {
			return false;
		}

		return (_v3.x >= 0) && (_v3.y >= 0) && ((_v3.x + _v3.y) <= 1);
	}

	public static function getInterpolation(point:Vector3, p1:Vector3, p2:Vector3, p3:Vector3, v1:Vector3, v2:Vector3, v3:Vector3, target:Vector3):Vector3 {
		if (getBarycoord(point, p1, p2, p3, _v3) == null) {
			target.x = 0;
			target.y = 0;
			target.z = 0;
			return null;
		}

		target.set(0, 0, 0);
		target.addScaled(v1, _v3.x);
		target.addScaled(v2, _v3.y);
		target.addScaled(v3, _v3.z);

		return target;
	}

	public static function isFrontFacing(a:Vector3, b:Vector3, c:Vector3, direction:Vector3):Bool {
		_v0.sub(c, b);
		_v1.sub(a, b);

		// strictly front facing
		return (_v0.cross(_v0, _v1).dot(direction) < 0);
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

	// No direct equivalent for fromBufferAttribute in Kha
	// public function setFromAttributeAndIndices(attribute, i0, i1, i2) {
	// 	this.a.fromBufferAttribute(attribute, i0);
	// 	this.b.fromBufferAttribute(attribute, i1);
	// 	this.c.fromBufferAttribute(attribute, i2);
	//
	// 	return this;
	// }

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
		_v0.sub(this.c, this.b);
		_v1.sub(this.a, this.b);

		return _v0.cross(_v0, _v1).length() * 0.5;
	}

	public function getMidpoint(target:Vector3):Vector3 {
		return target.add(this.a).add(this.b).add(this.c).multiply(1 / 3);
	}

	public function getNormal(target:Vector3):Vector3 {
		return Triangle.getNormal(this.a, this.b, this.c, target);
	}

	// No direct equivalent for Plane in Kha
	// public function getPlane(target) {
	// 	return target.setFromCoplanarPoints(this.a, this.b, this.c);
	// }

	public function getBarycoord(point:Vector3, target:Vector3):Vector3 {
		return Triangle.getBarycoord(point, this.a, this.b, this.c, target);
	}

	public function getInterpolation(point:Vector3, v1:Vector3, v2:Vector3, v3:Vector3, target:Vector3):Vector3 {
		return Triangle.getInterpolation(point, this.a, this.b, this.c, v1, v2, v3, target);
	}

	public function containsPoint(point:Vector3):Bool {
		return Triangle.containsPoint(point, this.a, this.b, this.c);
	}

	public function isFrontFacing(direction:Vector3):Bool {
		return Triangle.isFrontFacing(this.a, this.b, this.c, direction);
	}

	// No direct equivalent for intersectsBox in Kha
	// public function intersectsBox(box) {
	// 	return box.intersectsTriangle(this);
	// }

	public function closestPointToPoint(p:Vector3, target:Vector3):Vector3 {
		var a = this.a;
		var b = this.b;
		var c = this.c;
		var v:Float, w:Float;

		// algorithm thanks to Real-Time Collision Detection by Christer Ericson,
		// published by Morgan Kaufmann Publishers, (c) 2005 Elsevier Inc.,
		// under the accompanying license; see chapter 5.1.5 for detailed explanation.
		// basically, we're distinguishing which of the voronoi regions of the triangle
		// the point lies in with the minimum amount of redundant computation.

		_vab.sub(b, a);
		_vac.sub(c, a);
		_vap.sub(p, a);
		var d1 = _vab.dot(_vap);
		var d2 = _vac.dot(_vap);
		if (d1 <= 0 && d2 <= 0) {
			// vertex region of A; barycentric coords (1, 0, 0)
			return target.copy(a);
		}

		_vbp.sub(p, b);
		var d3 = _vab.dot(_vbp);
		var d4 = _vac.dot(_vbp);
		if (d3 >= 0 && d4 <= d3) {
			// vertex region of B; barycentric coords (0, 1, 0)
			return target.copy(b);
		}

		var vc = d1 * d4 - d3 * d2;
		if (vc <= 0 && d1 >= 0 && d3 <= 0) {
			v = d1 / (d1 - d3);
			// edge region of AB; barycentric coords (1-v, v, 0)
			return target.copy(a).addScaled(_vab, v);
		}

		_vcp.sub(p, c);
		var d5 = _vab.dot(_vcp);
		var d6 = _vac.dot(_vcp);
		if (d6 >= 0 && d5 <= d6) {
			// vertex region of C; barycentric coords (0, 0, 1)
			return target.copy(c);
		}

		var vb = d5 * d2 - d1 * d6;
		if (vb <= 0 && d2 >= 0 && d6 <= 0) {
			w = d2 / (d2 - d6);
			// edge region of AC; barycentric coords (1-w, 0, w)
			return target.copy(a).addScaled(_vac, w);
		}

		var va = d3 * d6 - d5 * d4;
		if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
			_vbc.sub(c, b);
			w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
			// edge region of BC; barycentric coords (0, 1-w, w)
			return target.copy(b).addScaled(_vbc, w); // edge region of BC
		}

		// face region
		var denom = 1 / (va + vb + vc);
		// u = va * denom
		v = vb * denom;
		w = vc * denom;

		return target.copy(a).addScaled(_vab, v).addScaled(_vac, w);
	}

	public function equals(triangle:Triangle):Bool {
		return triangle.a.equals(this.a) && triangle.b.equals(this.b) && triangle.c.equals(this.c);
	}
}