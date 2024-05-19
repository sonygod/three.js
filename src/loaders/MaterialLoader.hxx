import js.Browser.window;
import js.Lib.Json;
import three.math.Color;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;
import three.math.Matrix3;
import three.math.Matrix4;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.materials.Materials.*;

class MaterialLoader extends Loader {

    public var textures:Dynamic<Texture>;

    public function new(manager:Loader) {
        super(manager);
        this.textures = {};
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(Json.parse(text)));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    window.console.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(json:Dynamic):Material {
        var textures = this.textures;
        function getTexture(name:String):Texture {
            if (textures[name] == null) {
                window.console.warn('THREE.MaterialLoader: Undefined texture', name);
            }
            return textures[name];
        }
        var material = MaterialLoader.createMaterialFromType(json.type);
        // ... 其他代码转换
        return material;
    }

    public function setTextures(value:Dynamic<Texture>):MaterialLoader {
        this.textures = value;
        return this;
    }

    public static function createMaterialFromType(type:String):Material {
        var materialLib = {
            ShadowMaterial: ShadowMaterial,
            SpriteMaterial: SpriteMaterial,
            RawShaderMaterial: RawShaderMaterial,
            ShaderMaterial: ShaderMaterial,
            PointsMaterial: PointsMaterial,
            MeshPhysicalMaterial: MeshPhysicalMaterial,
            MeshStandardMaterial: MeshStandardMaterial,
            MeshPhongMaterial: MeshPhongMaterial,
            MeshToonMaterial: MeshToonMaterial,
            MeshNormalMaterial: MeshNormalMaterial,
            MeshLambertMaterial: MeshLambertMaterial,
            MeshDepthMaterial: MeshDepthMaterial,
            MeshDistanceMaterial: MeshDistanceMaterial,
            MeshBasicMaterial: MeshBasicMaterial,
            MeshMatcapMaterial: MeshMatcapMaterial,
            LineDashedMaterial: LineDashedMaterial,
            LineBasicMaterial: LineBasicMaterial,
            Material: Material
        };
        return Type.createInstance(materialLib[type], []);
    }
}