import MathUtils;
import Quaternion;

class Vector3 {
    public var x:Float;
    public var y:Float;
    public var z:Float;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public function set(x:Float, y:Float, z:Float = this.z):Vector3 {
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    // ... 其他方法的转换 ...

    public function applyQuaternion(q:Quaternion):Vector3 {
        var ix = q.w * this.x + q.y * this.z - q.z * this.y;
        var iy = q.w * this.y + q.z * this.x - q.x * this.z;
        var iz = q.w * this.z + q.x * this.y - q.y * this.x;
        var iw = - q.x * this.x - q.y * this.y - q.z * this.z;

        this.x = ix * q.w + iw * - q.x + iy * - q.z - iz * - q.y;
        this.y = iy * q.w + iw * - q.y + iz * - q.x - ix * - q.z;
        this.z = iz * q.w + iw * - q.z + ix * - q.y - iy * - q.x;

        return this;
    }

    // ... 其他方法的转换 ...
}