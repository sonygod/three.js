import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;
import three.math.Matrix4;

class Frustum {

    public var planes:Array<Plane>;

    private var _sphere:Sphere = new Sphere();
    private var _vector:Vector3 = new Vector3();

    public function new(p0:Plane = new Plane(), p1:Plane = new Plane(), p2:Plane = new Plane(), p3:Plane = new Plane(), p4:Plane = new Plane(), p5:Plane = new Plane()) {
        this.planes = [p0, p1, p2, p3, p4, p5];
    }

    public function set(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane):Frustum {
        this.planes[0].copy(p0);
        this.planes[1].copy(p1);
        this.planes[2].copy(p2);
        this.planes[3].copy(p3);
        this.planes[4].copy(p4);
        this.planes[5].copy(p5);

        return this;
    }

    public function copy(frustum:Frustum):Frustum {
        for (i in 0...6) {
            this.planes[i].copy(frustum.planes[i]);
        }

        return this;
    }

    public function setFromProjectionMatrix(m:Matrix4, coordinateSystem:Int = WebGLCoordinateSystem):Frustum {
        var me = m.elements;
        var me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3];
        var me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7];
        var me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11];
        var me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];

        this.planes[0].setComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize();
        this.planes[1].setComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize();
        this.planes[2].setComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize();
        this.planes[3].setComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize();
        this.planes[4].setComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize();

        if (coordinateSystem == WebGLCoordinateSystem) {
            this.planes[5].setComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize();
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            this.planes[5].setComponents(me2, me6, me10, me14).normalize();
        } else {
            throw "THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: " + coordinateSystem;
        }

        return this;
    }

    // ... continue in the same way
}