import three.Material;
import three.Texture;

class MeshDistanceMaterial extends Material {

    public var isMeshDistanceMaterial:Bool = true;
    public var type:String = 'MeshDistanceMaterial';
    public var map:Texture;
    public var alphaMap:Texture;
    public var displacementMap:Texture;
    public var displacementScale:Float = 1.0;
    public var displacementBias:Float = 0.0;

    public function new(parameters:Dynamic = null) {
        super();
        this.map = null;
        this.alphaMap = null;
        this.displacementMap = null;
        if (parameters != null) this.setValues(parameters);
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