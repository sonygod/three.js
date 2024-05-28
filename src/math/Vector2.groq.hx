Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.math;

import MathUtils;

class Vector2 {
    public var x:Float = 0;
    public var y:Float = 0;

    public function new(x:Float = 0, y:Float = 0) {
        this.x = x;
        this.y = y;
    }

    public var width(get, set):Float;
    private function get_width():Float {
        return x;
    }
    private function set_width(value:Float):Float {
        x = value;
        return value;
    }

    public var height(get, set):Float;
    private function get_height():Float {
        return y;
    }
    private function set_height(value:Float):Float {
        y = value;
        return value;
    }

    public function set(x:Float, y:Float):Vector2 {
        this.x = x;
        this.y = y;
        return this;
    }

    public function setScalar(scalar:Float):Vector2 {
        x = scalar;
        y = scalar;
        return this;
    }

    public function setX(x:Float):Vector2 {
        this.x = x;
        return this;
    }

    public function setY(y:Float):Vector2 {
        this.y = y;
        return this;
    }

    public function setComponent(index:Int, value:Float):Vector2 {
        switch (index) {
            case 0:
                x = value;
            case 1:
                y = value;
            default:
                throw new Error('index is out of range: ' + index);
        }
        return this;
    }

    public function getComponent(index:Int):Float {
        switch (index) {
            case 0:
                return x;
            case 1:
                return y;
            default:
                throw new Error('index is out of range: ' + index);
        }
    }

    public function clone():Vector2 {
        return new Vector2(x, y);
    }

    public function copy(v:Vector2):Vector2 {
        x = v.x;
        y = v.y;
        return this;
    }

    public function add(v:Vector2):Vector2 {
        x += v.x;
        y += v.y;
        return this;
    }

    public function addScalar(s:Float):Vector2 {
        x += s;
        y += s;
        return this;
    }

    public function addVectors(a:Vector2, b:Vector2):Vector2 {
        x = a.x + b.x;
        y = a.y + b.y;
        return this;
    }

    public function addScaledVector(v:Vector2, s:Float):Vector2 {
        x += v.x * s;
        y += v.y * s;
        return this;
    }

    public function sub(v:Vector2):Vector2 {
        x -= v.x;
        y -= v.y;
        return this;
    }

    public function subScalar(s:Float):Vector2 {
        x -= s;
        y -= s;
        return this;
    }

    public function subVectors(a:Vector2, b:Vector2):Vector2 {
        x = a.x - b.x;
        y = a.y - b.y;
        return this;
    }

    public function multiply(v:Vector2):Vector2 {
        x *= v.x;
        y *= v.y;
        return this;
    }

    public function multiplyScalar(scalar:Float):Vector2 {
        x *= scalar;
        y *= scalar;
        return this;
    }

    public function divide(v:Vector2):Vector2 {
        x /= v.x;
        y /= v.y;
        return this;
    }

    public function divideScalar(scalar:Float):Vector2 {
        return multiplyScalar(1 / scalar);
    }

    public function applyMatrix3(m:Array<Float>):Vector2 {
        var e:Array<Float> = m;
        var x1:Float = x, y1:Float = y;
        x = e[0] * x1 + e[3] * y1 + e[6];
        y = e[1] * x1 + e[4] * y1 + e[7];
        return this;
    }

    public function min(v:Vector2):Vector2 {
        x = Math.min(x, v.x);
        y = Math.min(y, v.y);
        return this;
    }

    public function max(v:Vector2):Vector2 {
        x = Math.max(x, v.x);
        y = Math.max(y, v.y);
        return this;
    }

    public function clamp(min:Vector2, max:Vector2):Vector2 {
        x = Math.max(min.x, Math.min(max.x, x));
        y = Math.max(min.y, Math.min(max.y, y));
        return this;
    }

    public function clampScalar(minVal:Float, maxVal:Float):Vector2 {
        x = Math.max(minVal, Math.min(maxVal, x));
        y = Math.max(minVal, Math.min(maxVal, y));
        return this;
    }

    public function clampLength(min:Float, max:Float):Vector2 {
        var length:Float = length();
        return divideScalar(length || 1).multiplyScalar(Math.max(min, Math.min(max, length)));
    }

