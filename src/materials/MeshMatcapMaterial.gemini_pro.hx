import haxe.extern.Either;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Color;
import three.math.Vector2;

class MeshMatcapMaterial extends Material {
  public var isMeshMatcapMaterial:Bool = true;
  public var defines:Map<String,String> = new Map<String,String>({
    "MATCAP": "",
  });
  public var type:String = "MeshMatcapMaterial";
  public var color:Color = new Color(0xffffff); // diffuse
  public var matcap:Either<Null<Dynamic>,Dynamic> = null;
  public var map:Either<Null<Dynamic>,Dynamic> = null;
  public var bumpMap:Either<Null<Dynamic>,Dynamic> = null;
  public var bumpScale:Float = 1;
  public var normalMap:Either<Null<Dynamic>,Dynamic> = null;
  public var normalMapType:Int = TangentSpaceNormalMap;
  public var normalScale:Vector2 = new Vector2(1, 1);
  public var displacementMap:Either<Null<Dynamic>,Dynamic> = null;
  public var displacementScale:Float = 1;
  public var displacementBias:Float = 0;
  public var alphaMap:Either<Null<Dynamic>,Dynamic> = null;
  public var flatShading:Bool = false;
  public var fog:Bool = true;

  public function new(parameters:Dynamic = null) {
    super();
    this.setValues(parameters);
  }

  public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
    super.copy(source);
    this.defines = new Map<String,String>({
      "MATCAP": "",
    });
    this.color = source.color.clone();
    this.matcap = source.matcap;
    this.map = source.map;
    this.bumpMap = source.bumpMap;
    this.bumpScale = source.bumpScale;
    this.normalMap = source.normalMap;
    this.normalMapType = source.normalMapType;
    this.normalScale = source.normalScale.clone();
    this.displacementMap = source.displacementMap;
    this.displacementScale = source.displacementScale;
    this.displacementBias = source.displacementBias;
    this.alphaMap = source.alphaMap;
    this.flatShading = source.flatShading;
    this.fog = source.fog;
    return this;
  }
}