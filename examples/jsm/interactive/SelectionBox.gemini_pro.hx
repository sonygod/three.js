import three.math.Frustum;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Quaternion;

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

	public camera:three.cameras.Camera;
	public scene:three.core.Object3D;
	public startPoint:Vector3;
	public endPoint:Vector3;
	public collection:Array<three.core.Object3D>;
	public instances:Dynamic;
	public deep:Float;

	public function new(camera:three.cameras.Camera, scene:three.core.Object3D, deep:Float = Math.POSITIVE_INFINITY) {
		this.camera = camera;
		this.scene = scene;
		this.startPoint = new Vector3();
		this.endPoint = new Vector3();
		this.collection = [];
		this.instances = new Dynamic();
		this.deep = deep;
	}

	public function select(startPoint:Vector3 = null, endPoint:Vector3 = null):Array<three.core.Object3D> {
		this.startPoint = startPoint != null ? startPoint : this.startPoint;
		this.endPoint = endPoint != null ? endPoint : this.endPoint;
		this.collection = [];

		this.updateFrustum(this.startPoint, this.endPoint);
		this.searchChildInFrustum(_frustum, this.scene);

		return this.collection;
	}

	public function updateFrustum(startPoint:Vector3 = null, endPoint:Vector3 = null) {
		startPoint = startPoint != null ? startPoint : this.startPoint;
		endPoint = endPoint != null ? endPoint : this.endPoint;

		// Avoid invalid frustum

		if (startPoint.x == endPoint.x) {
			endPoint.x += Number.EPSILON;
		}

		if (startPoint.y == endPoint.y) {
			endPoint.y += Number.EPSILON;
		}

		this.camera.updateProjectionMatrix();
		this.camera.updateMatrixWorld();

		if (cast this.camera to three.cameras.PerspectiveCamera) {
			_tmpPoint.copy(startPoint);
			_tmpPoint.x = Math.min(startPoint.x, endPoint.x);
			_tmpPoint.y = Math.max(startPoint.y, endPoint.y);
			endPoint.x = Math.max(startPoint.x, endPoint.x);
			endPoint.y = Math.min(startPoint.y, endPoint.y);

			_vecNear.setFromMatrixPosition(this.camera.matrixWorld);
			_vecTopLeft.copy(_tmpPoint);
			_vecTopRight.set(endPoint.x, _tmpPoint.y, 0);
			_vecDownRight.copy(endPoint);
			_vecDownLeft.set(_tmpPoint.x, endPoint.y, 0);

			_vecTopLeft.unproject(this.camera);
			_vecTopRight.unproject(this.camera);
			_vecDownRight.unproject(this.camera);
			_vecDownLeft.unproject(this.camera);

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

		} else if (cast this.camera to three.cameras.OrthographicCamera) {
			var left = Math.min(startPoint.x, endPoint.x);
			var top = Math.max(startPoint.y, endPoint.y);
			var right = Math.max(startPoint.x, endPoint.x);
			var down = Math.min(startPoint.y, endPoint.y);

			_vecTopLeft.set(left, top, -1);
			_vecTopRight.set(right, top, -1);
			_vecDownRight.set(right, down, -1);
			_vecDownLeft.set(left, down, -1);

			_vecFarTopLeft.set(left, top, 1);
			_vecFarTopRight.set(right, top, 1);
			_vecFarDownRight.set(right, down, 1);
			_vecFarDownLeft.set(left, down, 1);

			_vecTopLeft.unproject(this.camera);
			_vecTopRight.unproject(this.camera);
			_vecDownRight.unproject(this.camera);
			_vecDownLeft.unproject(this.camera);

			_vecFarTopLeft.unproject(this.camera);
			_vecFarTopRight.unproject(this.camera);
			_vecFarDownRight.unproject(this.camera);
			_vecFarDownLeft.unproject(this.camera);

			var planes = _frustum.planes;

			planes[0].setFromCoplanarPoints(_vecTopLeft, _vecFarTopLeft, _vecFarTopRight);
			planes[1].setFromCoplanarPoints(_vecTopRight, _vecFarTopRight, _vecFarDownRight);
			planes[2].setFromCoplanarPoints(_vecFarDownRight, _vecFarDownLeft, _vecDownLeft);
			planes[3].setFromCoplanarPoints(_vecFarDownLeft, _vecFarTopLeft, _vecTopLeft);
			planes[4].setFromCoplanarPoints(_vecTopRight, _vecDownRight, _vecDownLeft);
			planes[5].setFromCoplanarPoints(_vecFarDownRight, _vecFarTopRight, _vecFarTopLeft);
			planes[5].normal.multiplyScalar(-1);

		} else {
			trace("THREE.SelectionBox: Unsupported camera type.");
		}
	}

	public function searchChildInFrustum(frustum:Frustum, object:three.core.Object3D) {
		if (cast object to three.objects.Mesh || cast object to three.objects.Line || cast object to three.objects.Points) {
			if (cast object to three.objects.InstancedMesh) {
				this.instances[object.uuid] = [];

				for (instanceId in 0...object.count) {
					object.getMatrixAt(instanceId, _matrix);
					_matrix.decompose(_center, _quaternion, _scale);
					_center.applyMatrix4(object.matrixWorld);

					if (frustum.containsPoint(_center)) {
						this.instances[object.uuid].push(instanceId);
					}
				}
			} else {
				if (object.geometry.boundingSphere == null) object.geometry.computeBoundingSphere();
				_center.copy(object.geometry.boundingSphere.center);
				_center.applyMatrix4(object.matrixWorld);

				if (frustum.containsPoint(_center)) {
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