    public function floor():Vector2 {
        x = Math.floor(x);
        y = Math.floor(y);
        return this;
    }

    public function ceil():Vector2 {
        x = Math.ceil(x);
        y = Math.ceil(y);
        return this;
    }

    public function round():Vector2 {
        x = Math.round(x);
        y = Math.round(y);
        return this;
    }

    public function roundToZero():Vector2 {
        x = Math.trunc(x);
        y = Math.trunc(y);
        return this;
    }

    public function negate():Vector2 {
        x = -x;
        y = -y;
        return this;
    }

    public function dot(v:Vector2):Float {
        return x * v.x + y * v.y;
    }

    public function cross(v:Vector2):Float {
        return x * v.y - y * v.x;
    }

    public function lengthSq():Float {
        return x * x + y * y;
    }

    public function length():Float {
        return Math.sqrt(lengthSq());
    }

    public function manhattanLength():Float {
        return Math.abs(x) + Math.abs(y);
    }

    public function normalize():Vector2 {
        return divideScalar(length() || 1);
    }

    public function angle():Float {
        var angle:Float = Math.atan2(-y, -x) + Math.PI;
        return angle;
    }

    public function angleTo(v:Vector2):Float {
        var denominator:Float = Math.sqrt(lengthSq() * v.lengthSq());
        if (denominator == 0) return Math.PI / 2;
        var theta:Float = dot(v) / denominator;
        return Math.acos(MathUtils.clamp(theta, -1, 1));
    }

    public function distanceTo(v:Vector2):Float {
        return Math.sqrt(distanceToSquared(v));
    }

    public function distanceToSquared(v:Vector2):Float {
        var dx:Float = x - v.x, dy:Float = y - v.y;
        return dx * dx + dy * dy;
    }

    public function manhattanDistanceTo(v:Vector2):Float {
        return Math.abs(x - v.x) + Math.abs(y - v.y);
    }

    public function setLength(length:Float):Vector2 {
        return normalize().multiplyScalar(length);
    }

    public function lerp(v:Vector2, alpha:Float):Vector2 {
        x += (v.x - x) * alpha;
        y += (v.y - y) * alpha;
        return this;
    }

    public function lerpVectors(v1:Vector2, v2:Vector2, alpha:Float):Vector2 {
        x = v1.x + (v2.x - v1.x) * alpha;
        y = v1.y + (v2.y - v1.y) * alpha;
        return this;
    }

    public function equals(v:Vector2):Bool {
        return x == v.x && y == v.y;
    }

    public function fromArray(array:Array<Float>, offset:Int = 0):Vector2 {
        x = array[offset];
        y = array[offset + 1];
        return this;
    }

    public function toArray(array:Array<Float> = [], offset:Int = 0):Array<Float> {
        array[offset] = x;
        array[offset + 1] = y;
        return array;
    }

    public function fromBufferAttribute(attribute:Any, index:Int):Vector2 {
        x = attribute.getX(index);
        y = attribute.getY(index);
        return this;
    }

    public function rotateAround(center:Vector2, angle:Float):Vector2 {
        var c:Float = Math.cos(angle), s:Float = Math.sin(angle);
        var x1:Float = x - center.x, y1:Float = y - center.y;
        x = x1 * c - y1 * s + center.x;
        y = x1 * s + y1 * c + center.y;
        return this;
    }

    public function random():Vector2 {
        x = Math.random();
        y = Math.random();
        return this;
    }

    public function iterator():Iterator<Float> {
        return new Vector2Iterator(this);
    }
}

class Vector2Iterator {
    private var v:Vector2;
    private var index:Int;

    public function new(v:Vector2) {
        this.v = v;
        this.index = 0;
    }

    public function hasNext():Bool {
        return index < 2;
    }

    public function next():Float {
        return v[index++] == 0 ? v.x : v.y;
    }
}
```
Note that I've used the `Math` module from Haxe's standard library for mathematical operations. I've also replaced the `import * as MathUtils from './MathUtils.js';` statement with `import MathUtils;`, assuming that `MathUtils` is a Haxe module that provides the necessary mathematical utility functions.