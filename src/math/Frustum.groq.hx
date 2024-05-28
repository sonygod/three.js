package three.math;

import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;

class Frustum {
    public var planes:Array<Plane>;

    public function new(p0:Plane = null, p1:Plane = null, p2:Plane = null, p3:Plane = null, p4:Plane = null, p5:Plane = null) {
        if (p0 == null) p0 = new Plane();
        if (p1 == null) p1 = new Plane();
        if (p2 == null) p2 = new Plane();
        if (p3 == null) p3 = new Plane();
        if (p4 == null) p4 = new Plane();
        if (p5 == null) p5 = new Plane();

        planes = [p0, p1, p2, p3, p4, p5];
    }

    public function set(p0:Plane, p1:Plane, p2:Plane, p3:Plane, p4:Plane, p5:Plane):Frustum {
        var planes:Array<Plane> = this.planes;
        planes[0].copy(p0);
        planes[1].copy(p1);
        planes[2].copy(p2);
        planes[3].copy(p3);
        planes[4].copy(p4);
        planes[5].copy(p5);
        return this;
    }

    public function copy(frustum:Frustum):Frustum {
        var planes:Array<Plane> = this.planes;
        for (i in 0...6) {
            planes[i].copy(frustum.planes[i]);
        }
        return this;
    }

    public function setFromProjectionMatrix(m:Array<Float>, coordinateSystem:Int = WebGLCoordinateSystem):Frustum {
        var planes:Array<Plane> = this.planes;
        var me:Array<Float> = m;
        var me0:Float = me[0], me1:Float = me[1], me2:Float = me[2], me3:Float = me[3];
        var me4:Float = me[4], me5:Float = me[5], me6:Float = me[6], me7:Float = me[7];
        var me8:Float = me[8], me9:Float = me[9], me10:Float = me[10], me11:Float = me[11];
        var me12:Float = me[12], me13:Float = me[13], me14:Float = me[14], me15:Float = me[15];

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
            throw new Error('THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: ' + coordinateSystem);
        }

        return this;
    }

    public function intersectsObject(object:Object):Bool {
        if (object.boundingSphere != null) {
            if (object.boundingSphere == null) object.computeBoundingSphere();
            _sphere.copy(object.boundingSphere).applyMatrix4(object.matrixWorld);
        } else {
            var geometry:Object = object.geometry;
            if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
            _sphere.copy(geometry.boundingSphere).applyMatrix4(object.matrixWorld);
        }
        return intersectsSphere(_sphere);
    }

    public function intersectsSprite(sprite:Object):Bool {
        _sphere.center.set(0, 0, 0);
        _sphere.radius = 0.7071067811865476;
        _sphere.applyMatrix4(sprite.matrixWorld);
        return intersectsSphere(_sphere);
    }

    public function intersectsSphere(sphere:Sphere):Bool {
        var planes:Array<Plane> = this.planes;
        var center:Vector3 = sphere.center;
        var negRadius:Float = -sphere.radius;

        for (i in 0...6) {
            var distance:Float = planes[i].distanceToPoint(center);
            if (distance < negRadius) {
                return false;
            }
        }
        return true;
    }

    public function intersectsBox(box:Object):Bool {
        var planes:Array<Plane> = this.planes;

        for (i in 0...6) {
            var plane:Plane = planes[i];
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
        var planes:Array<Plane> = this.planes;

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

    static var _sphere:Sphere = new Sphere();
    static var _vector:Vector3 = new Vector3();
}