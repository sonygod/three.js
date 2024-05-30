package three.renderers.webgl;

import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.extras.PMREMGenerator;

class WebGLCubeUVMaps {
  private var cubeUVmaps:WeakMap<Texture, Dynamic>;
  private var pmremGenerator:PMREMGenerator;

  public function new(renderer:Renderer) {
    cubeUVmaps = new WeakMap<Texture, Dynamic>();
    pmremGenerator = null;
  }

  public function get(texture:Texture):Texture {
    if (texture != null && texture.isTexture) {
      var mapping:Int = texture.mapping;
      var isEquirectMap:Bool = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
      var isCubeMap:Bool = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

      if (isEquirectMap || isCubeMap) {
        var renderTarget = cubeUVmaps.get(texture);
        var currentPMREMVersion:Int = renderTarget != null ? renderTarget.texture.pmremVersion : 0;

        if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
          if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
          renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture, renderTarget) : pmremGenerator.fromCubemap(texture, renderTarget);
          renderTarget.texture.pmremVersion = texture.pmremVersion;
          cubeUVmaps.set(texture, renderTarget);
          return renderTarget.texture;
        } else {
          if (renderTarget != null) {
            return renderTarget.texture;
          } else {
            var image:Image = texture.image;
            if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
              if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
              renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture) : pmremGenerator.fromCubemap(texture);
              renderTarget.texture.pmremVersion = texture.pmremVersion;
              cubeUVmaps.set(texture, renderTarget);
              texture.addEventListener('dispose', onTextureDispose);
              return renderTarget.texture;
            } else {
              return null;
            }
          }
        }
      }
    }
    return texture;
  }

  private function isCubeTextureComplete(image:Image):Bool {
    var count:Int = 0;
    var length:Int = 6;

    for (i in 0...length) {
      if (image[i] != null) count++;
    }

    return count == length;
  }

  private function onTextureDispose(event:Event<Texture>) {
    var texture:Texture = event.target;
    texture.removeEventListener('dispose', onTextureDispose);
    var cubemapUV:Dynamic = cubeUVmaps.get(texture);
    if (cubemapUV != null) {
      cubeUVmaps.delete(texture);
      cubemapUV.dispose();
    }
  }

  public function dispose() {
    cubeUVmaps = new WeakMap<Texture, Dynamic>();
    if (pmremGenerator != null) {
      pmremGenerator.dispose();
      pmremGenerator = null;
    }
  }
}

#else
extern class WebGLCubeUVMaps {}
#end