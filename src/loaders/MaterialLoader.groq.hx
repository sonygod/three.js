package three.loaders;

import math.Color;
import math.Vector2;
import math.Vector3;
import math.Vector4;
import math.Matrix3;
import math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.*;

class MaterialLoader extends Loader {
    public var textures:Map<String,Dynamic>;

    public function new(manager:Loader) {
        super(manager);
        this.textures = new Map<String, Dynamic>();
    }

    public function load(url:String, onLoad:Material->Void, onProgress:Dynamic->Void, onError:Dynamic->Void) {
        var loader = new FileLoader(this.manager);
        loader.setPath(this.path);
        loader.setRequestHeader(this.requestHeader);
        loader.setWithCredentials(this.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(this.parse(haxe.Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                this.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Material {
        var material:Material = MaterialLoader.createMaterialFromType(json.type);

        if (json.uuid != null) material.uuid = json.uuid;
        if (json.name != null) material.name = json.name;
        if (json.color != null && material.color != null) material.color.setHex(json.color);
        if (json.roughness != null) material.roughness = json.roughness;
        if (json.metalness != null) material.metalness = json.metalness;
        // ... (rest of the material properties)

        if (json.uniforms != null) {
            for (name in json.uniforms.keys()) {
                var uniform:Dynamic = json.uniforms.get(name);
                material.uniforms.set(name, {});

                switch (uniform.type) {
                    case 't':
                        material.uniforms.get(name).value = getTexture(uniform.value);
                        break;
                    case 'c':
                        material.uniforms.get(name).value = new Color().setHex(uniform.value);
                        break;
                    case 'v2':
                        material.uniforms.get(name).value = new Vector2().fromArray(uniform.value);
                        break;
                    case 'v3':
                        material.uniforms.get(name).value = new Vector3().fromArray(uniform.value);
                        break;
                    case 'v4':
                        material.uniforms.get(name).value = new Vector4().fromArray(uniform.value);
                        break;
                    case 'm3':
                        material.uniforms.get(name).value = new Matrix3().fromArray(uniform.value);
                        break;
                    case 'm4':
                        material.uniforms.get(name).value = new Matrix4().fromArray(uniform.value);
                        break;
                    default:
                        material.uniforms.get(name).value = uniform.value;
                }
            }
        }

        // ... (rest of the material properties)

        return material;
    }

    public function getTexture(name:String):Dynamic {
        if (textures.get(name) == null) {
            trace('THREE.MaterialLoader: Undefined texture ' + name);
        }
        return textures.get(name);
    }

    public function setTextures(value:Map<String, Dynamic>):MaterialLoader {
        this.textures = value;
        return this;
    }

    static public function createMaterialFromType(type:String):Material {
        var materialLib = [
            ShadowMaterial, SpriteMaterial, RawShaderMaterial, ShaderMaterial, PointsMaterial,
            MeshPhysicalMaterial, MeshStandardMaterial, MeshPhongMaterial, MeshToonMaterial,
            MeshNormalMaterial, MeshLambertMaterial, MeshDepthMaterial, MeshDistanceMaterial,
            MeshBasicMaterial, MeshMatcapMaterial, LineDashedMaterial, LineBasicMaterial, Material
        ];

        return Type.createInstance(Type.resolveClass(materialLib[type]));
    }
}