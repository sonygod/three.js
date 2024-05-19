import threejs.lights.LightShadow;
import threejs.cameras.PerspectiveCamera;
import threejs.math.Matrix4;
import threejs.math.Vector2;
import threejs.math.Vector3;
import threejs.math.Vector4;

class PointLightShadow extends LightShadow {

	var _projScreenMatrix:Matrix4 = new Matrix4();
	var _lightPositionWorld:Vector3 = new Vector3();
	var _lookTarget:Vector3 = new Vector3();

	public function new() {

		super(new PerspectiveCamera( 90, 1, 0.5, 500 ));

		this.isPointLightShadow = true;

		this._frameExtents = new Vector2( 4, 2 );

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
			new Vector4( 2, 1, 1, 1 ),
			// negative X
			new Vector4( 0, 1, 1, 1 ),
			// positive Z
			new Vector4( 3, 1, 1, 1 ),
			// negative Z
			new Vector4( 1, 1, 1, 1 ),
			// positive Y
			new Vector4( 3, 0, 1, 1 ),
			// negative Y
			new Vector4( 1, 0, 1, 1 )
		];

		this._cubeDirections = [
			new Vector3( 1, 0, 0 ), new Vector3( - 1, 0, 0 ), new Vector3( 0, 0, 1 ),
			new Vector3( 0, 0, - 1 ), new Vector3( 0, 1, 0 ), new Vector3( 0, - 1, 0 )
		];

		this._cubeUps = [
			new Vector3( 0, 1, 0 ), new Vector3( 0, 1, 0 ), new Vector3( 0, 1, 0 ),
			new Vector3( 0, 1, 0 ), new Vector3( 0, 0, 1 ), new Vector3( 0, 0, - 1 )
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

		_lightPositionWorld.setFromMatrixPosition(light.matrixWorld);
		camera.position.copy(_lightPositionWorld);

		_lookTarget.copy(camera.position);
		_lookTarget.add(this._cubeDirections[viewportIndex]);
		camera.up.copy(this._cubeUps[viewportIndex]);
		camera.lookAt(_lookTarget);
		camera.updateMatrixWorld();

		shadowMatrix.makeTranslation(-_lightPositionWorld.x, -_lightPositionWorld.y, -_lightPositionWorld.z);

		_projScreenMatrix.multiplyMatrices(camera.projectionMatrix, camera.matrixWorldInverse);
		this._frustum.setFromProjectionMatrix(_projScreenMatrix);

	}

}