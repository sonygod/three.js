package three.materials;

import three.Material;

class MeshDistanceMaterial extends Material {
    public var isMeshDistanceMaterial:Bool = true;
    public var type:String = 'MeshDistanceMaterial';

    public var map:Dynamic = null;
    public var alphaMap:Dynamic = null;
    public var displacementMap:Dynamic = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public function new(parameters:Dynamic = null) {
        super();
        if (parameters != null) {
            setValues(parameters);
        }
    }

    public function copy(source:MeshDistanceMaterial):MeshDistanceMaterial {
        super.copy(source);
        map = source.map;
        alphaMap = source.alphaMap;
        displacementMap = source.displacementMap;
        displacementScale = source.displacementScale;
        displacementBias = source.displacementBias;
        return this;
    }
}