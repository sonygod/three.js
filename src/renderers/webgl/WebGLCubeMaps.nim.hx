import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.renderers.webgl.WebGLCubeRenderTarget;

class WebGLCubeMaps {
    private var cubemaps:Map<Texture, WebGLCubeRenderTarget>;

    public function new(renderer:WebGLRenderer) {
        this.cubemaps = new Map<Texture, WebGLCubeRenderTarget>();
    }

    private function mapTextureMapping(texture:Texture, mapping:Int):Texture {
        if (mapping == EquirectangularReflectionMapping) {
            texture.mapping = CubeReflectionMapping;
        } else if (mapping == EquirectangularRefractionMapping) {
            texture.mapping = CubeRefractionMapping;
        }
        return texture;
    }

    public function get(texture:Texture):Texture {
        if (texture != null && texture.isTexture) {
            var mapping:Int = texture.mapping;
            if (mapping == EquirectangularReflectionMapping || mapping == EquirectangularRefractionMapping) {
                if (this.cubemaps.exists(texture)) {
                    var cubemap:WebGLCubeRenderTarget = this.cubemaps.get(texture);
                    return mapTextureMapping(cubemap.texture, texture.mapping);
                } else {
                    var image:Image = texture.image;
                    if (image != null && image.height > 0) {
                        var renderTarget:WebGLCubeRenderTarget = new WebGLCubeRenderTarget(image.height);
                        renderTarget.fromEquirectangularTexture(renderer, texture);
                        this.cubemaps.set(texture, renderTarget);
                        texture.addEventListener(Event.DISPOSE, onTextureDispose);
                        return mapTextureMapping(renderTarget.texture, texture.mapping);
                    } else {
                        // image not yet ready. try the conversion next frame
                        return null;
                    }
                }
            }
        }
        return texture;
    }

    private function onTextureDispose(event:Event):Void {
        var texture:Texture = cast event.target;
        texture.removeEventListener(Event.DISPOSE, onTextureDispose);
        var cubemap:WebGLCubeRenderTarget = this.cubemaps.get(texture);
        if (cubemap != null) {
            this.cubemaps.remove(texture);
            cubemap.dispose();
        }
    }

    public function dispose():Void {
        this.cubemaps = new Map<Texture, WebGLCubeRenderTarget>();
    }
}