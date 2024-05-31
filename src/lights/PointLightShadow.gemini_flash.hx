import three.lights.LightShadow;
import three.cameras.PerspectiveCamera;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class PointLightShadow extends LightShadow {

	public var isPointLightShadow:Bool = true;

	public var _frameExtents:Vector2;
	public var _viewportCount:Int = 6;

	public var _viewports:Array<Vector4>;

	public var _cubeDirections:Array<Vector3>;
	public var _cubeUps:Array<Vector3>;

	public function new() {
		super(new PerspectiveCamera(90, 1, 0.5, 500));

		_frameExtents = new Vector2(4, 2);

		_viewports = [
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

		_cubeDirections = [
			new Vector3(1, 0, 0), new Vector3(-1, 0, 0), new Vector3(0, 0, 1),
			new Vector3(0, 0, -1), new Vector3(0, 1, 0), new Vector3(0, -1, 0)
		];

		_cubeUps = [
			new Vector3(0, 1, 0), new Vector3(0, 1, 0), new Vector3(0, 1, 0),
			new Vector3(0, 1, 0), new Vector3(0, 0, 1), new Vector3(0, 0, -1)
		];
	}

	public function updateMatrices(light:Dynamic, viewportIndex:Int = 0) {

		var camera = this.camera;
		var shadowMatrix = this.matrix;

		var far = light.distance != null ? light.distance : camera.far;

		if (far != camera.far) {
			camera.far = far;
			camera.updateProjectionMatrix();
		}

		var _lightPositionWorld:Vector3 = new Vector3();
		_lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
		camera.position.copy(_lightPositionWorld);

		var _lookTarget:Vector3 = new Vector3();
		_lookTarget.copy(camera.position);
		_lookTarget.add(this._cubeDirections[viewportIndex]);
		camera.up.copy(this._cubeUps[viewportIndex]);
		camera.lookAt(_lookTarget);
		camera.updateMatrixWorld();

		shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);

		var _projScreenMatrix:Matrix4 = new Matrix4();
		_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
		this._frustum.setFromProjectionMatrix(_projScreenMatrix);
	}
}