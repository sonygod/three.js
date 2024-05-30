import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;

class Frustum {
    public var planes:Array<Plane>;

    public function new(p0:Plane = new Plane(), p1:Plane = new Plane(), p2:Plane = new Plane(), p3:Plane = new Plane(), p4:Plane = new Plane(), p5:Plane = new Plane()) {
        this.planes = [p0, p1, p2, p3, p4, p5];
    }

    public function set(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane):Frustum {
        var planes = this.planes;
        planes[0].copy(p0);
        planes[1].copy(p1);
        planes[2].copy(p2);
        planes[3].copy(p3);
        planes[4].copy(p4);
        planes[5].copy(p5);
        return this;
    }

    public function copy(frustum:Frustum):Frustum {
        var planes = this.planes;
        for (i in 0...6) {
            planes[i].copy(frustum.planes[i]);
        }
        return this;
    }

    public function setFromProjectionMatrix(m:Matrix4, coordinateSystem:CoordinateSystem = WebGLCoordinateSystem):Frustum {
        var planes = this.planes;
        var me = m.elements;
        var me0 = me[0], me1 = me[1], me2 = me[2], me3 = me[3];
        var me4 = me[4], me5 = me[5], me6 = me[6], me7 = me[7];
        var me8 = me[8], me9 = me[9], me10 = me[10], me11 = me[11];
        var me12 = me[12], me13 = me[13], me14 = me[14], me15 = me[15];

        planes[0].setComponents(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize();
        planes[1].setComponents(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize();
        planes[2].setComponents(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize();
        planes[3].setComponents(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize();
        planes[4].setComponents(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize();

        if (coordinateSystem == WebGLCoordinateSystem) {
            planes[5].setComponents(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize();
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            planes[5].setComponents(me2, me6, me10, me14).normalize();
        } else {
            throw "THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: " + Std.string(coordinateSystem);
        }

        return this;
    }

    public function intersectsObject(object:Object3D):Bool {
        var _sphere:Sphere = new Sphere();
        if (object.boundingSphere != null) {
            if (object.boundingSphere == null) object.computeBoundingSphere();
            _sphere.copy(object.boundingSphere).applyMatrix4(object.matrixWorld);
        } else {
            var geometry = object.geometry;
            if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
            _sphere.copy(geometry.boundingSphere).applyMatrix4(object.matrixWorld);
        }
        return this.intersectsSphere(_sphere);
    }

    public function intersectsSprite(sprite:Sprite):Bool {
        var _sphere:Sphere = new Sphere();
        _sphere.center.set(0, 0, 0);
        _sphere.radius = 0.7071067811865476;
        _sphere.applyMatrix4(sprite.matrixWorld);
        return this.intersectsSphere(_sphere);
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var planes = this.planes;
        var center = sphere.center;
        var negRadius = -sphere.radius;

        for (i in 0...6) {
            var distance = planes[i].distanceToPoint(center);
            if (distance < negRadius) {
                return false;
            }
        }
        return true;
    }

    public function intersectsBox(box:Box3):Bool {
        var planes = this.planes;
        var _vector:Vector3 = new Vector3();

        for (i in 0...6) {
            var plane = planes[i];

            // corner at max distance
            _vector.x = plane.normal.x > 0 ? box.max.x : box.min.x;
            _vector.y = plane.normal.y > 0 ? box.max.y : box.min.y;
            _vector.z = plane.normal.z > 0 ? box.max.z : box.min.z;

            if (plane.distanceToPoint(_vector) < 0) {
                return false;
            }
        }
        return true;
    }

    public function containsPoint(point:Vector3):Bool {
        var planes = this.planes;

        for (i in 0...6) {
            if (planes[i].distanceToPoint(point) < 0) {
                return false;
            }
        }
        return true;
    }

    public function clone():Frustum {
        return new Frustum().copy(this);
    }
}