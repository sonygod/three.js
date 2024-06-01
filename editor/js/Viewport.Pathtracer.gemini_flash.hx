import three.examples.gpu_pathtracer.WebGLPathTracer;

class ViewportPathtracer {
	var pathTracer:WebGLPathTracer = null;

	public function new(renderer:Dynamic) {
		// Assuming 'renderer' is a compatible object with WebGLPathTracer constructor
		
	}

	public function init(scene:Dynamic, camera:Dynamic):Void {
		if (pathTracer == null) {
			pathTracer = new WebGLPathTracer(renderer);
			pathTracer.filterGlossyFactor = 0.5;
		}

		pathTracer.setScene(scene, camera);
	}

	public function setSize(width:Int = 0, height:Int = 0):Void {
		if (pathTracer == null) return;

		pathTracer.reset(); // Size updates automatically in WebGLPathTracer
	}

	public function setBackground(background:Dynamic = null, blurriness:Float = 0.0):Void {
		if (pathTracer == null) return;

		pathTracer.updateEnvironment(); // Assuming background updates happen within WebGLPathTracer
	}

	public function updateMaterials():Void {
		if (pathTracer == null) return;

		pathTracer.updateMaterials();
	}

	public function setEnvironment(environment:Dynamic = null):Void {
		if (pathTracer == null) return;

		pathTracer.updateEnvironment();
	}

	public function update():Void {
		if (pathTracer == null) return;

		pathTracer.renderSample();
	}

	public function reset():Void {
		if (pathTracer == null) return;

		pathTracer.updateCamera();
	}
}