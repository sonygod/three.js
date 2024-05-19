package three.cameras;

import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.core.Object3D;

class CubeCamera extends Object3D {

	var fov: Float = -90;
	var aspect: Float = 1;

	var renderTarget: Dynamic;
	var coordinateSystem: Dynamic = null;
	var activeMipmapLevel: Int = 0;

	public function new(near: Float, far: Float, renderTarget: Dynamic) {
		super();
		
		this.type = "CubeCamera";
		this.renderTarget = renderTarget;
		this.coordinateSystem = null;
		this.activeMipmapLevel = 0;

		var cameraPX = new PerspectiveCamera(fov, aspect, near, far);
		cameraPX.layers = this.layers;
		this.add(cameraPX);

		var cameraNX = new PerspectiveCamera(fov, aspect, near, far);
		cameraNX.layers = this.layers;
		this.add(cameraNX);

		var cameraPY = new PerspectiveCamera(fov, aspect, near, far);
		cameraPY.layers = this.layers;
		this.add(cameraPY);

		var cameraNY = new PerspectiveCamera(fov, aspect, near, far);
		cameraNY.layers = this.layers;
		this.add(cameraNY);

		var cameraPZ = new PerspectiveCamera(fov, aspect, near, far);
		cameraPZ.layers = this.layers;
		this.add(cameraPZ);

		var cameraNZ = new PerspectiveCamera(fov, aspect, near, far);
		cameraNZ.layers = this.layers;
		this.add(cameraNZ);
	}

	public function updateCoordinateSystem(): Void {
		var coordinateSystem = this.coordinateSystem;

		var cameras = this.children.concat();

		var cameraPX = cameras[0];
		var cameraNX = cameras[1];
		var cameraPY = cameras[2];
		var cameraNY = cameras[3];
		var cameraPZ = cameras[4];
		var cameraNZ = cameras[5];

		for (camera in cameras) this.remove(camera);

		if (coordinateSystem == WebGLCoordinateSystem) {
			cameraPX.up.set(0, 1, 0);
			cameraPX.lookAt(1, 0, 0);

			cameraNX.up.set(0, 1, 0);
			cameraNX.lookAt(-1, 0, 0);

			cameraPY.up.set(0, 0, -1);
			cameraPY.lookAt(0, 1, 0);

			cameraNY.up.set(0, 0, 1);
			cameraNY.lookAt(0, -1, 0);

			cameraPZ.up.set(0, 1, 0);
			cameraPZ.lookAt(0, 0, 1);

			cameraNZ.up.set(0, 1, 0);
			cameraNZ.lookAt(0, 0, -1);
		} else if (coordinateSystem == WebGPUCoordinateSystem) {
			cameraPX.up.set(0, -1, 0);
			cameraPX.lookAt(-1, 0, 0);

			cameraNX.up.set(0, -1, 0);
			cameraNX.lookAt(1, 0, 0);

			cameraPY.up.set(0, 0, 1);
			cameraPY.lookAt(0, 1, 0);

			cameraNY.up.set(0, 0, -1);
			cameraNY.lookAt(0, -1, 0);

			cameraPZ.up.set(0, -1, 0);
			cameraPZ.lookAt(0, 0, 1);

			cameraNZ.up.set(0, -1, 0);
			cameraNZ.lookAt(0, 0, -1);
		} else {
			throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: " + coordinateSystem);
		}

		for (camera in cameras) {
			this.add(camera);
			camera.updateMatrixWorld();
		}
	}

	public function update(renderer: Dynamic, scene: Dynamic): Void {
		if (this.parent == null) this.updateMatrixWorld();

		var renderTarget = this.renderTarget;
		var activeMipmapLevel = this.activeMipmapLevel;

		if (this.coordinateSystem != renderer.coordinateSystem) {
			this.coordinateSystem = renderer.coordinateSystem;
			this.updateCoordinateSystem();
		}

		var cameraPX = this.children[0];
		var cameraNX = this.children[1];
		var cameraPY = this.children[2];
		var cameraNY = this.children[3];
		var cameraPZ = this.children[4];
		var cameraNZ = this.children[5];

		var currentRenderTarget = renderer.getRenderTarget();
		var currentActiveCubeFace = renderer.getActiveCubeFace();
		var currentActiveMipmapLevel = renderer.getActiveMipmapLevel();

		var currentXrEnabled = renderer.xr.enabled;
		renderer.xr.enabled = false;

		var generateMipmaps = renderTarget.texture.generateMipmaps;
		renderTarget.texture.generateMipmaps = false;

		renderer.setRenderTarget(renderTarget, 0, activeMipmapLevel);
		renderer.render(scene, cameraPX);

		renderer.setRenderTarget(renderTarget, 1, activeMipmapLevel);
		renderer.render(scene, cameraNX);

		renderer.setRenderTarget(renderTarget, 2, activeMipmapLevel);
		renderer.render(scene, cameraPY);

		renderer.setRenderTarget(renderTarget, 3, activeMipmapLevel);
		renderer.render(scene, cameraNY);

		renderer.setRenderTarget(renderTarget, 4, activeMipmapLevel);
		renderer.render(scene, cameraPZ);

		renderTarget.texture.generateMipmaps = generateMipmaps;

		renderer.setRenderTarget(renderTarget, 5, activeMipmapLevel);
		renderer.render(scene, cameraNZ);

		renderer.setRenderTarget(currentRenderTarget, currentActiveCubeFace, currentActiveMipmapLevel);
		renderer.xr.enabled = currentXrEnabled;

		renderTarget.texture.needsPMREMUpdate = true;
	}
}