package three.math;

import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.math.Vector3;
import three.math.Sphere;
import three.math.Plane;

class Frustum {
    public var planes:Array<Plane>;

    public function new(p0:Plane = null, p1:Plane = null, p2:Plane = null, p3:Plane = null, p4:Plane = null, p5:Plane = null) {
        planes = [p0 != null ? p0 : new Plane(), p1 != null ? p1 : new Plane(), p2 != null ? p2 : new Plane(), p3 != null ? p3 : new Plane(), p4 != null ? p4 : new Plane(), p5 != null ? p5 : new Plane()];
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

    public function setFromProjectionMatrix(m:Matrix4, ?coordinateSystem:Int = WebGLCoordinateSystem):Frustum {
        var planes:Array<Plane> = this.planes;
        var me:Array<Float> = m.elements;
        planes[0].setComponents(me[3] - me[0], me[7] - me[4], me[11] - me[8], me[15] - me[12]).normalize();
        planes[1].setComponents(me[3] + me[0], me[7] + me[4], me[11] + me[8], me[15] + me[12]).normalize();
        planes[2].setComponents(me[3] + me[1], me[7] + me[5], me[11] + me[9], me[15] + me[13]).normalize();
        planes[3].setComponents(me[3] - me[1], me[7] - me[5], me[11] - me[9], me[15] - me[13]).normalize();
        planes[4].setComponents(me[3] - me[2], me[7] - me[6], me[11] - me[10], me[15] - me[14]).normalize();
        if (coordinateSystem == WebGLCoordinateSystem) {
            planes[5].setComponents(me[3] + me[2], me[7] + me[6], me[11] + me[10], me[15] + me[14]).normalize();
        } else if (coordinateSystem == WebGPUCoordinateSystem) {
            planes[5].setComponents(me[2], me[6], me[10], me[14]).normalize();
        } else {
            throw new Error('THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: ' + coordinateSystem);
        }
        return this;
    }

    public function intersectsObject(object:Object3D):Bool {
        if (object.boundingSphere != null) {
            if (object.boundingSphere == null) object.computeBoundingSphere();
            _sphere.copy(object.boundingSphere).applyMatrix4(object.matrixWorld);
        } else {
            var geometry:Geometry = object.geometry;
            if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
            _sphere.copy(geometry.boundingSphere).applyMatrix4(object.matrixWorld);
        }
        return intersectsSphere(_sphere);
    }

    public function intersectsSprite(sprite:Sprite):Bool {
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

    public function intersectsBox(box:Box3):Bool {
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