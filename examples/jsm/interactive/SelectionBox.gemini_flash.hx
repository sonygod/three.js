import three.core.Frustum;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Quaternion;
import three.objects.Mesh;
import three.objects.Line;
import three.objects.Points;
import three.objects.InstancedMesh;
import three.objects.Object3D;
import three.cameras.Camera;

/**
 * This is a class to check whether objects are in a selection area in 3D space
 */
class SelectionBox {
    private static _frustum:Frustum = new Frustum();
    private static _center:Vector3 = new Vector3();
    private static _tmpPoint:Vector3 = new Vector3();
    private static _vecNear:Vector3 = new Vector3();
    private static _vecTopLeft:Vector3 = new Vector3();
    private static _vecTopRight:Vector3 = new Vector3();
    private static _vecDownRight:Vector3 = new Vector3();
    private static _vecDownLeft:Vector3 = new Vector3();
    private static _vecFarTopLeft:Vector3 = new Vector3();
    private static _vecFarTopRight:Vector3 = new Vector3();
    private static _vecFarDownRight:Vector3 = new Vector3();
    private static _vecFarDownLeft:Vector3 = new Vector3();
    private static _vectemp1:Vector3 = new Vector3();
    private static _vectemp2:Vector3 = new Vector3();
    private static _vectemp3:Vector3 = new Vector3();
    private static _matrix:Matrix4 = new Matrix4();
    private static _quaternion:Quaternion = new Quaternion();
    private static _scale:Vector3 = new Vector3();

    public camera:Camera;
    public scene:Object3D;
    public startPoint:Vector3;
    public endPoint:Vector3;
    public collection:Array<Object3D> = [];
    public instances:Dynamic<Array<Int>> = {};
    public deep:Float = Math.POSITIVE_INFINITY;

    public function new(camera:Camera, scene:Object3D, deep:Float = Math.POSITIVE_INFINITY) {
        this.camera = camera;
        this.scene = scene;
        this.startPoint = new Vector3();
        this.endPoint = new Vector3();
        this.deep = deep;
    }

    public function select(startPoint:Vector3 = null, endPoint:Vector3 = null):Array<Object3D> {
        this.startPoint = startPoint != null ? startPoint : this.startPoint;
        this.endPoint = endPoint != null ? endPoint : this.endPoint;
        this.collection = [];

        this.updateFrustum(this.startPoint, this.endPoint);
        this.searchChildInFrustum(SelectionBox._frustum, this.scene);

        return this.collection;
    }

