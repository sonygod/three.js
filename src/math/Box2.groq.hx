package three.math;

import three.math.Vector2;

class Box2 {
    public var isBox2:Bool = true;
    public var min:Vector2;
    public var max:Vector2;

    public function new(?min:Vector2 = null, ?max:Vector2 = null) {
        if (min == null) min = new Vector2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        if (max == null) max = new Vector2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
        this.min = min;
        this.max = max;
    }

    public function set(min:Vector2, max:Vector2):Box2 {
        this.min.copy(min);
        this.max.copy(max);
        return this;
    }

    public function setFromPoints(points:Array<Vector2>):Box2 {
        makeEmpty();
        for (i in 0...points.length) {
            expandByPoint(points[i]);
        }
        return this;
    }

    public function setFromCenterAndSize(center:Vector2, size:Vector2):Box2 {
        var halfSize:Vector2 = size.clone().multiplyScalar(0.5);
        this.min.copy(center).sub(halfSize);
        this.max.copy(center).add(halfSize);
        return this;
    }

    public function clone():Box2 {
        return new Box2().copy(this);
    }

    public function copy(box:Box2):Box2 {
        this.min.copy(box.min);
        this.max.copy(box.max);
        return this;
    }

    public function makeEmpty():Box2 {
        this.min.x = this.min.y = Math.POSITIVE_INFINITY;
        this.max.x = this.max.y = Math.NEGATIVE_INFINITY;
        return this;
    }

    public function isEmpty():Bool {
        return (max.x < min.x) || (max.y < min.y);
    }

    public function getCenter(target:Vector2):Vector2 {
        return isEmpty() ? target.set(0, 0) : target.addVectors(min, max).multiplyScalar(0.5);
    }

    public function getSize(target:Vector2):Vector2 {
        return isEmpty() ? target.set(0, 0) : target.subVectors(max, min);
    }

    public function expandByPoint(point:Vector2):Box2 {
        min.min(point);
        max.max(point);
        return this;
    }

    public function expandByVector(vector:Vector2):Box2 {
        min.sub(vector);
        max.add(vector);
        return this;
    }

    public function expandByScalar(scalar:Float):Box2 {
        min.addScalar(-scalar);
        max.addScalar(scalar);
        return this;
    }

    public function containsPoint(point:Vector2):Bool {
        return point.x < min.x || point.x > max.x || point.y < min.y || point.y > max.y ? false : true;
    }

    public function containsBox(box:Box2):Bool {
        return min.x <= box.min.x && box.max.x <= max.x && min.y <= box.min.y && box.max.y <= max.y;
    }

    public function getParameter(point:Vector2, target:Vector2):Vector2 {
        return target.set((point.x - min.x) / (max.x - min.x), (point.y - min.y) / (max.y - min.y));
    }

    public function intersectsBox(box:Box2):Bool {
        return box.max.x < min.x || box.min.x > max.x || box.max.y < min.y || box.min.y > max.y ? false : true;
    }

    public function clampPoint(point:Vector2, target:Vector2):Vector2 {
        return target.copy(point).clamp(min, max);
    }

    public function distanceToPoint(point:Vector2):Float {
        return clampPoint(point, _vector).distanceTo(point);
    }

    public function intersect(box:Box2):Box2 {
        min.max(box.min);
        max.min(box.max);
        if (isEmpty()) makeEmpty();
        return this;
    }

    public function union(box:Box2):Box2 {
        min.min(box.min);
        max.max(box.max);
        return this;
    }

    public function translate(offset:Vector2):Box2 {
        min.add(offset);
        max.add(offset);
        return this;
    }

    public function equals(box:Box2):Bool {
        return box.min.equals(min) && box.max.equals(max);
    }

    static var _vector:Vector2 = new Vector2();
}