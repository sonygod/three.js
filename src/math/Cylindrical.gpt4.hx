/**
 * Ref: https://en.wikipedia.org/wiki/Cylindrical_coordinate_system
 */

class Cylindrical {

    public var radius:Float;
    public var theta:Float;
    public var y:Float;

    public function new(?radius:Float = 1, ?theta:Float = 0, ?y:Float = 0) {
        this.radius = radius;
        this.theta = theta;
        this.y = y;
    }

    public function set(radius:Float, theta:Float, y:Float):Cylindrical {
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

    public function setFromCartesianCoords(x:Float, y:Float, z:Float):Cylindrical {
        this.radius = Math.sqrt(x * x + z * z);
        this.theta = Math.atan2(x, z);
        this.y = y;
        return this;
    }

    public function clone():Cylindrical {
        return new Cylindrical().copy(this);
    }
}

// Assuming you have a Vector3 class defined somewhere
class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float, y:Float, z:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
}