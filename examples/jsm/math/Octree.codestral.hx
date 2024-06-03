import three.math.Box3;
import three.math.Line3;
import three.math.Plane;
import three.math.Sphere;
import three.math.Triangle;
import three.math.Vector3;
import three.core.Layers;
import three.math.Capsule;

class Octree {
    private var _v1:Vector3 = new Vector3();
    private var _v2:Vector3 = new Vector3();
    private var _point1:Vector3 = new Vector3();
    private var _point2:Vector3 = new Vector3();
    private var _plane:Plane = new Plane();
    private var _line1:Line3 = new Line3();
    private var _line2:Line3 = new Line3();
    private var _sphere:Sphere = new Sphere();
    private var _capsule:Capsule = new Capsule();
    private var _temp1:Vector3 = new Vector3();
    private var _temp2:Vector3 = new Vector3();
    private var _temp3:Vector3 = new Vector3();
    private var EPS:Float = 1e-10;

    public function lineToLineClosestPoints(line1:Line3, line2:Line3, target1:Vector3 = null, target2:Vector3 = null) {
        var r:Vector3 = _temp1.copy(line1.end).sub(line1.start);
        var s:Vector3 = _temp2.copy(line2.end).sub(line2.start);
        var w:Vector3 = _temp3.copy(line2.start).sub(line1.start);

        var a:Float = r.dot(s);
        var b:Float = r.dot(r);
        var c:Float = s.dot(s);
        var d:Float = s.dot(w);
        var e:Float = r.dot(w);

        var t1:Float;
        var t2:Float;
        var divisor:Float = b * c - a * a;

        if (Math.abs(divisor) < EPS) {
            var d1:Float = -d / c;
            var d2:Float = (a - d) / c;

            if (Math.abs(d1 - 0.5) < Math.abs(d2 - 0.5)) {
                t1 = 0;
                t2 = d1;
            } else {
                t1 = 1;
                t2 = d2;
            }
        } else {
            t1 = (d * a + e * c) / divisor;
            t2 = (t1 * a - d) / c;
        }

        t2 = Math.max(0, Math.min(1, t2));
        t1 = Math.max(0, Math.min(1, t1));

        if (target1 != null) {
            target1.copy(r).multiplyScalar(t1).add(line1.start);
        }

        if (target2 != null) {
            target2.copy(s).multiplyScalar(t2).add(line2.start);
        }
    }

    public var box:Box3;
    public var bounds:Box3;
    public var subTrees:Array<Octree> = [];
    public var triangles:Array<Triangle> = [];
    public var layers:Layers = new Layers();

    public function new(box:Box3) {
        this.box = box;
        this.bounds = new Box3();
    }

    public function addTriangle(triangle:Triangle):Octree {
        this.bounds.min.x = Math.min(this.bounds.min.x, triangle.a.x, triangle.b.x, triangle.c.x);
        this.bounds.min.y = Math.min(this.bounds.min.y, triangle.a.y, triangle.b.y, triangle.c.y);
        this.bounds.min.z = Math.min(this.bounds.min.z, triangle.a.z, triangle.b.z, triangle.c.z);
        this.bounds.max.x = Math.max(this.bounds.max.x, triangle.a.x, triangle.b.x, triangle.c.x);
        this.bounds.max.y = Math.max(this.bounds.max.y, triangle.a.y, triangle.b.y, triangle.c.y);
        this.bounds.max.z = Math.max(this.bounds.max.z, triangle.a.z, triangle.b.z, triangle.c.z);

        this.triangles.push(triangle);

        return this;
    }

    public function calcBox():Octree {
        this.box = this.bounds.clone();

        // offset small amount to account for regular grid
        this.box.min.x -= 0.01;
        this.box.min.y -= 0.01;
        this.box.min.z -= 0.01;

        return this;
    }

    // ... continue this way for the rest of the class
}