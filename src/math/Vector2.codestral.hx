import Math;

class Vector2 {
    public var x: Float;
    public var y: Float;

    public function new(x: Float = 0.0, y: Float = 0.0) {
        this.x = x;
        this.y = y;
    }

    public function get width(): Float {
        return this.x;
    }

    public function set width(value: Float) {
        this.x = value;
    }

    public function get height(): Float {
        return this.y;
    }

    public function set height(value: Float) {
        this.y = value;
    }

    public function set(x: Float, y: Float): Vector2 {
        this.x = x;
        this.y = y;
        return this;
    }

    public function setScalar(scalar: Float): Vector2 {
        this.x = scalar;
        this.y = scalar;
        return this;
    }

    public function setX(x: Float): Vector2 {
        this.x = x;
        return this;
    }

    public function setY(y: Float): Vector2 {
        this.y = y;
        return this;
    }

    public function setComponent(index: Int, value: Float): Vector2 {
        switch (index) {
            case 0:
                this.x = value;
                break;
            case 1:
                this.y = value;
                break;
            default:
                throw "index is out of range: " + index;
        }
        return this;
    }

    public function getComponent(index: Int): Float {
        switch (index) {
            case 0:
                return this.x;
            case 1:
                return this.y;
            default:
                throw "index is out of range: " + index;
        }
    }

    public function clone(): Vector2 {
        return new Vector2(this.x, this.y);
    }

    public function copy(v: Vector2): Vector2 {
        this.x = v.x;
        this.y = v.y;
        return this;
    }

    public function add(v: Vector2): Vector2 {
        this.x += v.x;
        this.y += v.y;
        return this;
    }

    public function addScalar(s: Float): Vector2 {
        this.x += s;
        this.y += s;
        return this;
    }

    public function addVectors(a: Vector2, b: Vector2): Vector2 {
        this.x = a.x + b.x;
        this.y = a.y + b.y;
        return this;
    }

    public function addScaledVector(v: Vector2, s: Float): Vector2 {
        this.x += v.x * s;
        this.y += v.y * s;
        return this;
    }

    public function sub(v: Vector2): Vector2 {
        this.x -= v.x;
        this.y -= v.y;
        return this;
    }

    public function subScalar(s: Float): Vector2 {
        this.x -= s;
        this.y -= s;
        return this;
    }

    public function subVectors(a: Vector2, b: Vector2): Vector2 {
        this.x = a.x - b.x;
        this.y = a.y - b.y;
        return this;
    }

    public function multiply(v: Vector2): Vector2 {
        this.x *= v.x;
        this.y *= v.y;
        return this;
    }

    public function multiplyScalar(scalar: Float): Vector2 {
        this.x *= scalar;
        this.y *= scalar;
        return this;
    }

    public function divide(v: Vector2): Vector2 {
        this.x /= v.x;
        this.y /= v.y;
        return this;
    }

    public function divideScalar(scalar: Float): Vector2 {
        return this.multiplyScalar(1 / scalar);
    }

    // Note: This function assumes that 'm' is an instance of a Matrix3 class
    // public function applyMatrix3(m: Matrix3): Vector2 {
    //     const e = m.elements;
    //     const x = this.x, y = this.y;
    //     this.x = e[0] * x + e[3] * y + e[6];
    //     this.y = e[1] * x + e[4] * y + e[7];
    //     return this;
    // }

    public function min(v: Vector2): Vector2 {
        this.x = Math.min(this.x, v.x);
        this.y = Math.min(this.y, v.y);
        return this;
    }

    public function max(v: Vector2): Vector2 {
        this.x = Math.max(this.x, v.x);
        this.y = Math.max(this.y, v.y);
        return this;
    }

    public function clamp(min: Vector2, max: Vector2): Vector2 {
        this.x = Math.max(min.x, Math.min(max.x, this.x));
        this.y = Math.max(min.y, Math.min(max.y, this.y));
        return this;
    }

    public function clampScalar(minVal: Float, maxVal: Float): Vector2 {
        this.x = Math.max(minVal, Math.min(maxVal, this.x));
        this.y = Math.max(minVal, Math.min(maxVal, this.y));
        return this;
    }

