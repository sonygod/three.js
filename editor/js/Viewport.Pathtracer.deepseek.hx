import three.gpu.pathtracer.WebGLPathTracer;

class ViewportPathtracer {

	var pathTracer:WebGLPathTracer;

	public function new(renderer:Dynamic) {

		pathTracer = null;

	}

	public function init(scene:Dynamic, camera:Dynamic) {

		if (pathTracer == null) {

			pathTracer = new WebGLPathTracer(renderer);
			pathTracer.filterGlossyFactor = 0.5;

		}

		pathTracer.setScene(scene, camera);

	}

	public function setSize(width:Float, height:Float) {

		if (pathTracer == null) return;

		pathTracer.reset();

	}

	public function setBackground(background:Dynamic, blurriness:Float) {

		if (pathTracer == null) return;

		pathTracer.updateEnvironment();

	}

	public function updateMaterials() {

		if (pathTracer == null) return;

		pathTracer.updateMaterials();

	}

	public function setEnvironment(environment:Dynamic) {

		if (pathTracer == null) return;

		pathTracer.updateEnvironment();

	}

	public function update() {

		if (pathTracer == null) return;

		pathTracer.renderSample();

	}

	public function reset() {

		if (pathTracer == null) return;

		pathTracer.updateCamera();

	}

}