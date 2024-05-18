package materials;

import three.materials.Material;

class MeshDepthMaterial extends Material {
    public var isMeshDepthMaterial:Bool = true;
    public var type:String = 'MeshDepthMaterial';
    public var depthPacking:Int = BasicDepthPacking;
    public var map:Dynamic = null;
    public var alphaMap:Dynamic = null;
    public var displacementMap:Dynamic = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;
    public var wireframe:Bool = false;
    public var wireframeLinewidth:Int = 1;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshDepthMaterial):MeshDepthMaterial {
        super.copy(source);
        depthPacking = source.depthPacking;
        map = source.map;
        alphaMap = source.alphaMap;
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        wireframe = source.wireframe;
        wireframeLinewidth = source.wireframeLinewidth;
        return this;
    }
}