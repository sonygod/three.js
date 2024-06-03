import Material from "./Material";
import BasicDepthPacking from "../constants";

class MeshDepthMaterial extends Material {

	public var isMeshDepthMaterial:Bool = true;
	public var type:String = "MeshDepthMaterial";
	public var depthPacking:Int = BasicDepthPacking;
	public var map:Dynamic = null;
	public var alphaMap:Dynamic = null;
	public var displacementMap:Dynamic = null;
	public var displacementScale:Float = 1;
	public var displacementBias:Float = 0;
	public var wireframe:Bool = false;
	public var wireframeLinewidth:Float = 1;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) {
			this.setValues(parameters);
		}
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

export default MeshDepthMaterial;