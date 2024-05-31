import three.constants.WebGLCoordinateSystem;
import three.constants.WebGPUCoordinateSystem;
import three.core.Object3D;
import three.cameras.PerspectiveCamera;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.textures.CubeTexture;

class CubeCamera extends Object3D {

	public var renderTarget:CubeTexture;
	public var coordinateSystem:Null<Int>;
	public var activeMipmapLevel:Int;

	public function new(near:Float, far:Float, renderTarget:CubeTexture) {
		super();
		this.type = "CubeCamera";
		this.renderTarget = renderTarget;
		this.coordinateSystem = null;
		this.activeMipmapLevel = 0;

		var cameraPX = new PerspectiveCamera(-90, 1, near, far);
		cameraPX.layers = this.layers;
		this.add(cameraPX);

		var cameraNX = new PerspectiveCamera(-90, 1, near, far);
		cameraNX.layers = this.layers;
		this.add(cameraNX);

		var cameraPY = new PerspectiveCamera(-90, 1, near, far);
		cameraPY.layers = this.layers;
		this.add(cameraPY);

		var cameraNY = new PerspectiveCamera(-90, 1, near, far);
		cameraNY.layers = this.layers;
		this.add(cameraNY);

		var cameraPZ = new PerspectiveCamera(-90, 1, near, far);
		cameraPZ.layers = this.layers;
		this.add(cameraPZ);

		var cameraNZ = new PerspectiveCamera(-90, 1, near, far);
		cameraNZ.layers = this.layers;
		this.add(cameraNZ);
	}

	public function updateCoordinateSystem() {
		var coordinateSystem = this.coordinateSystem;
		var cameras = this.children.copy();
		var [cameraPX, cameraNX, cameraPY, cameraNY, cameraPZ, cameraNZ] = cameras;

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

	public function update(renderer:WebGLRenderer, scene:Scene) {
		if (this.parent == null) this.updateMatrixWorld();

		var {renderTarget, activeMipmapLevel} = this;

		if (this.coordinateSystem != renderer.coordinateSystem) {
			this.coordinateSystem = renderer.coordinateSystem;
			this.updateCoordinateSystem();
		}

		var [cameraPX, cameraNX, cameraPY, cameraNY, cameraPZ, cameraNZ] = this.children;

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

		// mipmaps are generated during the last call of render()
		// at this point, all sides of the cube render target are defined

		renderTarget.texture.generateMipmaps = generateMipmaps;

		renderer.setRenderTarget(renderTarget, 5, activeMipmapLevel);
		renderer.render(scene, cameraNZ);

		renderer.setRenderTarget(currentRenderTarget, currentActiveCubeFace, currentActiveMipmapLevel);

		renderer.xr.enabled = currentXrEnabled;

		renderTarget.texture.needsPMREMUpdate = true;
	}
}