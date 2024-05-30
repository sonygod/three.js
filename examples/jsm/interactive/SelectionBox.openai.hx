package three.js.examples.jsm.interactive;

import three.Frustum;
import three.Vector3;
import three.Matrix4;
import three.Quaternion;

class SelectionBox {
    public var camera:Dynamic;
    public var scene:Dynamic;
    public var startPoint:Vector3;
    public var endPoint:Vector3;
    public var collection:Array<Dynamic>;
    public var instances:Map<String, Array<Int>>;
    public var deep:Float;

    public function new(camera:Dynamic, scene:Dynamic, deep:Float = Math.POSITIVE_INFINITY) {
        this.camera = camera;
        this.scene = scene;
        this.startPoint = new Vector3();
        this.endPoint = new Vector3();
        this.collection = [];
        this.instances = new Map<String, Array<Int>>();
        this.deep = deep;
    }

    public function select(startPoint:Vector3, endPoint:Vector3):Array<Dynamic> {
        this.startPoint = startPoint != null ? startPoint : this.startPoint;
        this.endPoint = endPoint != null ? endPoint : this.endPoint;
        this.collection = [];

        updateFrustum(this.startPoint, this.endPoint);
        searchChildInFrustum(_frustum, this.scene);

        return this.collection;
    }

    private var _frustum:Frustum;
    private var _center:Vector3;
    private var _tmpPoint:Vector3;

    private var _vecNear:Vector3;
    private var _vecTopLeft:Vector3;
    private var _vecTopRight:Vector3;
    private var _vecDownRight:Vector3;
    private var _vecDownLeft:Vector3;

    private var _vecFarTopLeft:Vector3;
    private var _vecFarTopRight:Vector3;
    private var _vecFarDownRight:Vector3;
    private var _vecFarDownLeft:Vector3;

    private var _vectemp1:Vector3;
    private var _vectemp2:Vector3;
    private var _vectemp3:Vector3;

    private var _matrix:Matrix4;
    private var _quaternion:Quaternion;
    private var _scale:Vector3;

