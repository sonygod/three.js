package three.materials;

import three.materials.Material;

class MeshDistanceMaterial extends Material {
    public var isMeshDistanceMaterial:Bool = true;
    public var type:String = 'MeshDistanceMaterial';
    public var map:Null<Any> = null;
    public var alphaMap:Null<Any> = null;
    public var displacementMap:Null<Any> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public function new(parameters:Any) {
        super();
        setValues(parameters);
    }

    public function copy(source:MeshDistanceMaterial):MeshDistanceMaterial {
        super.copy(source);
        this.map = source.map;
        this.alphaMap = source.alphaMap;
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
        return this;
    }
}