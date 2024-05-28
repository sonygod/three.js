import TangentSpaceNormalMap from "../constants";
import Material from "./Material";
import Vector2 from "../math/Vector2";

class MeshNormalMaterial extends Material {
    public isMeshNormalMaterial:Bool = true;
    public type:String = "MeshNormalMaterial";
    public bumpMap:Null<Dynamic> = null;
    public bumpScale:F1 = 1;
    public normalMap:Null<Dynamic> = null;
    public normalMapType:TangentSpaceNormalMap;
    public normalScale:Vector2 = new Vector2(1, 1);
    public displacementMap:Null<Dynamic> = null;
    public displacementScale:F1 = 1;
    public displacementBias:F1 = 0;
    public wireframe:Bool = false;
    public wireframeLinewidth:F1 = 1;
    public flatShading:Bool = false;

    public function new(parameters:Null<Dynamic> = null) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:MeshNormalMaterial):MeshNormalMaterial {
        super.copy(source);
        this.bumpMap = source.bumpMap;
        this.bumpScale = source.bumpScale;
        this.normalMap = source.normalMap;
        this.normalMapType = source.normalMapType;
        this.normalScale.copy(source.normalScale);
        this.displacementMap = source.displacementMap;
        this.displacementScale = source.displacementScale;
        this.displacementBias = source.displacementBias;
        this.wireframe = source.wireframe;
        this.wireframeLinewidth = source.wireframeLinewidth;
        this.flatShading = source.flatShading;
        return this;
    }
}

export class MeshNormalMaterial;