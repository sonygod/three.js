import js.Browser.Window;
import js.Three.Material;
import js.Three.MultiplyOperation;
import js.Three.Color;
import js.Three.Euler;

class MeshBasicMaterial extends Material {
    public var isMeshBasicMaterial:Bool;
    public var type:String;
    public var color:Color;
    public var map:Dynamic;
    public var lightMap:Dynamic;
    public var lightMapIntensity:F32;
    public var aoMap:Dynamic;
    public var aoMapIntensity:F32;
    public var specularMap:Dynamic;
    public var alphaMap:Dynamic;
    public var envMap:Dynamic;
    public var envMapRotation:Euler;
    public var combine:MultiplyOperation;
    public var reflectivity:F32;
    public var refractionRatio:F32;
    public var wireframe:Bool;
    public var wireframeLinewidth:Int;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var fog:Bool;

    public function new(?parameters:Dynamic) {
        super();
        isMeshBasicMaterial = true;
        type = 'MeshBasicMaterial';
        color = new Color(0xffffff);
        lightMapIntensity = 1.0;
        aoMapIntensity = 1.0;
        reflectivity = 1;
        refractionRatio = 0.98;
        wireframe = false;
        wireframeLinewidth = 1;
        wireframeLinecap = 'round';
        wireframeLinejoin = 'round';
        fog = true;
        setValues(parameters);
    }

    public function copy(source:MeshBasicMaterial) : MeshBasicMaterial {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        lightMap = source.lightMap;
        lightMapIntensity = source.lightMapIntensity;
        aoMap = source.aoMap;
        aoMapIntensity = source.aoMapIntensity;
        specularMap = source.specularMap;
        alphaMap = source.alphaMap;
        envMap = source.envMap;
        envMapRotation.copy(source.envMapRotation);
        combine = source.combine;
        reflectivity = source.reflectivity;
        refractionRatio = source.refractionRatio;
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;
        fog = source.fog;
        return this;
    }
}

class MultiplyOperation { }

class Color {
    public function new(?hex:Int) { }
    public function copy(source:Color) : Color { }
}

class Euler {
    public function new(?x:F32, ?y:F32, ?z:F32, ?order:String) { }
    public function copy(source:Euler) : Euler { }
}