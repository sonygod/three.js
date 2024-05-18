package renderers.webgl;

import haxe.ds.WeakMap;
import three.extras.PMREMGenerator;

class WebGLCubeUVMaps {
    private var cubeUVmaps:WeakMap<Texture, RenderTarget>;
    private var pmremGenerator:PMREMGenerator;

    public function new(renderer:Renderer) {
        cubeUVmaps = new WeakMap();
        pmremGenerator = null;
    }

    public function get(texture:Texture):Texture {
        if (texture != null && texture.isTexture) {
            var mapping = texture.mapping;
            var isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
            var isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

            if (isEquirectMap || isCubeMap) {
                var renderTarget = cubeUVmaps.get(texture);
                var currentPMREMVersion = (renderTarget != null) ? renderTarget.texture.pmremVersion : 0;

                if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
                    if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
                    renderTarget = (isEquirectMap) ? pmremGenerator.fromEquirectangular(texture, renderTarget) : pmremGenerator.fromCubemap(texture, renderTarget);
                    renderTarget.texture.pmremVersion = texture.pmremVersion;
                    cubeUVmaps.set(texture, renderTarget);
                    return renderTarget.texture;
                } else {
                    if (renderTarget != null) {
                        return renderTarget.texture;
                    } else {
                        var image = texture.image;
                        if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
                            if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);
                            renderTarget = (isEquirectMap) ? pmremGenerator.fromEquirectangular(texture) : pmremGenerator.fromCubemap(texture);
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

    private function isCubeTextureComplete(image:Array<Dynamic>):Bool {
        var count = 0;
        var length = 6;
        for (i in 0...length) {
            if (image[i] != null) count++;
        }
        return count == length;
    }

    private function onTextureDispose(event:Event):Void {
        var texture = cast(event.target, Texture);
        texture.removeEventListener('dispose', onTextureDispose);
        var cubemapUV = cubeUVmaps.get(texture);
        if (cubemapUV != null) {
            cubeUVmaps.remove(texture);
            cubemapUV.dispose();
        }
    }

    public function dispose():Void {
        cubeUVmaps = new WeakMap();
        if (pmremGenerator != null) {
            pmremGenerator.dispose();
            pmremGenerator = null;
        }
    }
}