    public function clampLength(min: Float, max: Float): Vector2 {
        const length = this.length();
        return this.divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
    }

    public function floor(): Vector2 {
        this.x = Math.floor(this.x);
        this.y = Math.floor(this.y);
        return this;
    }

    public function ceil(): Vector2 {
        this.x = Math.ceil(this.x);
        this.y = Math.ceil(this.y);
        return this;
    }

    public function round(): Vector2 {
        this.x = Math.round(this.x);
        this.y = Math.round(this.y);
        return this;
    }

    public function roundToZero(): Vector2 {
        this.x = Math.trunc(this.x);
        this.y = Math.trunc(this.y);
        return this;
    }

    public function negate(): Vector2 {
        this.x = -this.x;
        this.y = -this.y;
        return this;
    }

    public function dot(v: Vector2): Float {
        return this.x * v.x + this.y * v.y;
    }

    public function cross(v: Vector2): Float {
        return this.x * v.y - this.y * v.x;
    }

    public function lengthSq(): Float {
        return this.x * this.x + this.y * this.y;
    }

    public function length(): Float {
        return Math.sqrt(this.x * this.x + this.y * this.y);
    }

    public function manhattanLength(): Float {
        return Math.abs(this.x) + Math.abs(this.y);
    }

    public function normalize(): Vector2 {
        return this.divideScalar(this.length() || 1);
    }

    public function angle(): Float {
        const angle = Math.atan2(-this.y, -this.x) + Math.PI;
        return angle;
    }

    public function angleTo(v: Vector2): Float {
        const denominator = Math.sqrt(this.lengthSq() * v.lengthSq());
        if (denominator === 0) return Math.PI / 2;
        const theta = this.dot(v) / denominator;
        return Math.acos(Math.min(Math.max(theta, -1), 1));
    }

    public function distanceTo(v: Vector2): Float {
        return Math.sqrt(this.distanceToSquared(v));
    }

    public function distanceToSquared(v: Vector2): Float {
        const dx = this.x - v.x, dy = this.y - v.y;
        return dx * dx + dy * dy;
    }

    public function manhattanDistanceTo(v: Vector2): Float {
        return Math.abs(this.x - v.x) + Math.abs(this.y - v.y);
    }

    public function setLength(length: Float): Vector2 {
        return this.normalize().multiplyScalar(length);
    }

    public function lerp(v: Vector2, alpha: Float): Vector2 {
        this.x += (v.x - this.x) * alpha;
        this.y += (v.y - this.y) * alpha;
        return this;
    }

    public function lerpVectors(v1: Vector2, v2: Vector2, alpha: Float): Vector2 {
        this.x = v1.x + (v2.x - v1.x) * alpha;
        this.y = v1.y + (v2.y - v1.y) * alpha;
        return this;
    }

    public function equals(v: Vector2): Bool {
        return (v.x === this.x) && (v.y === this.y);
    }

    public function fromArray(array: Array<Float>, offset: Int = 0): Vector2 {
        this.x = array[offset];
        this.y = array[offset + 1];
        return this;
    }

    public function toArray(array: Array<Float> = null, offset: Int = 0): Array<Float> {
        if (array == null) array = [];
        array[offset] = this.x;
        array[offset + 1] = this.y;
        return array;
    }

    // Note: This function assumes that 'attribute' is an instance of a BufferAttribute class
    // public function fromBufferAttribute(attribute: BufferAttribute, index: Int): Vector2 {
    //     this.x = attribute.getX(index);
    //     this.y = attribute.getY(index);
    //     return this;
    // }

    public function rotateAround(center: Vector2, angle: Float): Vector2 {
        const c = Math.cos(angle), s = Math.sin(angle);
        const x = this.x - center.x;
        const y = this.y - center.y;
        this.x = x * c - y * s + center.x;
        this.y = x * s + y * c + center.y;
        return this;
    }

    public function random(): Vector2 {
        this.x = Math.random();
        this.y = Math.random();
        return this;
    }
}

class Main {
    static function main() {
        var vector = new Vector2(1, 2);
        trace(vector.x); // Output: 1
        trace(vector.y); // Output: 2
    }
}