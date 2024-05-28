import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;

class WebGLCubeMaps {
    public var cubemaps:WeakMap<TextureBase, CubeTexture>;

    public function new(renderer:Dynamic) {
        cubemaps = new WeakMap();
    }

    public function mapTextureMapping(texture:Texture, mapping:Int) : Texture {
        switch(mapping) {
            case CubeReflectionMapping:
                texture.mapping = CubeReflectionMapping;
                break;
            case CubeRefractionMapping:
                texture.mapping = CubeRefractionMapping;
                break;
        }
        return texture;
    }

    public function get(texture:Texture) : Texture {
        if (texture != null && texture.isTexture) {
            switch(texture.mapping) {
                case EquirectangularReflectionMapping:
                case EquirectangularRefractionMapping:
                    if (cubemaps.exists(texture)) {
                        var cubemap = cubemaps.get(texture);
                        return mapTextureMapping(cubemap, texture.mapping);
                    } else {
                        var image = texture.image;
                        if (image != null && image.height > 0) {
                            var renderTarget = new WebGLCubeRenderTarget(image.height);
                            renderTarget.fromEquirectangularTexture(renderer, texture);
                            cubemaps.set(texture, renderTarget);
                            texture.addEventListener("dispose", onTextureDispose);
                            return mapTextureMapping(renderTarget.texture, texture.mapping);
                        } else {
                            // image not yet ready. try the conversion next frame
                            return null;
                        }
                    }
                    break;
            }
        }
        return texture;
    }

    public function onTextureDispose(event:Dynamic) {
        var texture = event.target;
        texture.removeEventListener("dispose", onTextureDispose);
        var cubemap = cubemaps.get(texture);
        if (cubemap != null) {
            cubemaps.delete(texture);
            cubemap.dispose();
        }
    }

    public function dispose() {
        cubemaps = new WeakMap();
    }
}

class WebGLCubeRenderTarget {
    public var texture:CubeTexture;

    public function new(size:Int) {
        texture = new CubeTexture(size, size, false, 0);
    }

    public function fromEquirectangularTexture(renderer:Dynamic, texture:Texture) {
        // implementation specific to WebGL renderer
    }
}

enum CubeReflectionMapping { __dummy__ }
enum CubeRefractionMapping { __dummy__ }
enum EquirectangularReflectionMapping { __dummy__ }
enum EquirectangularRefractionMapping { __dummy__ }