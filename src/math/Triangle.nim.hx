import Vector3.{Vector3, Vector3Default};

class Triangle {
    public var a(default, null):Vector3;
    public var b(default, null):Vector3;
    public var c(default, null):Vector3;

    public function new(a?:Vector3, b?:Vector3, c?:Vector3) {
        this.a = a ?? new Vector3();
        this.b = b ?? new Vector3();
        this.c = c ?? new Vector3();
    }

    public static function getNormal(a:Vector3, b:Vector3, c:Vector3, target:Vector3):Vector3 {
        target.subtract(c, b);
        var v0 = new Vector3();
        v0.subtract(a, b);
        target.cross(v0);

        var targetLengthSq = target.lengthSq();
        if (targetLengthSq > 0) {
            return target.multiplyScalar(1 / Math.sqrt(targetLengthSq));
        }

        return target.set(0, 0, 0);
    }

    // ... other methods ...

    public function clone():Triangle {
        var clone = new Triangle();
        clone.copy(this);
        return clone;
    }

    public function copy(triangle:Triangle):Triangle {
        this.a.copy(triangle.a);
        this.b.copy(triangle.b);
        this.c.copy(triangle.c);
        return this;
    }

    // ... other methods ...
}