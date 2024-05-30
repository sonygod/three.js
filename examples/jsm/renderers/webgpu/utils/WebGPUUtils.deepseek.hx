import js.Browser.window;

class WebGPUUtils {

	var backend:Dynamic;

	public function new(backend:Dynamic) {
		this.backend = backend;
	}

	public function getCurrentDepthStencilFormat(renderContext:Dynamic):String {
		var format:String;
		if (renderContext.depthTexture !== null) {
			format = this.getTextureFormatGPU(renderContext.depthTexture);
		} else if (renderContext.depth && renderContext.stencil) {
			format = "Depth24PlusStencil8";
		} else if (renderContext.depth) {
			format = "Depth24Plus";
		}
		return format;
	}

	public function getTextureFormatGPU(texture:Dynamic):String {
		return this.backend.get(texture).texture.format;
	}

	public function getCurrentColorFormat(renderContext:Dynamic):String {
		var format:String;
		if (renderContext.textures !== null) {
			format = this.getTextureFormatGPU(renderContext.textures[0]);
		} else {
			format = "BGRA8Unorm"; // default context format
		}
		return format;
	}

	public function getCurrentColorSpace(renderContext:Dynamic):String {
		if (renderContext.textures !== null) {
			return renderContext.textures[0].colorSpace;
		}
		return this.backend.renderer.outputColorSpace;
	}

	public function getPrimitiveTopology(object:Dynamic, material:Dynamic):String {
		if (object.isPoints) return "PointList";
		else if (object.isLineSegments || (object.isMesh && material.wireframe === true)) return "LineList";
		else if (object.isLine) return "LineStrip";
		else if (object.isMesh) return "TriangleList";
		return "";
	}

	public function getSampleCount(renderContext:Dynamic):Int {
		if (renderContext.textures !== null) {
			return Std.parseInt(renderContext.sampleCount);
		}
		return this.backend.parameters.sampleCount;
	}
}

typedef WebGPUUtilsType = {
	function getCurrentDepthStencilFormat(renderContext:Dynamic):String;
	function getTextureFormatGPU(texture:Dynamic):String;
	function getCurrentColorFormat(renderContext:Dynamic):String;
	function getCurrentColorSpace(renderContext:Dynamic):String;
	function getPrimitiveTopology(object:Dynamic, material:Dynamic):String;
	function getSampleCount(renderContext:Dynamic):Int;
}

@:native("WebGPUUtils")
class WebGPUUtilsNative extends WebGPUUtils {}