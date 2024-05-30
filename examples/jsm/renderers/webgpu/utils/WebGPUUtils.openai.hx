package three.js.examples.jm.renderers.webgpu.utils;

import WebGPUConstants;

class WebGPUUtils {
  public var backend:Backend;

  public function new(backend:Backend) {
    this.backend = backend;
  }

  public function getCurrentDepthStencilFormat(renderContext:RenderContext):GPUTextureFormat {
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

  public function getTextureFormatGPU(texture:Texture):GPUTextureFormat {
    return backend.get(texture).texture.format;
  }

  public function getCurrentColorFormat(renderContext:RenderContext):GPUTextureFormat {
    var format:GPUTextureFormat;

    if (renderContext.textures != null) {
      format = getTextureFormatGPU(renderContext.textures[0]);
    } else {
      format = GPUTextureFormat.BGRA8Unorm; // default context format
    }

    return format;
  }

  public function getCurrentColorSpace(renderContext:RenderContext):ColorSpace {
    if (renderContext.textures != null) {
      return renderContext.textures[0].colorSpace;
    }

    return backend.renderer.outputColorSpace;
  }

  public function getPrimitiveTopology(object:Object, material:Material):GPUPrimitiveTopology {
    if (object.isPoints) return GPUPrimitiveTopology.PointList;
    else if (object.isLineSegments || (object.isMesh && material.wireframe == true)) return GPUPrimitiveTopology.LineList;
    else if (object.isLine) return GPUPrimitiveTopology.LineStrip;
    else if (object.isMesh) return GPUPrimitiveTopology.TriangleList;

    return null;
  }

  public function getSampleCount(renderContext:RenderContext):Int {
    if (renderContext.textures != null) {
      return renderContext.sampleCount;
    }

    return backend.parameters.sampleCount;
  }
}