    public function updateFrustum(startPoint:Vector3 = null, endPoint:Vector3 = null) {
        startPoint = startPoint != null ? startPoint : this.startPoint;
        endPoint = endPoint != null ? endPoint : this.endPoint;

        // Avoid invalid frustum
        if (startPoint.x == endPoint.x) {
            endPoint.x += Math.EPSILON;
        }

        if (startPoint.y == endPoint.y) {
            endPoint.y += Math.EPSILON;
        }

        this.camera.updateProjectionMatrix();
        this.camera.updateMatrixWorld();

        if (this.camera.isPerspectiveCamera) {
            SelectionBox._tmpPoint.copy(startPoint);
            SelectionBox._tmpPoint.x = Math.min(startPoint.x, endPoint.x);
            SelectionBox._tmpPoint.y = Math.max(startPoint.y, endPoint.y);
            endPoint.x = Math.max(startPoint.x, endPoint.x);
            endPoint.y = Math.min(startPoint.y, endPoint.y);

            SelectionBox._vecNear.setFromMatrixPosition(this.camera.matrixWorld);
            SelectionBox._vecTopLeft.copy(SelectionBox._tmpPoint);
            SelectionBox._vecTopRight.set(endPoint.x, SelectionBox._tmpPoint.y, 0);
            SelectionBox._vecDownRight.copy(endPoint);
            SelectionBox._vecDownLeft.set(SelectionBox._tmpPoint.x, endPoint.y, 0);

            SelectionBox._vecTopLeft.unproject(this.camera);
            SelectionBox._vecTopRight.unproject(this.camera);
            SelectionBox._vecDownRight.unproject(this.camera);
            SelectionBox._vecDownLeft.unproject(this.camera);

            SelectionBox._vectemp1.copy(SelectionBox._vecTopLeft).sub(SelectionBox._vecNear);
            SelectionBox._vectemp2.copy(SelectionBox._vecTopRight).sub(SelectionBox._vecNear);
            SelectionBox._vectemp3.copy(SelectionBox._vecDownRight).sub(SelectionBox._vecNear);
            SelectionBox._vectemp1.normalize();
            SelectionBox._vectemp2.normalize();
            SelectionBox._vectemp3.normalize();

            SelectionBox._vectemp1.multiplyScalar(this.deep);
            SelectionBox._vectemp2.multiplyScalar(this.deep);
            SelectionBox._vectemp3.multiplyScalar(this.deep);
            SelectionBox._vectemp1.add(SelectionBox._vecNear);
            SelectionBox._vectemp2.add(SelectionBox._vecNear);
            SelectionBox._vectemp3.add(SelectionBox._vecNear);

            var planes = SelectionBox._frustum.planes;
            planes[0].setFromCoplanarPoints(SelectionBox._vecNear, SelectionBox._vecTopLeft, SelectionBox._vecTopRight);
            planes[1].setFromCoplanarPoints(SelectionBox._vecNear, SelectionBox._vecTopRight, SelectionBox._vecDownRight);
            planes[2].setFromCoplanarPoints(SelectionBox._vecDownRight, SelectionBox._vecDownLeft, SelectionBox._vecNear);
            planes[3].setFromCoplanarPoints(SelectionBox._vecDownLeft, SelectionBox._vecTopLeft, SelectionBox._vecNear);
            planes[4].setFromCoplanarPoints(SelectionBox._vecTopRight, SelectionBox._vecDownRight, SelectionBox._vecDownLeft);
            planes[5].setFromCoplanarPoints(SelectionBox._vectemp3, SelectionBox._vectemp2, SelectionBox._vectemp1);
            planes[5].normal.multiplyScalar(-1);
        } else if (this.camera.isOrthographicCamera) {
            var left = Math.min(startPoint.x, endPoint.x);
            var top = Math.max(startPoint.y, endPoint.y);
            var right = Math.max(startPoint.x, endPoint.x);
            var down = Math.min(startPoint.y, endPoint.y);

            SelectionBox._vecTopLeft.set(left, top, -1);
            SelectionBox._vecTopRight.set(right, top, -1);
            SelectionBox._vecDownRight.set(right, down, -1);
            SelectionBox._vecDownLeft.set(left, down, -1);

            SelectionBox._vecFarTopLeft.set(left, top, 1);
            SelectionBox._vecFarTopRight.set(right, top, 1);
            SelectionBox._vecFarDownRight.set(right, down, 1);
            SelectionBox._vecFarDownLeft.set(left, down, 1);

            SelectionBox._vecTopLeft.unproject(this.camera);
            SelectionBox._vecTopRight.unproject(this.camera);
            SelectionBox._vecDownRight.unproject(this.camera);
            SelectionBox._vecDownLeft.unproject(this.camera);

            SelectionBox._vecFarTopLeft.unproject(this.camera);
            SelectionBox._vecFarTopRight.unproject(this.camera);
            SelectionBox._vecFarDownRight.unproject(this.camera);
            SelectionBox._vecFarDownLeft.unproject(this.camera);

            var planes = SelectionBox._frustum.planes;
            planes[0].setFromCoplanarPoints(SelectionBox._vecTopLeft, SelectionBox._vecFarTopLeft, SelectionBox._vecFarTopRight);
            planes[1].setFromCoplanarPoints(SelectionBox._vecTopRight, SelectionBox._vecFarTopRight, SelectionBox._vecFarDownRight);
            planes[2].setFromCoplanarPoints(SelectionBox._vecFarDownRight, SelectionBox._vecFarDownLeft, SelectionBox._vecDownLeft);
            planes[3].setFromCoplanarPoints(SelectionBox._vecFarDownLeft, SelectionBox._vecFarTopLeft, SelectionBox._vecTopLeft);
            planes[4].setFromCoplanarPoints(SelectionBox._vecTopRight, SelectionBox._vecDownRight, SelectionBox._vecDownLeft);
            planes[5].setFromCoplanarPoints(SelectionBox._vecFarDownRight, SelectionBox._vecFarTopRight, SelectionBox._vecFarTopLeft);
            planes[5].normal.multiplyScalar(-1);
        } else {
            Sys.println("THREE.SelectionBox: Unsupported camera type.");
        }
    }

    public function searchChildInFrustum(frustum:Frustum, object:Object3D) {
        if (Std.is(object, Mesh) || Std.is(object, Line) || Std.is(object, Points)) {
            if (Std.is(object, InstancedMesh)) {
                this.instances[object.uuid] = [];
                for (instanceId in 0...object.count) {
                    object.getMatrixAt(instanceId, SelectionBox._matrix);
                    SelectionBox._matrix.decompose(SelectionBox._center, SelectionBox._quaternion, SelectionBox._scale);
                    SelectionBox._center.applyMatrix4(object.matrixWorld);

                    if (frustum.containsPoint(SelectionBox._center)) {
                        this.instances[object.uuid].push(instanceId);
                    }
                }
            } else {
                if (object.geometry.boundingSphere == null) object.geometry.computeBoundingSphere();

                SelectionBox._center.copy(object.geometry.boundingSphere.center);
                SelectionBox._center.applyMatrix4(object.matrixWorld);

                if (frustum.containsPoint(SelectionBox._center)) {
                    this.collection.push(object);
                }
            }
        }

        if (object.children.length > 0) {
            for (x in 0...object.children.length) {
                this.searchChildInFrustum(frustum, object.children[x]);
            }
        }
    }
}