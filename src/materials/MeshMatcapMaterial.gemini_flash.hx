import three.constants.TangentSpaceNormalMap;
import three.math.Color;
import three.math.Vector2;
import three.materials.Material;

class MeshMatcapMaterial extends Material {

  public var isMeshMatcapMaterial:Bool = true;

  public var defines:Map<String, String> = new Map<String, String>({'MATCAP': ''});

  public var type:String = 'MeshMatcapMaterial';

  public var color:Color = new Color(0xFFFFFF); // diffuse

  public var matcap:Dynamic = null;

  public var map:Dynamic = null;

  public var bumpMap:Dynamic = null;

  public var bumpScale:Float = 1;

  public var normalMap:Dynamic = null;

  public var normalMapType:TangentSpaceNormalMap = TangentSpaceNormalMap.TangentSpaceNormalMap;

  public var normalScale:Vector2 = new Vector2(1, 1);

  public var displacementMap:Dynamic = null;

  public var displacementScale:Float = 1;

  public var displacementBias:Float = 0;

  public var alphaMap:Dynamic = null;

  public var flatShading:Bool = false;

  public var fog:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();

    if (parameters != null) {
      this.setValues(parameters);
    }
  }

  public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
    super.copy(source);

    this.defines = new Map<String, String>({'MATCAP': ''});
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