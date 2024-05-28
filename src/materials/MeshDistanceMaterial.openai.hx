package three.materials;

import three.materials.Material;

class MeshDistanceMaterial extends Material {
    public var isMeshDistanceMaterial:Bool = true;
    public var type:String = 'MeshDistanceMaterial';
    public var map:Dynamic;
    public var alphaMap:Dynamic;
    public var displacementMap:Dynamic;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public function new(?parameters:Dynamic) {
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