@:native("TangentSpaceNormalMap")
abstract class TangentSpaceNormalMap {
    static function new():TangentSpaceNormalMap;
    static var instance:TangentSpaceNormalMap;
}

@:extern
class Material {
    public function new();
    public function copy(source:Material):Material;
    public function setValues(parameters:Dynamic):Void;
}

@:extern
class Vector2 {
    public function new(x:Float, y:Float);
    public function copy(source:Vector2):Vector2;
}

@:extern
class Color {
    public function new(hex:Int);
    public function copy(source:Color):Color;
}

@:extern
class Euler {
    public function new();
    public function copy(source:Euler):Euler;
}

class MeshStandardMaterial extends Material {

    public var isMeshStandardMaterial:Bool;
    public var type:String;
    public var defines:Map<String, String>;
    public var color:Color;
    public var roughness:Float;
    public var metalness:Float;
    public var map:Dynamic;
    public var lightMap:Dynamic;
    public var lightMapIntensity:Float;
    public var aoMap:Dynamic;
    public var aoMapIntensity:Float;
    public var emissive:Color;
    public var emissiveIntensity:Float;
    public var emissiveMap:Dynamic;
    public var bumpMap:Dynamic;
    public var bumpScale:Float;
    public var normalMap:Dynamic;
    public var normalMapType:TangentSpaceNormalMap;
    public var normalScale:Vector2;
    public var displacementMap:Dynamic;
    public var displacementScale:Float;
    public var displacementBias:Float;
    public var roughnessMap:Dynamic;
    public var metalnessMap:Dynamic;
    public var alphaMap:Dynamic;
    public var envMap:Dynamic;
    public var envMapRotation:Euler;
    public var envMapIntensity:Float;
    public var wireframe:Bool;
    public var wireframeLinewidth:Float;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var flatShading:Bool;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();

        isMeshStandardMaterial = true;

        defines = new Map<String, String>();
        defines.set("STANDARD", "");

        type = "MeshStandardMaterial";

        color = new Color(0xffffff);
        roughness = 1.0;
        metalness = 0.0;

        map = null;

        lightMap = null;
        lightMapIntensity = 1.0;

        aoMap = null;
        aoMapIntensity = 1.0;

        emissive = new Color(0x000000);
        emissiveIntensity = 1.0;
        emissiveMap = null;

        bumpMap = null;
        bumpScale = 1;

        normalMap = null;
        normalMapType = TangentSpaceNormalMap.instance;
        normalScale = new Vector2(1, 1);

        displacementMap = null;
        displacementScale = 1;
        displacementBias = 0;

        roughnessMap = null;

        metalnessMap = null;

        alphaMap = null;

        envMap = null;
        envMapRotation = new Euler();
        envMapIntensity = 1.0;

        wireframe = false;
        wireframeLinewidth = 1;
        wireframeLinecap = 'round';
        wireframeLinejoin = 'round';

        flatShading = false;

        fog = true;

        setValues(parameters);
    }

    @:override
    public function copy(source:Material):MeshStandardMaterial {
        super.copy(source);

        defines.set("STANDARD", "");

        color.copy(cast source.color);
        roughness = source.roughness;
        metalness = source.metalness;

        map = source.map;

        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;

        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;

        emissive.copy(cast source.emissive);
        emissiveMap = source.emissiveMap;
        emissiveIntensity = source.emissiveIntensity;

        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;

        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(cast source.normalScale);

        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;

        roughnessMap = source.roughnessMap;

        metalnessMap = source.metalnessMap;

        alphaMap = source.alphaMap;

        envMap = source.envMap;
        envMapRotation.copy(cast source.envMapRotation);
        envMapIntensity = source.envMapIntensity;

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;

        flatShading = source.flatShading;

        fog = source.fog;

        return this;
    }
}