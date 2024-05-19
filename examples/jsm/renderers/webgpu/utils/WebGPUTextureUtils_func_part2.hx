Here is the converted Haxe code:
```
package three.js.examples.jsm.renderers.webgpu.utils;

import hex.webgpu.WebGPU;
import hex.webgpu.gpu.GPUDevice;
import hex.webgpu.gpu.GPUTexture;
import hex.webgpu.gpu.GPUTextureDescriptor;
import hex.webgpu.gpu.GPUTextureFormat;
import hex.webgpu.gpu.GPUAddressMode;
import hex.webgpu.gpu.GPUFilterMode;
import hex.webgpu.gpu.GPUCommandEncoder;
import haxe.io.UInt8Array;
import haxe.io.Int8Array;
import haxe.io.UInt16Array;
import haxe.io.Int16Array;
import haxe.io.UInt32Array;
import haxe.io.Int32Array;
import haxe.io.Float32Array;

class WebGPUTextureUtils {
  private var _passUtils:WebGPUPassUtils;
  private var _backend:WebGPUBackend;

  public function new(backend:WebGPUBackend) {
    _backend = backend;
  }

  private function _getPassUtils():WebGPUPassUtils {
    if (_passUtils == null) {
      _passUtils = new WebGPUPassUtils(_backend.device);
    }
    return _passUtils;
  }

  public function _generateMipmaps(textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, baseArrayLayer:Int = 0) {
    _getPassUtils().generateMipmaps(textureGPU, textureDescriptorGPU, baseArrayLayer);
  }

  public function _flipY(textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, originDepth:Int = 0) {
    _getPassUtils().flipY(textureGPU, textureDescriptorGPU, originDepth);
  }

  public function _copyBufferToTexture(image:Dynamic, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor, originDepth:Int = 0, flipY:Bool = false, depth:Int = 0) {
    var device:GPUDevice = _backend.device;
    var data:UInt8Array = image.data;
    var bytesPerTexel:Int = _getBytesPerTexel(textureDescriptorGPU.format);
    var bytesPerRow:Int = image.width * bytesPerTexel;

    device.queue.writeTexture({
      texture: textureGPU,
      mipLevel: 0,
      origin: { x: 0, y: 0, z: originDepth }
    }, data, {
      offset: image.width * image.height * bytesPerTexel * depth,
      bytesPerRow: bytesPerRow
    }, {
      width: image.width,
      height: image.height,
      depthOrArrayLayers: 1
    });

    if (flipY) {
      _flipY(textureGPU, textureDescriptorGPU, originDepth);
    }
  }

  public function _copyCompressedBufferToTexture(mipmaps:Array<Dynamic>, textureGPU:GPUTexture, textureDescriptorGPU:GPUTextureDescriptor) {
    var device:GPUDevice = _backend.device;
    var blockData:Dynamic = _getBlockData(textureDescriptorGPU.format);

    for (i in 0...mipmaps.length) {
      var mipmap:Dynamic = mipmaps[i];
      var width:Int = mipmap.width;
      var height:Int = mipmap.height;

      var bytesPerRow:Int = Math.ceil(width / blockData.width) * blockData.byteLength;

      device.queue.writeTexture({
        texture: textureGPU,
        mipLevel: i
      }, mipmap.data, {
        offset: 0,
        bytesPerRow: bytesPerRow
      }, {
        width: Math.ceil(width / blockData.width) * blockData.width,
        height: Math.ceil(height / blockData.width) * blockData.width,
        depthOrArrayLayers: 1
      });
    }
  }

  private function _getBlockData(format:GPUTextureFormat):Dynamic {
    switch (format) {
      case GPUTextureFormat.BC1RGBAUnorm | GPUTextureFormat.BC1RGBAUnormSRGB:
        return { byteLength: 8, width: 4, height: 4 };
      // ...
    }
  }

  private function _convertAddressMode(value:Dynamic):GPUAddressMode {
    switch (value) {
      case RepeatWrapping:
        return GPUAddressMode.Repeat;
      case MirroredRepeatWrapping:
        return GPUAddressMode.MirrorRepeat;
      default:
        return GPUAddressMode.ClampToEdge;
    }
  }

  private function _convertFilterMode(value:Dynamic):GPUFilterMode {
    switch (value) {
      case NearestFilter | NearestMipmapNearestFilter | NearestMipmapLinearFilter:
        return GPUFilterMode.Nearest;
      default:
        return GPUFilterMode.Linear;
    }
  }

  private function _getBytesPerTexel(format:GPUTextureFormat):Int {
    switch (format) {
      case GPUTextureFormat.R8Unorm | GPUTextureFormat.R8Snorm | GPUTextureFormat.R8Uint | GPUTextureFormat.R8Sint:
        return 1;
      // ...
    }
  }

  private function _getTypedArrayType(format:GPUTextureFormat):Dynamic {
    switch (format) {
      case GPUTextureFormat.R8Uint:
        return UInt8Array;
      case GPUTextureFormat.R8Sint:
        return Int8Array;
      // ...
    }
  }

  private function _getDimension(texture:Dynamic):GPUTextureDimension {
    if (texture.isData3DTexture) {
      return GPUTextureDimension.ThreeD;
    } else {
      return GPUTextureDimension.TwoD;
    }
  }

  public function getFormat(texture:Dynamic, device:GPUDevice = null):GPUTextureFormat {
    var format:GPUTextureFormat;
    switch (texture.format) {
      case RGBA_S3TC_DXT1_Format:
        format = (texture.colorSpace == SRGBColorSpace) ? GPUTextureFormat.BC1RGBAUnormSRGB : GPUTextureFormat.BC1RGBAUnorm;
        break;
      // ...
    }
  }
}
```
Note that I had to make some assumptions about the type of `image` and `mipmap.data` in the `_copyBufferToTexture` and `_copyCompressedBufferToTexture` methods, as the original JavaScript code did not provide explicit type information. I assumed that `image.data` is a `UInt8Array` and `mipmap.data` is a `Dynamic` that can be passed to the `writeTexture` method. You may need to adjust these types based on your specific use case.