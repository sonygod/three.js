package three.js.examples.jm.renderers.webgpu.utils;

import WebGPUConstants.*;

class WebGPUUtils {

    public var backend:Dynamic;

    public function new(backend:Dynamic) {
        this.backend = backend;
    }

    public function getCurrentDepthStencilFormat(renderContext:Dynamic):GPUTextureFormat {
        var format:GPUTextureFormat;

        if (renderContext.depthTexture != null) {
            format = getTextureFormatGPU(renderContext.depthTexture);
        } else if (renderContext.depth && renderContext.stencil) {
            format = GPUTextureFormat.Depth24PlusStencil8;
        } else if (renderContext.depth) {
            format = GPUTextureFormat.Depth24Plus;
        }

        return format;
    }

    public function getTextureFormatGPU(texture:Dynamic):GPUTextureFormat {
        return backend.get(texture).texture.format;
    }

    public function getCurrentColorFormat(renderContext:Dynamic):GPUTextureFormat {
        var format:GPUTextureFormat;

        if (renderContext.textures != null) {
            format = getTextureFormatGPU(renderContext.textures[0]);
        } else {
            format = GPUTextureFormat.BGRA8Unorm; // default context format
        }

        return format;
    }

    public function getCurrentColorSpace(renderContext:Dynamic):String {
        if (renderContext.textures != null) {
            return renderContext.textures[0].colorSpace;
        }

        return backend.renderer.outputColorSpace;
    }

    public function getPrimitiveTopology(object:Dynamic, material:Dynamic):GPUPrimitiveTopology {
        if (object.isPoints) return GPUPrimitiveTopology.PointList;
        else if (object.isLineSegments || (object.isMesh && material.wireframe == true)) return GPUPrimitiveTopology.LineList;
        else if (object.isLine) return GPUPrimitiveTopology.LineStrip;
        else if (object.isMesh) return GPUPrimitiveTopology.TriangleList;
    }

    public function getSampleCount(renderContext:Dynamic):Int {
        if (renderContext.textures != null) {
            return renderContext.sampleCount;
        }

        return backend.parameters.sampleCount;
    }
}