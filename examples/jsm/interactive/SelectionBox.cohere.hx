import js.three.Frustum;
import js.three.Vector3;
import js.three.Matrix4;
import js.three.Quaternion;

class SelectionBox {
    var _frustum:Frustum;
    var _center:Vector3;
    var _tmpPoint:Vector3;
    var _vecNear:Vector3;
    var _vecTopLeft:Vector3;
    var _vecTopRight:Vector3;
    var _vecDownRight:Vector3;
    var _vecDownLeft:Vector3;
    var _vecFarTopLeft:Vector3;
    var _vecFarTopRight:Vector3;
    var _vecFarDownRight:Vector3;
    var _vecFarDownLeft:Vector3;
    var _vectemp1:Vector3;
    var _vectemp2:Vector3;
    var _vectemp3:Vector3;
    var _matrix:Matrix4;
    var _quaternion:Quaternion;
    var _scale:Vector3;
    var camera:Dynamic;
    var scene:Dynamic;
    var startPoint:Vector3;
    var endPoint:Vector3;
    var collection:Array<Dynamic>;
    var instances:Array<Dynamic>;
    var deep:Float;

    public function new(camera:Dynamic, scene:Dynamic, ?deep:Float) {
        this._frustum = new Frustum();
        this._center = new Vector3();
        this._tmpPoint = new Vector3();
        this._vecNear = new Vector3();
        this._vecTopLeft = new Vector3();
        this._vecTopRight = new Vector3();
        this._vecDownRight = new Vector3();
        this._vecDownLeft = new Vector3();
        this._vecFarTopLeft = new Vector3();
        this._vecFarTopRight = new Vector3();
        this._vecFarDownRight = new Vector3();
        this._vecFarDownLeft = new Vector3();
        this._vectemp1 = new Vector3();
        this._vectemp2 = new Vector3();
        this._vectemp3 = new Vector3();
        this._matrix = new Matrix4();
        this._quaternion = new Quaternion();
        this._scale = new Vector3();
        this.camera = camera;
        this.scene = scene;
        this.startPoint = new Vector3();
        this.endPoint = new Vector3();
        this.collection = [];
        this.instances = {};
        this.deep = if (deep != null) deep else Float.POSITIVE_INFINITY;
    }

    public function select(?startPoint:Vector3, ?endPoint:Vector3):Array<Dynamic> {
        this.startPoint = if (startPoint != null) startPoint else this.startPoint;
        this.endPoint = if (endPoint != null) endPoint else this.endPoint;
        this.collection = [];
        this.updateFrustum(this.startPoint, this.endPoint);
        this.searchChildInFrustum(_frustum, this.scene);
        return this.collection;
    }

    public function updateFrustum(?startPoint:Vector3, ?endPoint:Vector3) {
        startPoint = if (startPoint != null) startPoint else this.startPoint;
        endPoint = if (endPoint != null) endPoint else this.endPoint;
        if (startPoint.x == endPoint.x) {
            endPoint.x += 2e-16;
        }
        if (startPoint.y == endPoint.y) {
            endPoint.y += 2e-16;
        }
        camera.updateProjectionMatrix();
        camera.updateMatrixWorld();
        if (camera.isPerspectiveCamera) {
            _tmpPoint.copy(startPoint);
            _tmpPoint.x = min(startPoint.x, endPoint.x);
            _tmpPoint.y = max(startPoint.y, endPoint.y);
            endPoint.x = max(startPoint.x, endPoint.x);
            endPoint.y = min(startPoint.y, endPoint.y);
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
            var planes = _frustum.planes;
            planes[0].setFromCoplanarPoints(_vecNear, _vecTopLeft, _vecTopRight);
            planes[1].setFromCoplanarPoints(_vecNear, _vecTopRight, _vecDownRight);
            planes[2].setFromCoplanarPoints(_vecDownRight, _vecDownLeft, _vecNear);
            planes[3].setFromCoplanarPoints(_vecDownLeft, _vecTopLeft, _vecNear);
            planes[4].setFromCoplanarPoints(_vecTopRight, _vecDownRight, _vecDownLeft);
            planes[5].setFromCoplanarPoints(_vectemp3, _vectemp2, _vectemp1);
            planes[5].normal.multiplyScalar(-1);
        } else if (camera.isOrthographicCamera) {
            var left = min(startPoint.x, endPoint.x);
            var top = max(startPoint.y, endPoint.y);
            var right = max(startPoint.x, endPoint.x);
            var down = min(startPoint.y, endPoint.y);
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
            var planes = _frustum.planes;
            planes[0].setFromCoplanarPoints(_vecTopLeft, _vecFarTopLeft, _vecFarTopRight);
            planes[1].setFromCoplanarPoints(_vecTopRight, _vecFarTopRight, _vecFarDownRight);
            planes[2].setFromCoplanarPoints(_vecFarDownRight, _vecFarDownLeft, _vecDownLeft);
            planes[3].setFromCoplanarPoints(_vecFarDownLeft, _vecFarTopLeft, _vecTopLeft);
            planes[4].setFromCoplanarPoints(_vecTopRight, _vecDownRight, _vecDownLeft);
            planes[5].setFromCoplanarPoints(_vecFarDownRight, _vecFarTopRight, _vecFarTopLeft);
            planes[5].normal.multiplyScalar(-1);
        } else {
            throw "THREE.SelectionBox: Unsupported camera type.";
        }
    }

    public function searchChildInFrustum(frustum:Frustum, object:Dynamic) {
        if (object.isMesh || object.isLine || object.isPoints) {
            if (object.isInstancedMesh) {
                this.instances[object.uuid] = [];
                var instanceId = 0;
                while (instanceId < object.count) {
                    object.getMatrixAt(instanceId, _matrix);
                    _matrix.decompose(_center, _quaternion, _scale);
                    _center.applyMatrix4(object.matrixWorld);
                    if (frustum.containsPoint(_center)) {
                        this.instances[object.uuid].push(instanceId);
                    }
                    instanceId++;
                }
            } else {
                if (object.geometry.boundingSphere == null) {
                    object.geometry.computeBoundingSphere();
                }
                _center.copy(object.geometry.boundingSphere.center);
                _center.applyMatrix4(object.matrixWorld);
                if (frustum.containsPoint(_center)) {
                    this.collection.push(object);
                }
            }
        }
        if (object.children.length > 0) {
            var x = 0;
            while (x < object.children.length) {
                this.searchChildInFrustum(frustum, object.children[x]);
                x++;
            }
        }
    }
}