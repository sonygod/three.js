import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshMatcapMaterial extends Material {

    public var isMeshMatcapMaterial:Bool;
    public var defines:Map<String, String>;
    public var type:String;
    public var color:Color;
    public var matcap:Dynamic; // Assuming a dynamic type for now
    public var map:Dynamic; // Assuming a dynamic type for now
    public var bumpMap:Dynamic; // Assuming a dynamic type for now
    public var bumpScale:Float;
    public var normalMap:Dynamic; // Assuming a dynamic type for now
    public var normalMapType:Int;
    public var normalScale:Vector2;
    public var displacementMap:Dynamic; // Assuming a dynamic type for now
    public var displacementScale:Float;
    public var displacementBias:Float;
    public var alphaMap:Dynamic; // Assuming a dynamic type for now
    public var flatShading:Bool;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();

        this.isMeshMatcapMaterial = true;
        this.defines = new Map();
        this.defines.set('MATCAP', '');

        this.type = 'MeshMatcapMaterial';
        this.color = new Color(0xffffff); // diffuse

        this.matcap = null;
        this.map = null;
        this.bumpMap = null;
        this.bumpScale = 1;

        this.normalMap = null;
        this.normalMapType = TangentSpaceNormalMap;
        this.normalScale = new Vector2(1, 1);

        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;

        this.alphaMap = null;
        this.flatShading = false;
        this.fog = true;

        this.setValues(parameters);
    }

    public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
        super.copy(source);

        this.defines = new Map();
        this.defines.set('MATCAP', '');

        this.color.copy(source.color);

        this.matcap = source.matcap;
        this.map = source.map;
        this.bumpMap = source.bumpMap;
        this.bumpScale = source.bumpScale;
        this.normalMap = source.normalMap;
        this.normalMapType = source.normalMapType;
        this.normalScale.copy(source.normalScale);
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
        this.alphaMap = source.alphaMap;
        this.flatShading = source.flatShading;
        this.fog = source.fog;

        return this;
    }
}