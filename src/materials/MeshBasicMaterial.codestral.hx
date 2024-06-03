import three.materials.Material;
import three.constants.MultiplyOperation;
import three.math.Color;

class MeshBasicMaterial extends Material {
    public var isMeshBasicMaterial:Bool;
    public var type:String;
    public var color:Color;
    public var map:Dynamic;
    public var lightMap:Dynamic;
    public var lightMapIntensity:Float;
    public var aoMap:Dynamic;
    public var aoMapIntensity:Float;
    public var specularMap:Dynamic;
    public var alphaMap:Dynamic;
    public var envMap:Dynamic;
    public var envMapRotation:Dynamic;
    public var combine:Dynamic;
    public var reflectivity:Float;
    public var refractionRatio:Float;
    public var wireframe:Bool;
    public var wireframeLinewidth:Float;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();

        this.isMeshBasicMaterial = true;
        this.type = 'MeshBasicMaterial';
        this.color = new Color(0xffffff);
        this.map = null;
        this.lightMap = null;
        this.lightMapIntensity = 1.0;
        this.aoMap = null;
        this.aoMapIntensity = 1.0;
        this.specularMap = null;
        this.alphaMap = null;
        this.envMap = null;
        this.envMapRotation = new Euler(); // Placeholder, Euler is not built-in in Haxe
        this.combine = MultiplyOperation;
        this.reflectivity = 1;
        this.refractionRatio = 0.98;
        this.wireframe = false;
        this.wireframeLinewidth = 1;
        this.wireframeLinecap = 'round';
        this.wireframeLinejoin = 'round';
        this.fog = true;

        this.setValues(parameters);
    }

    public function copy(source:MeshBasicMaterial):MeshBasicMaterial {
        super.copy(source);

        this.color.copy(source.color);
        this.map = source.map;
        this.lightMap = source.lightMap;
        this.lightMapIntensity = source.lightMapIntensity;
        this.aoMap = source.aoMap;
        this.aoMapIntensity = source.aoMapIntensity;
        this.specularMap = source.specularMap;
        this.alphaMap = source.alphaMap;
        this.envMap = source.envMap;
        this.envMapRotation.copy(source.envMapRotation);
        this.combine = source.combine;
        this.reflectivity = source.reflectivity;
        this.refractionRatio = source.refractionRatio;
        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        this.wireframeLinecap = source.wireframeLinecap;
        this.wireframeLinejoin = source.wireframeLinejoin;
        this.fog = source.fog;

        return this;
    }
}