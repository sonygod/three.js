import haxe.extern.Math;

class Spherical {
	public var radius:Float;
	public var phi:Float;
	public var theta:Float;

	public function new(radius:Float = 1, phi:Float = 0, theta:Float = 0) {
		this.radius = radius;
		this.phi = phi; // polar angle
		this.theta = theta; // azimuthal angle
	}

	public function set(radius:Float, phi:Float, theta:Float):Spherical {
		this.radius = radius;
		this.phi = phi;
		this.theta = theta;
		return this;
	}

	public function copy(other:Spherical):Spherical {
		this.radius = other.radius;
		this.phi = other.phi;
		this.theta = other.theta;
		return this;
	}

	// restrict phi to be between EPS and PI-EPS
	public function makeSafe():Spherical {
		final EPS = 0.000001;
		this.phi = Math.max(EPS, Math.min(Math.PI - EPS, this.phi));
		return this;
	}

	public function setFromVector3(v:{x:Float, y:Float, z:Float}):Spherical {
		return setFromCartesianCoords(v.x, v.y, v.z);
	}

	public function setFromCartesianCoords(x:Float, y:Float, z:Float):Spherical {
		this.radius = Math.sqrt(x * x + y * y + z * z);

		if (this.radius == 0) {
			this.theta = 0;
			this.phi = 0;
		} else {
			this.theta = Math.atan2(x, z);
			this.phi = Math.acos(MathUtils.clamp(y / this.radius, -1, 1));
		}

		return this;
	}

	public function clone():Spherical {
		return new Spherical().copy(this);
	}
}

class MathUtils {
	public static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.min(Math.max(value, min), max);
	}
}