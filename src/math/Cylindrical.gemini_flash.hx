import haxe.io.Float32;
import haxe.io.Float64;

class Cylindrical {

	public var radius:Float64;
	public var theta:Float64;
	public var y:Float64;

	public function new(radius:Float64 = 1, theta:Float64 = 0, y:Float64 = 0) {
		this.radius = radius;
		this.theta = theta;
		this.y = y;
	}

	public function set(radius:Float64, theta:Float64, y:Float64):Cylindrical {
		this.radius = radius;
		this.theta = theta;
		this.y = y;
		return this;
	}

	public function copy(other:Cylindrical):Cylindrical {
		this.radius = other.radius;
		this.theta = other.theta;
		this.y = other.y;
		return this;
	}

	public function setFromVector3(v:Vector3):Cylindrical {
		return this.setFromCartesianCoords(v.x, v.y, v.z);
	}

	public function setFromCartesianCoords(x:Float64, y:Float64, z:Float64):Cylindrical {
		this.radius = Math.sqrt(x * x + z * z);
		this.theta = Math.atan2(x, z);
		this.y = y;
		return this;
	}

	public function clone():Cylindrical {
		return new Cylindrical().copy(this);
	}
}