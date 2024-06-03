import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.extras.PMREMGenerator;

class WebGLCubeUVMaps {

    private var cubeUVmaps:Map<Texture,RenderTarget>;
    private var pmremGenerator:PMREMGenerator;
    private var renderer:WebGLRenderer;

    public function new(renderer:WebGLRenderer) {
        this.renderer = renderer;
        this.cubeUVmaps = new haxe.ds.WeakMap();
        this.pmremGenerator = null;
    }

    public function get(texture:Texture):Texture {
        if (texture != null && texture.isTexture) {
            var mapping = texture.mapping;
            var isEquirectMap = (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping);
            var isCubeMap = (mapping == CubeReflectionMapping || mapping == CubeRefractionMapping);

            if (isEquirectMap || isCubeMap) {
                var renderTarget = this.cubeUVmaps.get(texture);
                var currentPMREMVersion = renderTarget != null ? renderTarget.texture.pmremVersion : 0;

                if (texture.isRenderTargetTexture && texture.pmremVersion != currentPMREMVersion) {
                    if (this.pmremGenerator == null) this.pmremGenerator = new PMREMGenerator(this.renderer);
                    renderTarget = isEquirectMap ? this.pmremGenerator.fromEquirectangular(texture, renderTarget) : this.pmremGenerator.fromCubemap(texture, renderTarget);
                    renderTarget.texture.pmremVersion = texture.pmremVersion;
                    this.cubeUVmaps.set(texture, renderTarget);
                    return renderTarget.texture;
                } else {
                    if (renderTarget != null) {
                        return renderTarget.texture;
                    } else {
                        var image = texture.image;
                        if ((isEquirectMap && image != null && image.height > 0) || (isCubeMap && image != null && isCubeTextureComplete(image))) {
                            if (this.pmremGenerator == null) this.pmremGenerator = new PMREMGenerator(this.renderer);
                            renderTarget = isEquirectMap ? this.pmremGenerator.fromEquirectangular(texture) : this.pmremGenerator.fromCubemap(texture);
                            renderTarget.texture.pmremVersion = texture.pmremVersion;
                            this.cubeUVmaps.set(texture, renderTarget);
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

    private function isCubeTextureComplete(image:Array<any>):Bool {
        var count = 0;
        var length = 6;
        for (var i in 0...length) {
            if (image[i] != null) count ++;
        }
        return count == length;
    }

    private function onTextureDispose(event:Event):Void {
        var texture = js.Boot.cast<Texture>(event.target);
        texture.removeEventListener('dispose', onTextureDispose);
        var cubemapUV = this.cubeUVmaps.get(texture);
        if (cubemapUV != null) {
            this.cubeUVmaps.remove(texture);
            cubemapUV.dispose();
        }
    }

    public function dispose():Void {
        this.cubeUVmaps = new haxe.ds.WeakMap();
        if (this.pmremGenerator != null) {
            this.pmremGenerator.dispose();
            this.pmremGenerator = null;
        }
    }
}