import three.math.Plane;
import three.math.Sphere;
import three.math.Vector3;
import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;

class Frustum {
	public var planes:Array<Plane>;

	public function new(p0:Plane = new Plane(), p1:Plane = new Plane(), p2:Plane = new Plane(), p3:Plane = new Plane(), p4:Plane = new Plane(), p5:Plane = new Plane()) {
		this.planes = [p0, p1, p2, p3, p4, p5];
	}

	public function set(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane):Frustum {
		this.planes[0] = p0.clone();
		this.planes[1] = p1.clone();
		this.planes[2] = p2.clone();
		this.planes[3] = p3.clone();
		this.planes[4] = p4.clone();
		this.planes[5] = p5.clone();
		return this;
	}

	public function copy(frustum:Frustum):Frustum {
		for (i in 0...6) {
			this.planes[i] = frustum.planes[i].clone();
		}
		return this;
	}

	public function setFromProjectionMatrix(m:Dynamic, coordinateSystem:Int = WebGLCoordinateSystem):Frustum {
		final me = m.elements;
		final me0 = me[0];
		final me1 = me[1];
		final me2 = me[2];
		final me3 = me[3];
		final me4 = me[4];
		final me5 = me[5];
		final me6 = me[6];
		final me7 = me[7];
		final me8 = me[8];
		final me9 = me[9];
		final me10 = me[10];
		final me11 = me[11];
		final me12 = me[12];
		final me13 = me[13];
		final me14 = me[14];
		final me15 = me[15];

		this.planes[0] = new Plane(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize();
		this.planes[1] = new Plane(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize();
		this.planes[2] = new Plane(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize();
		this.planes[3] = new Plane(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize();
		this.planes[4] = new Plane(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize();

		switch (coordinateSystem) {
			case WebGLCoordinateSystem:
				this.planes[5] = new Plane(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize();
			case WebGPUCoordinateSystem:
				this.planes[5] = new Plane(me2, me6, me10, me14).normalize();
			default:
				throw new Error('THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: ' + coordinateSystem);
		}

		return this;
	}

	public function intersectsObject(object:Dynamic):Bool {
		var sphere = new Sphere();
		if (object.boundingSphere != null) {
			sphere = object.boundingSphere.clone();
			sphere.applyMatrix4(object.matrixWorld);
		} else {
			var geometry = object.geometry;
			if (geometry.boundingSphere != null) {
				sphere = geometry.boundingSphere.clone();
				sphere.applyMatrix4(object.matrixWorld);
			} else {
				return false;
			}
		}
		return this.intersectsSphere(sphere);
	}

	public function intersectsSprite(sprite:Dynamic):Bool {
		var sphere = new Sphere(new Vector3(), 0.7071067811865476);
		sphere.applyMatrix4(sprite.matrixWorld);
		return this.intersectsSphere(sphere);
	}

	public function intersectsSphere(sphere:Sphere):Bool {
		for (i in 0...6) {
			final plane = this.planes[i];
			final distance = plane.distanceToPoint(sphere.center);
			if (distance < -sphere.radius) {
				return false;
			}
		}
		return true;
	}

	public function intersectsBox(box:Dynamic):Bool {
		for (i in 0...6) {
			final plane = this.planes[i];
			final normal = plane.normal;
			final vector = new Vector3();
			vector.x = normal.x > 0 ? box.max.x : box.min.x;
			vector.y = normal.y > 0 ? box.max.y : box.min.y;
			vector.z = normal.z > 0 ? box.max.z : box.min.z;
			if (plane.distanceToPoint(vector) < 0) {
				return false;
			}
		}
		return true;
	}

	public function containsPoint(point:Vector3):Bool {
		for (i in 0...6) {
			if (this.planes[i].distanceToPoint(point) < 0) {
				return false;
			}
		}
		return true;
	}

	public function clone():Frustum {
		return new Frustum().copy(this);
	}
}