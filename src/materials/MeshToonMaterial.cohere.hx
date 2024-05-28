import js.Browser.Window;
import js.Three.Color;
import js.Three.Material;
import js.Three.Vector2;

class MeshToonMaterial extends Material {
    public var isMeshToonMaterial:Bool;
    public var defines:Map<String, String>;
    public var type:String;
    public var color:Color;
    public var map:Dynamic;
    public var gradientMap:Dynamic;
    public var lightMap:Dynamic;
    public var lightMapIntensity:F32;
    public var aoMap:Dynamic;
    public var aoMapIntensity:F32;
    public var emissive:Color;
    public var emissiveIntensity:F32;
    public var emissiveMap:Dynamic;
    public var bumpMap:Dynamic;
    public var bumpScale:F32;
    public var normalMap:Dynamic;
    public var normalMapType:Dynamic;
    public var normalScale:Vector2;
    public var displacementMap:Dynamic;
    public var displacementScale:F32;
    public var displacementBias:F32;
    public var alphaMap:Dynamic;
    public var wireframe:Bool;
    public var wireframeLinewidth:F32;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();
        isMeshToonMaterial = true;
        defines = {"TOON": ""};
        type = "MeshToonMaterial";
        color = new Color(0xffffff);
        lightMapIntensity = 1.0;
        aoMapIntensity = 1.0;
        emissiveIntensity = 1.0;
        bumpScale = 1;
        displacementScale = 1;
        displacementBias = 0;
        wireframe = false;
        wireframeLinewidth = 1;
        wireframeLinecap = "round";
        wireframeLinejoin = "round";
        fog = true;
        setValues(parameters);
    }

    public function copy(source:Dynamic) {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        gradientMap = source.gradientMap;
        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;
        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;
        emissive.copy(source.emissive);
        emissiveMap = source.emissiveMap;
        emissiveIntensity = source.emissiveIntensity;
        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;
        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(source.normalScale);
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        alphaMap = source.alphaMap;
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;
        fog = source.fog;
        return this;
    }
}

class TangentSpaceNormalMap {
}