import js.Browser;

class Spherical {
    public var radius(default, null):Float;
    public var phi(default, null):Float;
    public var theta(default, null):Float;

    public function new(radius:Float = 1.0, phi:Float = 0.0, theta:Float = 0.0) {
        this.radius = radius;
        this.phi = phi;
        this.theta = theta;
    }

    public function set(radius:Float, phi:Float, theta:Float):Void {
        this.radius = radius;
        this.phi = phi;
        this.theta = theta;
    }

    public function clone():Spherical {
        return new Spherical(this.radius, this.phi, this.theta);
    }

    public function copy(other:Spherical):Spherical {
        this.radius = other.radius;
        this.phi = other.phi;
        this.theta = other.theta;
        return this;
    }

    public function makeSafe():Void {
        var EPS:Float = 0.000001;
        if (this.phi < EPS) {
            this.phi = EPS;
        } else if (this.phi > Math.PI - EPS) {
            this.phi = Math.PI - EPS;
        }
    }

    public function setFromVector3(vec:Vector3):Void {
        this.radius = vec.length();
        if (this.radius == 0) {
            this.theta = 0;
            this.phi = 0;
        } else {
            this.theta = Math.atan2(vec.x, vec.z);
            this.phi = Math.acos(Math.clamp(vec.y / this.radius, -1, 1));
        }
    }

    public function setFromCartesianCoords(x:Float, y:Float, z:Float):Void {
        this.setFromVector3(new Vector3(x, y, z));
    }
}

class Vector3 {
    public var x(default, null):Float;
    public var y(default, null):Float;
    public var z(default, null):Float;

    public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function length():Float {
        return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }
}

class Test {
    static function main() {
        // 在这里写你的测试代码
    }
}