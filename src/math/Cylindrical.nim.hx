// Ref: https://en.wikipedia.org/wiki/Cylindrical_coordinate_system

class Cylindrical {

    public var radius:Float; // distance from the origin to a point in the x-z plane
    public var theta:Float; // counterclockwise angle in the x-z plane measured in radians from the positive z-axis
    public var y:Float; // height above the x-z plane

    public function new(radius:Float = 1, theta:Float = 0, y:Float = 0) {

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

        return Type.createEmptyInstance(Type.getClass(this)).copy(this);

    }

}