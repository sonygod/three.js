import Math.Vector3;
import Math.Sphere;
import Math.Plane;

class Frustum {
	public var planes:Array<Plane> = [new Plane(), new Plane(), new Plane(), new Plane(), new Plane(), new Plane()];

	public function new(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane) {
		this.planes[0] = p0;
		this.planes[1] = p1;
		this.planes[2] = p2;
		this.planes[3] = p3;
		this.planes[4] = p4;
		this.planes[5] = p5;
	}

	public function set(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane):Void {
		this.planes[0] = p0;
		this.planes[1] = p1;
		this.planes[2] = p2;
		this.planes[3] = p3;
		this.planes[4] = p4;
		this.planes[5] = p5;
		return;
	}

	public function copy(frustum:Frustum):Frustum {
		for (i in 0...6) {
			this.planes[i] = frustum.planes[i].clone();
		}
		return this;
	}

	public function setFromProjectionMatrix(m:Matrix4, coordinateSystem:Int):Frustum {
		var me = m.elements;
		var me0 = me[0];
		var me1 = me[1];
		var me2 = me[2];
		var me3 = me[3];
		var me4 = me[4];
		var me5 = me[5];
		var me6 = me[6];
		var me7 = me[7];
		var me8 = me[8];
		var me9 = me[9];
		var me10 = me[10];
		var me11 = me[11];
		var me12 = me[12];
		var me13 = me[13];
		var me14 = me[14];
		var me15 = me[15];

		this.planes[0].setComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize();
		this.planes[1].setComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize();
		this.planes[2].setComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize();
		this.planes[3].setComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize();
		this.planes[4].setComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize();

		if (coordinateSystem == WebGLCoordinateSystem) {
			this.planes[5].setComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize();
		} else if (coordinateSystem == WebGPUCoordinateSystem) {
			this.planes[5].setComponents(me2, me6, me10, me14).normalize();
		} else {
			throw new Error('Frustum.setFromProjectionMatrix(): Invalid coordinate system: ' + coordinateSystem);
		}

		return this;
	}

	public function intersectsObject(object:Dynamic):Bool {
		if (Std.is(object, Dynamic.getFields('boundingSphere'))) {
			if (object.boundingSphere == null) object.computeBoundingSphere();
			var sphere = object.boundingSphere.clone();
			sphere.applyMatrix4(object.matrixWorld);
		} else {
			var geometry = object.geometry;
			if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
			var sphere = geometry.boundingSphere.clone();
			sphere.applyMatrix4(object.matrixWorld);
		}

		return this.intersectsSphere(sphere);
	}

	public function intersectsSprite(sprite:Dynamic):Bool {
		var sphere = new Sphere();
		sphere.center.set(0, 0, 0);
		sphere.radius = 0.7071067811865476;
		sphere.applyMatrix4(sprite.matrixWorld);

		return this.intersectsSphere(sphere);
	}

	public function intersectsSphere(sphere:Sphere):Bool {
		var planes = this.planes;
		var center = sphere.center;
		var negRadius = -sphere.radius;

		for (i in 0...6) {
			var distance = planes[i].distanceToPoint(center);
			if (distance < negRadius) {
				return false;
			}
		}

		return true;
	}

	public function intersectsBox(box:Box3):Bool {
		var planes = this.planes;
		var plane:Plane;
		var _vector = new Vector3();

		for (i in 0...6) {
			plane = planes[i];

			// corner at max distance
			_vector.x = (if (plane.normal.x > 0) box.max.x else box.min.x);
			_vector.y = (if (plane.normal.y > 0) box.max.y else box.min.y);
			_vector.z = (if (plane.normal.z > 0) box.max.z else box.min.z);

			if (plane.distanceToPoint(_vector) < 0) {
				return false;
			}
		}

		return true;
	}

	public function containsPoint(point:Vector3):Bool {
		var planes = this.planes;

		for (i in 0...6) {
			if (planes[i].distanceToPoint(point) < 0) {
				return false;
			}
		}

		return true;
	}

	public function clone():Frustum {
		return new Frustum().copy(this);
	}
}

class Plane {
	public var normal:Vector3;
	public var constant:Float;

	public function new(normal:Vector3, constant:Float) {
		this.normal = normal;
		this.constant = constant;
	}

	public function setComponents(x:Float, y:Float, z:Float, w:Float):Plane {
		this.normal.set(x, y, z);
		this.constant = w;
		return this;
	}

	public function normalize():Plane {
		var inverseNormalLength = 1.0 / this.normal.length;
		this.normal.multiplyScalar(inverseNormalLength);
		this.constant *= inverseNormalLength;

		return this;
	}

	public function distanceToPoint(point:Vector3):Float {
		return this.normal.dot(point) + this.constant;
	}

	public function clone():Plane {
		return new Plane(this.normal.clone(), this.constant);
	}
}

class Vector3 {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function set(x:Float, y:Float, z:Float):Vector3 {
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function clone():Vector3 {
		return new Vector3(this.x, this.y, this.z);
	}

	public function dot(v:Vector3):Float {
		return this.x * v.x + this.y * v.y + this.z * v.z;
	}

	public function length:Float {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}

	public function multiplyScalar(scalar:Float):Vector3 {
		this.x *= scalar;
		this.y *= scalar;
		this.z *= scalar;
		return this;
	}
}

class Sphere {
	public var center:Vector3;
	public var radius:Float;

	public function new(center:Vector3, radius:Float) {
		this.center = center;
		this.radius = radius;
	}

	public function applyMatrix4(matrix:Matrix4):Sphere {
		this.center.applyMatrix4(matrix);
		this.radius = this.radius * matrix.getMaxScaleOnAxis();
		return this;
	}

	public function clone():Sphere {
		return new Sphere(this.center.clone(), this.radius);
	}
}

class Matrix4 {
	public var elements:Array<Float>;

	public function getMaxScaleOnAxis():Float {
		var scaleXSq = this.elements[0] * this.elements[0] + this.elements[1] * this.elements[1] + this.elements[2] * this.elements[2];
		var scaleYSq = this.elements[4] * this.elements[4] + this.elements[5] * this.elements[5] + this.elements[6] * this.elements[6];
		var scaleZSq = this.elements[8] * this.elements[8] + this.elements[9] * this.elements[9] + this.elements[10] * this.elements[10];

		return Math.sqrt(Math.max(scaleXSq, Math.max(scaleYSq, scaleZSq)));
	}
}

enum WebGLCoordinateSystem {
	case 0;
}

enum WebGPUCoordinateSystem {
	case 0;
}