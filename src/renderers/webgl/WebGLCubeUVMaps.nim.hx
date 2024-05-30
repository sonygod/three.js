import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.extras.PMREMGenerator;

class WebGLCubeUVMaps {
    private var cubeUVmaps:Map<Texture, RenderTarget>;
    private var pmremGenerator:PMREMGenerator;

    public function new(renderer:WebGLRenderer) {
        cubeUVmaps = new Map<Texture, RenderTarget>();
        pmremGenerator = null;
    }

    public function get(texture:Texture):Texture {
        if (texture != null && texture.isTexture) {
            var mapping:Int = texture.mapping;
            var isEquirectMap:Bool = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
            var isCubeMap:Bool = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

            if (isEquirectMap || isCubeMap) {
                var renderTarget:RenderTarget = cubeUVmaps.get(texture);
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
                        var image:Dynamic = texture.image;

                        if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
                            if (pmremGenerator == null) pmremGenerator = new PMREMGenerator(renderer);

                            renderTarget = isEquirectMap ? pmremGenerator.fromEquirectangular(texture) : pmremGenerator.fromCubemap(texture);
                            renderTarget.texture.pmremVersion = texture.pmremVersion;

                            cubeUVmaps.set(texture, renderTarget);

                            texture.addEventListener(Event.DISPOSE, onTextureDispose);

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

    private function isCubeTextureComplete(image:Dynamic):Bool {
        var count:Int = 0;
        var length:Int = 6;

        for (i in 0...length) {
            if (image[i] != null) count++;
        }

        return count == length;
    }

    private function onTextureDispose(event:Event):Void {
        var texture:Texture = event.target;

        texture.removeEventListener(Event.DISPOSE, onTextureDispose);

        var cubemapUV:RenderTarget = cubeUVmaps.get(texture);

        if (cubemapUV != null) {
            cubeUVmaps.remove(texture);
            cubemapUV.dispose();
        }
    }

    public function dispose():Void {
        cubeUVmaps = new Map<Texture, RenderTarget>();

        if (pmremGenerator != null) {
            pmremGenerator.dispose();
            pmremGenerator = null;
        }
    }
}