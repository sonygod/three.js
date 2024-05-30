import three.materials.Material;

class MeshDistanceMaterial extends Material {

    public var isMeshDistanceMaterial:Bool;
    public var type:String;
    public var map:Dynamic;
    public var alphaMap:Dynamic;
    public var displacementMap:Dynamic;
    public var displacementScale:Float;
    public var displacementBias:Float;

    public function new(parameters:Dynamic) {
        super();
        this.isMeshDistanceMaterial = true;
        this.type = 'MeshDistanceMaterial';
        this.map = null;
        this.alphaMap = null;
        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;
        this.setValues(parameters);
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