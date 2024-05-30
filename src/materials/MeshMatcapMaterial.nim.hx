import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;
import three.math.Color;

class MeshMatcapMaterial extends Material {

    public var isMeshMatcapMaterial:Bool = true;

    public var defines:Map<String, String> = new Map();

    public var type:String = 'MeshMatcapMaterial';

    public var color:Color = new Color(0xffffff); // diffuse

    public var matcap:Null<Dynamic> = null;

    public var map:Null<Dynamic> = null;

    public var bumpMap:Null<Dynamic> = null;
    public var bumpScale:Float = 1;

    public var normalMap:Null<Dynamic> = null;
    public var normalMapType:TangentSpaceNormalMap = TangentSpaceNormalMap.TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);

    public var displacementMap:Null<Dynamic> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public var alphaMap:Null<Dynamic> = null;

    public var flatShading:Bool = false;

    public var fog:Bool = true;

    public function new(parameters:Map<String, Dynamic>) {
        super();

        this.defines.set('MATCAP', '');

        this.setValues(parameters);
    }

    public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
        super.copy(source);

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

export { MeshMatcapMaterial };