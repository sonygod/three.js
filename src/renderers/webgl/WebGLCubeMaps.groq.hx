package three.js.src.renderers.webgl;

import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.EquirectangularReflectionMapping;
import three.constants.EquirectangularRefractionMapping;
import three.renderers.webgl.WebGLCubeRenderTarget;

class WebGLCubeMaps {
    private var cubemaps:WeakMap<Texture, WebGLCubeRenderTarget>;

    public function new(renderer:WebGLRenderer) {
        cubemaps = new WeakMap<Texture, WebGLCubeRenderTarget>();
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
                if (cubemaps.exists(texture)) {
                    var cubemap:WebGLCubeRenderTarget = cubemaps.get(texture);
                    return mapTextureMapping(cubemap.texture, texture.mapping);
                } else {
                    var image:Image = texture.image;
                    if (image != null && image.height > 0) {
                        var renderTarget:WebGLCubeRenderTarget = new WebGLCubeRenderTarget(image.height);
                        renderTarget.fromEquirectangularTexture(renderer, texture);
                        cubemaps.set(texture, renderTarget);
                        texture.addEventListener('dispose', onTextureDispose);
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
        var texture:Texture = event.target;
        texture.removeEventListener('dispose', onTextureDispose);
        var cubemap:WebGLCubeRenderTarget = cubemaps.get(texture);
        if (cubemap != null) {
            cubemaps.remove(texture);
            cubemap.dispose();
        }
    }

    public function dispose():Void {
        cubemaps = new WeakMap<Texture, WebGLCubeRenderTarget>();
    }
}