package three.materials;

import three.constants.TangentSpaceNormalMap;
import three.math.Vector2;
import three.materials.Material;

class MeshNormalMaterial extends Material {
    
    public var isMeshNormalMaterial:Bool = true;
    public var type:String = 'MeshNormalMaterial';

    public var bumpMap:Dynamic = null;
    public var bumpScale:Float = 1.0;

    public var normalMap:Dynamic = null;
    public var normalMapType:Int = TangentSpaceNormalMap;
    public var normalScale:Vector2 = new Vector2(1, 1);

    public var displacementMap:Dynamic = null;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1.0;

    public var flatShading:Bool = false;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshNormalMaterial):MeshNormalMaterial {
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