    private function updateFrustum(startPoint:Vector3, endPoint:Vector3) {
        startPoint = startPoint != null ? startPoint : this.startPoint;
        endPoint = endPoint != null ? endPoint : this.endPoint;

        // Avoid invalid frustum
        if (startPoint.x == endPoint.x) endPoint.x += Math.EPSILON;
        if (startPoint.y == endPoint.y) endPoint.y += Math.EPSILON;

        camera.updateProjectionMatrix();
        camera.updateMatrixWorld();

        if (Std.is(camera, PerspectiveCamera)) {
            _tmpPoint.copy(startPoint);
            _tmpPoint.x = Math.min(startPoint.x, endPoint.x);
            _tmpPoint.y = Math.max(startPoint.y, endPoint.y);
            endPoint.x = Math.max(startPoint.x, endPoint.x);
            endPoint.y = Math.min(startPoint.y, endPoint.y);

            _vecNear.setFromMatrixPosition(camera.matrixWorld);
            _vecTopLeft.copy(_tmpPoint);
            _vecTopRight.set(endPoint.x, _tmpPoint.y, 0);
            _vecDownRight.copy(endPoint);
            _vecDownLeft.set(_tmpPoint.x, endPoint.y, 0);

            _vecTopLeft.unproject(camera);
            _vecTopRight.unproject(camera);
            _vecDownRight.unproject(camera);
            _vecDownLeft.unproject(camera);

            _vectemp1.copy(_vecTopLeft).sub(_vecNear);
            _vectemp2.copy(_vecTopRight).sub(_vecNear);
            _vectemp3.copy(_vecDownRight).sub(_vecNear);
            _vectemp1.normalize();
            _vectemp2.normalize();
            _vectemp3.normalize();

            _vectemp1.multiplyScalar(this.deep);
            _vectemp2.multiplyScalar(this.deep);
            _vectemp3.multiplyScalar(this.deep);
            _vectemp1.add(_vecNear);
            _vectemp2.add(_vecNear);
            _vectemp3.add(_vecNear);

            const planes = _frustum.planes;

            planes[0].setFromCoplanarPoints(_vecNear, _vecTopLeft, _vecTopRight);
            planes[1].setFromCoplanarPoints(_vecNear, _vecTopRight, _vecDownRight);
            planes[2].setFromCoplanarPoints(_vecDownRight, _vecDownLeft, _vecNear);
            planes[3].setFromCoplanarPoints(_vecDownLeft, _vecTopLeft, _vecNear);
            planes[4].setFromCoplanarPoints(_vecTopRight, _vecDownRight, _vecDownLeft);
            planes[5].setFromCoplanarPoints(_vectemp3, _vectemp2, _vectemp1);
            planes[5].normal.multiplyScalar(-1);
        } else if (Std.is(camera, OrthographicCamera)) {
            const left:Float = Math.min(startPoint.x, endPoint.x);
            const top:Float = Math.max(startPoint.y, endPoint.y);
            const right:Float = Math.max(startPoint.x, endPoint.x);
            const down:Float = Math.min(startPoint.y, endPoint.y);

            _vecTopLeft.set(left, top, -1);
            _vecTopRight.set(right, top, -1);
            _vecDownRight.set(right, down, -1);
            _vecDownLeft.set(left, down, -1);

            _vecFarTopLeft.set(left, top, 1);
            _vecFarTopRight.set(right, top, 1);
            _vecFarDownRight.set(right, down, 1);
            _vecFarDownLeft.set(left, down, 1);

            _vecTopLeft.unproject(camera);
            _vecTopRight.unproject(camera);
            _vecDownRight.unproject(camera);
            _vecDownLeft.unproject(camera);

            _vecFarTopLeft.unproject(camera);
            _vecFarTopRight.unproject(camera);
            _vecFarDownRight.unproject(camera);
            _vecFarDownLeft.unproject(camera);

            const planes = _frustum.planes;

            planes[0].setFromCoplanarPoints(_vecTopLeft, _vecFarTopLeft, _vecFarTopRight);
            planes[1].setFromCoplanarPoints(_vecTopRight, _vecFarTopRight, _vecFarDownRight);
            planes[2].setFromCoplanarPoints(_vecFarDownRight, _vecFarDownLeft, _vecDownLeft);
            planes[3].setFromCoplanarPoints(_vecFarDownLeft, _vecFarTopLeft, _vecTopLeft);
            planes[4].setFromCoplanarPoints(_vecTopRight, _vecDownRight, _vecDownLeft);
            planes[5].setFromCoplanarPoints(_vecFarDownRight, _vecFarTopRight, _vecFarTopLeft);
            planes[5].normal.multiplyScalar(-1);
        } else {
            trace('THREE.SelectionBox: Unsupported camera type.');
        }
    }

    private function searchChildInFrustum(frustum:Frustum, object:Dynamic) {
        if (object.isMesh || object.isLine || object.isPoints) {
            if (object.isInstancedMesh) {
                instances[object.uuid] = [];

                for (instanceId in 0...object.count) {
                    object.getMatrixAt(instanceId, _matrix);
                    _matrix.decompose(_center, _quaternion, _scale);
                    _center.applyMatrix4(object.matrixWorld);

                    if (frustum.containsPoint(_center)) {
                        instances[object.uuid].push(instanceId);
                    }
                }
            } else {
                if (object.geometry.boundingSphere == null) object.geometry.computeBoundingSphere();

                _center.copy(object.geometry.boundingSphere.center);

                _center.applyMatrix4(object.matrixWorld);

                if (frustum.containsPoint(_center)) {
                    collection.push(object);
                }
            }
        }

        if (object.children.length > 0) {
            for (child in object.children) {
                searchChildInFrustum(frustum, child);
            }
        }
    }
}