package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.math.Vector2;
import three.math.Color;

@:nativeGen
class MeshMatcapMaterial extends Material {

    public var isMeshMatcapMaterial:Bool = true;

    public var defines(default,null):Dynamic = { 'MATCAP':'' };

    public var type(default,null):String = 'MeshMatcapMaterial';

    public var color:Color;

    public var matcap:Null<Dynamic>;

    public var map:Null<Dynamic>;

    public var bumpMap:Null<Dynamic>;
    public var bumpScale:Float = 1;

    public var normalMap:Null<Dynamic>;
    public var normalMapType:Int = TangentSpaceNormalMap;
    public var normalScale:Vector2;

    public var displacementMap:Null<Dynamic>;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public var alphaMap:Null<Dynamic>;

    public var flatShading:Bool = false;

    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        color = new Color(0xFFFFFF);
        setValues(parameters);
    }

    public function copy(source:MeshMatcapMaterial):MeshMatcapMaterial {
        super.copy(source);
        defines = { 'MATCAP':'' };
        color.copy(source.color);
        matcap = source.matcap;
        map = source.map;
        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;
        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copy(source.normalScale);
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        alphaMap = source.alphaMap;
        flatShading = source.flatShading;
        fog = source.fog;
        return this;
    }
}