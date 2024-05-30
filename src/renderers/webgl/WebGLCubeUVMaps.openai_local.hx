import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.extras.PMREMGenerator;
import three.renderers.WebGLRenderer;
import three.textures.Texture;
import haxe.ds.WeakMap;

class WebGLCubeUVMaps {
    private var cubeUVmaps:WeakMap<Texture, Dynamic>;
    private var pmremGenerator:PMREMGenerator;

    public function new(renderer:WebGLRenderer) {
        cubeUVmaps = new WeakMap<Texture, Dynamic>();
        pmremGenerator = null;
    }

    public function get(texture:Texture):Dynamic {
        if (texture != null && texture.isTexture) {
            var mapping = texture.mapping;

            var isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
            var isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

            // equirect/cube map to cubeUV conversion
            if (isEquirectMap || isCubeMap) {
                var renderTarget = cubeUVmaps.get(texture);

                var currentPMREMVersion = renderTarget != null ? renderTarget.texture.pmremVersion : 0;

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
                        var image = texture.image;

                        if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
                            if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);

                            renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture) : pmremGenerator.fromCubemap(texture);
                            renderTarget.texture.pmremVersion = texture.pmremVersion;

                            cubeUVmaps.set(texture, renderTarget);

                            texture.addEventListener('dispose', onTextureDispose);

                            return renderTarget.texture;
                        } else {
                            // image not yet ready. try the conversion next frame
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

    private function onTextureDispose(event:Dynamic):Void {
        var texture = event.target;

        texture.removeEventListener('dispose', onTextureDispose);

        var cubemapUV = cubeUVmaps.get(texture);

        if (cubemapUV != null) {
            cubeUVmaps.remove(texture);
            cubemapUV.dispose();
        }
    }

    public function dispose():Void {
        cubeUVmaps = new WeakMap<Texture, Dynamic>();

        if (pmremGenerator != null) {
            pmremGenerator.dispose();
            pmremGenerator = null;
        }
    }
}