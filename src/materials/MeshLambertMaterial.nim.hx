import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;
import three.math.Euler;

class MeshLambertMaterial extends Material {

    public var isMeshLambertMaterial:Bool = true;
    public var type:String = 'MeshLambertMaterial';
    public var color:Color = new Color(0xffffff); // diffuse
    public var map:Null<Dynamic> = null;
    public var lightMap:Null<Dynamic> = null;
    public var lightMapIntensity:Float = 1.0;
    public var aoMap:Null<Dynamic> = null;
    public var aoMapIntensity:Float = 1.0;
    public var emissive:Color = new Color(0x000000);
    public var emissiveIntensity:Float = 1.0;
    public var emissiveMap:Null<Dynamic> = null;
    public var bumpMap:Null<Dynamic> = null;
    public var bumpScale:Float = 1;
    public var normalMap:Null<Dynamic> = null;
    public var normalMapType:Int = TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);
    public var displacementMap:Null<Dynamic> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;
    public var specularMap:Null<Dynamic> = null;
    public var alphaMap:Null<Dynamic> = null;
    public var envMap:Null<Dynamic> = null;
    public var envMapRotation:Euler = new Euler();
    public var combine:Int = MultiplyOperation;
    public var reflectivity:Float = 1;
    public var refractionRatio:Float = 0.98;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';
    public var flatShading:Bool = false;
    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:MeshLambertMaterial):MeshLambertMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.lightMap = source.lightMap;
        this.lightMapIntensity = source.lightMapIntensity;
        this.aoMap = source.aoMap;
        this.aoMapIntensity = source.aoMapIntensity;
        this.emissive.copy(source.emissive);
        this.emissiveMap = source.emissiveMap;
        this.emissiveIntensity = source.emissiveIntensity;
        this.bumpMap = source.bumpMap;
        this.bumpScale = source.bumpScale;
        this.normalMap = source.normalMap;
        this.normalMapType = source.normalMapType;
        this.normalScale.copy(source.normalScale);
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
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
        this.flatShading = source.flatShading;
        this.fog = source.fog;
        return this;
    }

}