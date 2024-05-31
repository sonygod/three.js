// File path: three.hx/src/math/Spherical.hx

import MathUtils from './MathUtils.hx';

/**
 * Ref: https://en.wikipedia.org/wiki/Spherical_coordinate_system
 *
 * phi (the polar angle) is measured from the positive y-axis. The positive y-axis is up.
 * theta (the azimuthal angle) is measured from the positive z-axis.
 */
class Spherical {

	var radius:Float;
	var phi:Float; // polar angle
	var theta:Float; // azimuthal angle

	public function new(radius = 1, phi = 0, theta = 0) {
		this.radius = radius;
		this.phi = phi;
		this.theta = theta;
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
		const EPS = 0.000001;
		this.phi = Math.max(EPS, Math.min(Math.PI - EPS, this.phi));
		return this;
	}

	public function setFromVector3(v:{x:Float, y:Float, z:Float}):Spherical {
		return this.setFromCartesianCoords(v.x, v.y, v.z);
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

// Since Haxe does not support export statements like JavaScript, you can use the following line to use the class in other files:
// import Spherical from './math/Spherical.hx';