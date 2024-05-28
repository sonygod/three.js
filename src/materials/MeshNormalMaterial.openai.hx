package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;

class MeshNormalMaterial extends Material {
    public var isMeshNormalMaterial:Bool = true;
    public var type:String = "MeshNormalMaterial";

    public var bumpMap:Null<Dynamic>;
    public var bumpScale:Float = 1.0;

    public var normalMap:Null<Dynamic>;
    public var normalMapType:Int = TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);

    public var displacementMap:Null<Dynamic>;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1.0;

    public var flatShading:Bool = false;

    public function new(parameters:Dynamic = null) {
        super();
        setValues(parameters);
    }

    override public function copy(source:MeshNormalMaterial):MeshNormalMaterial {
        super.copy(source);

        bumpMap = source.bumpMap;
        bumpScale = source.bumpScale;

        normalMap = source.normalMap;
        normalMapType = source.normalMapType;
        normalScale.copyFrom(source.normalScale);

        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;

        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;

        flatShading = source.flatShading;

        return this;
    }
}