import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshToonMaterial extends Material {

    public var isMeshToonMaterial:Bool = true;
    public var defines:Map<String, String> = { 'TOON': '' };
    public var type:String = 'MeshToonMaterial';
    public var color:Color = new Color(0xffffff);
    public var map:Null<Dynamic> = null;
    public var gradientMap:Null<Dynamic> = null;
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
    public var normalMapType:TangentSpaceNormalMap = TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);
    public var displacementMap:Null<Dynamic> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;
    public var alphaMap:Null<Dynamic> = null;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';
    public var fog:Bool = true;

    public function new(parameters:Map<String, Dynamic>) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:MeshToonMaterial):MeshToonMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.gradientMap = source.gradientMap;
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
        this.alphaMap = source.alphaMap;
        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        this.wireframeLinecap = source.wireframeLinecap;
        this.wireframeLinejoin = source.wireframeLinejoin;
        this.fog = source.fog;
        return this;
    }

}