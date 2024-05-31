import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;

class MeshNormalMaterial extends Material {

    public var isMeshNormalMaterial:Bool;
    public var type:String;
    public var bumpMap:Dynamic; // Using Dynamic to match the null initial value
    public var bumpScale:Float;
    public var normalMap:Dynamic; // Using Dynamic to match the null initial value
    public var normalMapType:Int;
    public var normalScale:Vector2;
    public var displacementMap:Dynamic; // Using Dynamic to match the null initial value
    public var displacementScale:Float;
    public var displacementBias:Float;
    public var wireframe:Bool;
    public var wireframeLinewidth:Float;
    public var flatShading:Bool;

    public function new(parameters:Dynamic = null) {
        super();

        this.isMeshNormalMaterial = true;

        this.type = 'MeshNormalMaterial';

        this.bumpMap = null;
        this.bumpScale = 1;

        this.normalMap = null;
        this.normalMapType = TangentSpaceNormalMap;
        this.normalScale = new Vector2(1, 1);

        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;

        this.wireframe = false;
        this.wireframeLinewidth = 1;

        this.flatShading = false;

        this.setValues(parameters);
    }

    public override function copy(source:Material):MeshNormalMaterial {
        super.copy(source);

        var src:MeshNormalMaterial = cast source;

        this.bumpMap = src.bumpMap;
        this.bumpScale = src.bumpScale;

        this.normalMap = src.normalMap;
        this.normalMapType = src.normalMapType;
        this.normalScale.copy(src.normalScale);

        this.displacementMap = src.displacementMap;
        this.displacementScale = src.displacementScale;
        this.displacementBias = src.displacementBias;

        this.wireframe = src.wireframe;
        this.wireframeLinewidth = src.wireframeLinewidth;

        this.flatShading = src.flatShading;

        return this;
    }
}