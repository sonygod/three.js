import Material.Material;
import three.constants.BasicDepthPacking;

class MeshDepthMaterial extends Material {

    public var isMeshDepthMaterial:Bool = true;

    public var type:String = 'MeshDepthMaterial';

    public var depthPacking:Int = BasicDepthPacking;

    public var map:Null<Dynamic> = null;

    public var alphaMap:Null<Dynamic> = null;

    public var displacementMap:Null<Dynamic> = null;
    public var displacementScale:Float = 1;
    public var displacementBias:Float = 0;

    public var wireframe:Bool = false;
    public var wireframeLinewidth:Float = 1;

    public function new(parameters:Dynamic) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:MeshDepthMaterial):MeshDepthMaterial {
        super.copy(source);
        this.depthPacking = source.depthPacking;
        this.map = source.map;
        this.alphaMap = source.alphaMap;
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        return this;
    }

}

export MeshDepthMaterial;