import Material from "./Material.hx";
import BasicDepthPacking from "../constants.hx";

class MeshDepthMaterial extends Material {
    public isMeshDepthMaterial: Bool;
    public type: String;
    public depthPacking: BasicDepthPacking;
    public map: Null<Dynamic>;
    public alphaMap: Null<Dynamic>;
    public displacementMap: Null<Dynamic>;
    public displacementScale: Float;
    public displacementBias: Int;
    public wireframe: Bool;
    public wireframeLinewidth: Int;

    public function new(parameters: Null<Dynamic> = null) {
        super();
        this.isMeshDepthMaterial = true;
        this.type = "MeshDepthMaterial";
        this.depthPacking = BasicDepthPacking.Basic;
        this.map = null;
        this.alphaMap = null;
        this.displacementMap = null;
        this.displacementScale = 1;
        this.displacementBias = 0;
        this.wireframe = false;
        this.wireframeLinewidth = 1;
        if (parameters != null) {
            this.setValues(parameters);
        }
    }

    public function copy(source: MeshDepthMaterial): MeshDepthMaterial {
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

@:export(MeshDepthMaterial)