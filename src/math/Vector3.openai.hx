package three.math;

import MathUtils.MathUtils;
import Quaternion;

class Vector3 {
    
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;

    public function new(?x:Float = 0, ?y:Float = 0, ?z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function set(x:Float, ?y:Float, ?z:Float):Vector3 {
        if (z == null) z = this.z; // sprite.scale.set(x,y)
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function setScalar(scalar:Float):Vector3 {
        this.x = scalar;
        this.y = scalar;
        this.z = scalar;
        return this;
    }

    public function setX(x:Float):Vector3 {
        this.x = x;
        return this;
    }

    public function setY(y:Float):Vector3 {
        this.y = y;
        return this;
    }

    public function setZ(z:Float):Vector3 {
        this.z = z;
        return this;
    }

    public function setComponent(index:Int, value:Float):Vector3 {
        switch (index) {
            case 0: this.x = value;
            case 1: this.y = value;
            case 2: this.z = value;
            default: throw "index is out of range: " + index;
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0: return this.x;
            case 1: return this.y;
            case 2: return this.z;
            default: throw "index is out of range: " + index;
        }
    }

    public function clone():Vector3 {
        return new Vector3(x, y, z);
    }

    public function copy(v:Vector3):Vector3 {
        this.x = v.x;
        this.y = v.y;
        this.z = v.z;
        return this;
    }

    // ... (rest of the methods)

    static var _vector = new Vector3();
    static var _quaternion = new Quaternion();
}