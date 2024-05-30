import haxe.ds.StringMap;

class WebGPUUtils {
    public backend:Backend;

    public function new(backend:Backend) {
        this.backend = backend;
    }

    public function getCurrentDepthStencilFormat(renderContext:RenderContext):GPUTextureFormat {
        var format:GPUTextureFormat;
        if (renderContext.depthTexture != null) {
            format = this.getTextureFormatGPU(renderContext.depthTexture);
        } else if (renderContext.depth && renderContext.stencil) {
            format = GPUTextureFormat.Depth24PlusStencil8;
        } else if (renderContext.depth) {
            format = GPUTextureFormat.Depth24Plus;
        }
        return format;
    }

    public function getTextureFormatGPU(texture:Texture):GPUTextureFormat {
        return this.backend.get(texture).texture.format;
    }

    public function getCurrentColorFormat(renderContext:RenderContext):GPUTextureFormat {
        var format:GPUTextureFormat;
        if (renderContext.textures != null) {
            format = this.getTextureFormatGPU(renderContext.textures[0]);
        } else {
            format = GPUTextureFormat.BGRA8Unorm; // default context format
        }
        return format;
    }

    public function getCurrentColorSpace(renderContext:RenderContext):String {
        if (renderContext.textures != null) {
            return renderContext.textures[0].colorSpace;
        }
        return this.backend.renderer.outputColorSpace;
    }

    public function getPrimitiveTopology(object:Object, material:Material):GPUPrimitiveTopology {
        if (object.isPoints) return GPUPrimitiveTopology.PointList;
        else if (object.isLineSegments || (object.isMesh && material.wireframe)) return GPUPrimitiveTopology.LineList;
        else if (object.isLine) return GPUPrimitiveTopology.LineStrip;
        else if (object.isMesh) return GPUPrimitiveTopology.TriangleList;
        return null;
    }

    public function getSampleCount(renderContext:RenderContext):Int {
        if (renderContext.textures != null) {
            return renderContext.sampleCount;
        }
        return this.backend.parameters.sampleCount;
    }
}

type GPUTextureFormat = String;

enum GPUPrimitiveTopology {
    PointList;
    LineList;
    LineStrip;
    TriangleList;
}