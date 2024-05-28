import Vector2;

class Box2 {
	public var min:Vector2;
	public var max:Vector2;
	public var isBox2:Bool;

	public function new(min:Vector2 = Vector2.make(+Infinity, +Infinity), max:Vector2 = Vector2.make(-Infinity, -Infinity)) {
		this.isBox2 = true;
		this.min = min;
		this.max = max;
	}

	public function set(min:Vector2, max:Vector2):Box2 {
		this.min.copy(min);
		this.max.copy(max);
		return this;
	}

	public function setFromPoints(points:Array<Vector2>):Box2 {
		this.makeEmpty();
		for (i in 0...points.length) {
			this.expandByPoint(points[i]);
		}
		return this;
	}

	public function setFromCenterAndSize(center:Vector2, size:Vector2):Box2 {
		var halfSize = size.clone().scale(0.5);
		this.min = center.clone().subtract(halfSize);
		this.max = center.clone().add(halfSize);
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
		this.min.set(+Infinity, +Infinity);
		this.max.set(-Infinity, -Infinity);
		return this;
	}

	public function isEmpty():Bool {
		// this is a more robust check for empty than ( volume <= 0 ) because volume can get positive with two negative axes
		return this.max.x < this.min.x || this.max.y < this.min.y;
	}

	public function getCenter(target:Vector2):Vector2 {
		return this.isEmpty() ? target.set(0, 0) : target.addVectors(this.min, this.max).scale(0.5);
	}

	public function getSize(target:Vector2):Vector2 {
		return this.isEmpty() ? target.set(0, 0) : target.subtractVectors(this.max, this.min);
	}

	public function expandByPoint(point:Vector2):Box2 {
		this.min.min(point);
		this.max.max(point);
		return this;
	}

	public function expandByVector(vector:Vector2):Box2 {
		this.min.subtract(vector);
		this.max.add(vector);
		return this;
	}

	public function expandByScalar(scalar:Float):Box2 {
		this.min.addScalar(-scalar);
		this.max.addScalar(scalar);
		return this;
	}

	public function containsPoint(point:Vector2):Bool {
		return point.x < this.min.x || point.x > this.max.x || point.y < this.min.y || point.y > this.max.y ? false : true;
	}

	public function containsBox(box:Box2):Bool {
		return this.min.x <= box.min.x && box.max.x <= this.max.x && this.min.y <= box.min.y && box.max.y <= this.max.y;
	}

	public function getParameter(point:Vector2, target:Vector2):Vector2 {
		// This can potentially have a divide by zero if the box
		// has a size dimension of 0.
		return target.set((point.x - this.min.x) / (this.max.x - this.min.x), (point.y - this.min.y) / (this.max.y - this.min.y));
	}

	public function intersectsBox(box:Box2):Bool {
		// using 4 splitting planes to rule out intersections
		return box.max.x < this.min.x || box.min.x > this.max.x || box.max.y < this.min.y || box.min.y > this.max.y ? false : true;
	}

	public function clampPoint(point:Vector2, target:Vector2):Vector2 {
		return target.copy(point).clamp(this.min, this.max);
	}

	public function distanceToPoint(point:Vector2):Float {
		return this.clampPoint(point, Vector2._vector).distanceTo(point);
	}

	public function intersect(box:Box2):Box2 {
		this.min.max(box.min);
		this.max.min(box.max);
		if (this.isEmpty()) this.makeEmpty();
		return this;
	}

	public function union(box:Box2):Box2 {
		this.min.min(box.min);
		this.max.max(box.max);
		return this;
	}

	public function translate(offset:Vector2):Box2 {
		this.min.add(offset);
		this.max.add(offset);
		return this;
	}

	public function equals(box:Box2):Bool {
		return box.min.equals(this.min) && box.max.equals(this.max);
	}
}