import LightShadow from "./LightShadow";
import PerspectiveCamera from "../cameras/PerspectiveCamera";
import Matrix4 from "../math/Matrix4";
import Vector2 from "../math/Vector2";
import Vector3 from "../math/Vector3";
import Vector4 from "../math/Vector4";

class PointLightShadow extends LightShadow {
	public var isPointLightShadow:Bool = true;
	private var _frameExtents:Vector2;
	private var _viewportCount:Int;
	private var _viewports:Array<Vector4>;
	private var _cubeDirections:Array<Vector3>;
	private var _cubeUps:Array<Vector3>;

	public function new() {
		super(new PerspectiveCamera(90, 1, 0.5, 500));
		this._frameExtents = new Vector2(4, 2);
		this._viewportCount = 6;
		this._viewports = [
			// These viewports map a cube-map onto a 2D texture with the
			// following orientation:
			//
			//  xzXZ
			//   y Y
			//
			// X - Positive x direction
			// x - Negative x direction
			// Y - Positive y direction
			// y - Negative y direction
			// Z - Positive z direction
			// z - Negative z direction

			// positive X
			new Vector4(2, 1, 1, 1),
			// negative X
			new Vector4(0, 1, 1, 1),
			// positive Z
			new Vector4(3, 1, 1, 1),
			// negative Z
			new Vector4(1, 1, 1, 1),
			// positive Y
			new Vector4(3, 0, 1, 1),
			// negative Y
			new Vector4(1, 0, 1, 1)
		];
		this._cubeDirections = [
			new Vector3(1, 0, 0), new Vector3(-1, 0, 0), new Vector3(0, 0, 1),
			new Vector3(0, 0, -1), new Vector3(0, 1, 0), new Vector3(0, -1, 0)
		];
		this._cubeUps = [
			new Vector3(0, 1, 0), new Vector3(0, 1, 0), new Vector3(0, 1, 0),
			new Vector3(0, 1, 0), new Vector3(0, 0, 1), new Vector3(0, 0, -1)
		];
	}

	public function updateMatrices(light:Dynamic, viewportIndex:Int = 0):Void {
		var camera = this.camera;
		var shadowMatrix = this.matrix;
		var far = light.distance != null ? light.distance : camera.far;
		if (far != camera.far) {
			camera.far = far;
			camera.updateProjectionMatrix();
		}
		var _lightPositionWorld = new Vector3();
		_lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
		camera.position.copy(_lightPositionWorld);
		var _lookTarget = new Vector3();
		_lookTarget.copy(camera.position);
		_lookTarget.add(this._cubeDirections[viewportIndex]);
		camera.up.copy(this._cubeUps[viewportIndex]);
		camera.lookAt(_lookTarget);
		camera.updateMatrixWorld();
		shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);
		var _projScreenMatrix = new Matrix4();
		_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
		this._frustum.setFromProjectionMatrix(_projScreenMatrix);
	}
}

export default PointLightShadow;