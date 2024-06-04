import webgpu.WebGPUConstants;
import webgpu.WebGPURenderer;
import webgpu.WebGPUBackend;
import webgpu.WebGPURenderContext;
import three.Object3D;
import three.Material;

class WebGPUUtils {

	public var backend:WebGPUBackend;

	public function new(backend:WebGPUBackend) {
		this.backend = backend;
	}

	public function getCurrentDepthStencilFormat(renderContext:WebGPURenderContext):WebGPUConstants.GPUTextureFormat {
		var format:WebGPUConstants.GPUTextureFormat;
		if (renderContext.depthTexture != null) {
			format = getTextureFormatGPU(renderContext.depthTexture);
		} else if (renderContext.depth && renderContext.stencil) {
			format = WebGPUConstants.GPUTextureFormat.Depth24PlusStencil8;
		} else if (renderContext.depth) {
			format = WebGPUConstants.GPUTextureFormat.Depth24Plus;
		}
		return format;
	}

	public function getTextureFormatGPU(texture:Dynamic):WebGPUConstants.GPUTextureFormat {
		return backend.get(texture).texture.format;
	}

	public function getCurrentColorFormat(renderContext:WebGPURenderContext):WebGPUConstants.GPUTextureFormat {
		var format:WebGPUConstants.GPUTextureFormat;
		if (renderContext.textures != null) {
			format = getTextureFormatGPU(renderContext.textures[0]);
		} else {
			format = WebGPUConstants.GPUTextureFormat.BGRA8Unorm; // default context format
		}
		return format;
	}

	public function getCurrentColorSpace(renderContext:WebGPURenderContext):String {
		if (renderContext.textures != null) {
			return renderContext.textures[0].colorSpace;
		}
		return backend.renderer.outputColorSpace;
	}

	public function getPrimitiveTopology(object:Object3D, material:Material):WebGPUConstants.GPUPrimitiveTopology {
		if (object.isPoints) return WebGPUConstants.GPUPrimitiveTopology.PointList;
		else if (object.isLineSegments || (object.isMesh && material.wireframe == true)) return WebGPUConstants.GPUPrimitiveTopology.LineList;
		else if (object.isLine) return WebGPUConstants.GPUPrimitiveTopology.LineStrip;
		else if (object.isMesh) return WebGPUConstants.GPUPrimitiveTopology.TriangleList;
		return null;
	}

	public function getSampleCount(renderContext:WebGPURenderContext):Int {
		if (renderContext.textures != null) {
			return renderContext.sampleCount;
		}
		return backend.parameters.sampleCount;
	}

}