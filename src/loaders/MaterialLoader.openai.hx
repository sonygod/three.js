package three.loaders;

import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.*;

class MaterialLoader extends Loader {
    public var textures:Array<String> = [];

    public function new(manager:Loader) {
        super(manager);
        textures = [];
    }

    public function load(url:String, onLoad:Material->Void, onProgress:ProgressEvent->Void, onError:Error->Void) {
        var loader:FileLoader = new FileLoader(manager);
        loader.setPath(path);
        loader.setRequestHeader(requestHeader);
        loader.setWithCredentials(withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(parse(JSON.parse(text)));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    private function parse(json:Dynamic):Material {
        var material:Material = createMaterialFromType(json.type);
        if (json.uuid != null) material.uuid = json.uuid;
        if (json.name != null) material.name = json.name;
        if (json.color != null && material.color != null) material.color.setHex(json.color);
        // ... (all the material properties)
        if (json.uniforms != null) {
            for (name in json.uniforms) {
                var uniform:Dynamic = json.uniforms[name];
                material.uniforms[name] = {};
                switch (uniform.type) {
                    case 't':
                        material.uniforms[name].value = getTexture(uniform.value);
                        break;
                    case 'c':
                        material.uniforms[name].value = new Color().setHex(uniform.value);
                        break;
                    case 'v2':
                        material.uniforms[name].value = new Vector2().fromArray(uniform.value);
                        break;
                    case 'v3':
                        material.uniforms[name].value = new Vector3().fromArray(uniform.value);
                        break;
                    case 'v4':
                        material.uniforms[name].value = new Vector4().fromArray(uniform.value);
                        break;
                    case 'm3':
                        material.uniforms[name].value = new Matrix3().fromArray(uniform.value);
                        break;
                    case 'm4':
                        material.uniforms[name].value = new Matrix4().fromArray(uniform.value);
                        break;
                    default:
                        material.uniforms[name].value = uniform.value;
                }
            }
        }
        // ... (rest of the material properties)
        return material;
    }

    private function getTexture(name:String):Texture {
        if (textures[name] == null) {
            trace('THREE.MaterialLoader: Undefined texture $name');
        }
        return textures[name];
    }

    public function setTextures(value:Array<String>):MaterialLoader {
        textures = value;
        return this;
    }

    static public function createMaterialFromType(type:String):Material {
        var materialLib:Map<String, Material> = [
            'ShadowMaterial' => ShadowMaterial,
            // ... (all the material types)
            'Material' => Material
        ];
        return new materialLib[type]();
    }
}