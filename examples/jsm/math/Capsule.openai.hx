package three.math;

import three.math.Vector3;

class Capsule {
    public var start:Vector3;
    public var end:Vector3;
    public var radius:Float;

    public function new(?start:Vector3 = new Vector3(0, 0, 0), ?end:Vector3 = new Vector3(0, 1, 0), ?radius:Float = 1) {
        this.start = start;
        this.end = end;
        this.radius = radius;
    }

    public function clone():Capsule {
        return new Capsule(start.clone(), end.clone(), radius);
    }

    public function set(start:Vector3, end:Vector3, radius:Float) {
        this.start.copy(start);
        this.end.copy(end);
        this.radius = radius;
    }

    public function copy(capsule:Capsule) {
        start.copy(capsule.start);
        end.copy(capsule.end);
        radius = capsule.radius;
    }

    public function getCenter(target:Vector3):Vector3 {
        return target.copy(end).add(start).multiplyScalar(0.5);
    }

    public function translate(v:Vector3) {
        start.add(v);
        end.add(v);
    }

    public function checkAABBAxis(p1x:Float, p1y:Float, p2x:Float, p2y:Float, minx:Float, maxx:Float, miny:Float, maxy:Float, radius:Float):Bool {
        return (minx - p1x < radius || minx - p2x < radius) &&
               (p1x - maxx < radius || p2x - maxx < radius) &&
               (miny - p1y < radius || miny - p2y < radius) &&
               (p1y - maxy < radius || p2y - maxy < radius);
    }

    public function intersectsBox(box:{ min:Vector3, max:Vector3 }):Bool {
        return checkAABBAxis(start.x, start.y, end.x, end.y, box.min.x, box.max.x, box.min.y, box.max.y, radius) &&
               checkAABBAxis(start.x, start.z, end.x, end.z, box.min.x, box.max.x, box.min.z, box.max.z, radius) &&
               checkAABBAxis(start.y, start.z, end.y, end.z, box.min.y, box.max.y, box.min.z, box.max.z, radius);
    }
}