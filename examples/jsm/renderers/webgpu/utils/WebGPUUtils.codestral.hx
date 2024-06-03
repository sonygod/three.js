import WebGPUConstants.GPUPrimitiveTopology;
import WebGPUConstants.GPUTextureFormat;

class WebGPUUtils {

    public var backend: dynamic;

    public function new(backend: dynamic) {
        this.backend = backend;
    }

    public function getCurrentDepthStencilFormat(renderContext: dynamic): Int {
        var format: Int;

        if (renderContext.depthTexture !== null) {
            format = this.getTextureFormatGPU(renderContext.depthTexture);
        } else if (renderContext.depth && renderContext.stencil) {
            format = GPUTextureFormat.Depth24PlusStencil8;
        } else if (renderContext.depth) {
            format = GPUTextureFormat.Depth24Plus;
        }

        return format;
    }

    public function getTextureFormatGPU(texture: dynamic): Int {
        return this.backend.get(texture).texture.format;
    }

    public function getCurrentColorFormat(renderContext: dynamic): Int {
        var format: Int;

        if (renderContext.textures !== null) {
            format = this.getTextureFormatGPU(renderContext.textures[0]);
        } else {
            format = GPUTextureFormat.BGRA8Unorm; // default context format
        }

        return format;
    }

    public function getCurrentColorSpace(renderContext: dynamic): String {
        if (renderContext.textures !== null) {
            return renderContext.textures[0].colorSpace;
        }

        return this.backend.renderer.outputColorSpace;
    }

    public function getPrimitiveTopology(object: dynamic, material: dynamic): Int {
        if (Std.is(object, js.html.Point)) return GPUPrimitiveTopology.PointList;
        else if (Std.is(object, js.html.LineSegments) || (Std.is(object, js.html.Mesh) && material.wireframe === true)) return GPUPrimitiveTopology.LineList;
        else if (Std.is(object, js.html.Line)) return GPUPrimitiveTopology.LineStrip;
        else if (Std.is(object, js.html.Mesh)) return GPUPrimitiveTopology.TriangleList;

        return null;
    }

    public function getSampleCount(renderContext: dynamic): Int {
        if (renderContext.textures !== null) {
            return renderContext.sampleCount;
        }

        return this.backend.parameters.sampleCount;
    }
}