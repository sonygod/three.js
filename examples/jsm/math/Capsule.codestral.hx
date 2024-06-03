package three;

import three.math.Vector3;
import three.math.Box3;

class Capsule {

    public var start: Vector3;
    public var end: Vector3;
    public var radius: Float;

    public function new(start: Vector3 = null, end: Vector3 = null, radius: Float = 1.0) {

        if (start == null) start = new Vector3();
        if (end == null) end = new Vector3(0, 1, 0);

        this.start = start;
        this.end = end;
        this.radius = radius;

    }

    public function clone(): Capsule {

        return new Capsule(this.start.clone(), this.end.clone(), this.radius);

    }

    public function set(start: Vector3, end: Vector3, radius: Float) {

        this.start.copy(start);
        this.end.copy(end);
        this.radius = radius;

    }

    public function copy(capsule: Capsule) {

        this.start.copy(capsule.start);
        this.end.copy(capsule.end);
        this.radius = capsule.radius;

    }

    public function getCenter(target: Vector3): Vector3 {

        return target.copy(this.end).add(this.start).multiplyScalar(0.5);

    }

    public function translate(v: Vector3) {

        this.start.add(v);
        this.end.add(v);

    }

    private function checkAABBAxis(p1x: Float, p1y: Float, p2x: Float, p2y: Float, minx: Float, maxx: Float, miny: Float, maxy: Float, radius: Float): Bool {

        return (
            (minx - p1x < radius || minx - p2x < radius) &&
            (p1x - maxx < radius || p2x - maxx < radius) &&
            (miny - p1y < radius || miny - p2y < radius) &&
            (p1y - maxy < radius || p2y - maxy < radius)
        );

    }

    public function intersectsBox(box: Box3): Bool {

        return (
            this.checkAABBAxis(
                this.start.x, this.start.y, this.end.x, this.end.y,
                box.min.x, box.max.x, box.min.y, box.max.y,
                this.radius) &&
            this.checkAABBAxis(
                this.start.x, this.start.z, this.end.x, this.end.z,
                box.min.x, box.max.x, box.min.z, box.max.z,
                this.radius) &&
            this.checkAABBAxis(
                this.start.y, this.start.z, this.end.y, this.end.z,
                box.min.y, box.max.y, box.min.z, box.max.z,
                this.radius)
        );

    }

}