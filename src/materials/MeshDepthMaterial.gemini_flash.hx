import three.materials.Material;
import three.constants.BasicDepthPacking;

class MeshDepthMaterial extends Material {

	public var isMeshDepthMaterial : Bool;
	public var type : String;
	public var depthPacking : Int;
	public var map : Dynamic;
	public var alphaMap : Dynamic;
	public var displacementMap : Dynamic;
	public var displacementScale : Float;
	public var displacementBias : Float;
	public var wireframe : Bool;
	public var wireframeLinewidth : Float;

	public function new(parameters : Dynamic = null) {
		super();
		isMeshDepthMaterial = true;
		type = "MeshDepthMaterial";
		depthPacking = BasicDepthPacking;
		map = null;
		alphaMap = null;
		displacementMap = null;
		displacementScale = 1.0;
		displacementBias = 0.0;
		wireframe = false;
		wireframeLinewidth = 1.0;
		setValues(parameters);
	}

	public function copy(source : MeshDepthMaterial) : MeshDepthMaterial {
		super.copy(source);
		depthPacking = source.depthPacking;
		map = source.map;
		alphaMap = source.alphaMap;
		displacementMap = source.displacementMap;
		displacementScale = source.displacementScale;
		displacementBias = source.displacementBias;
		wireframe = source.wireframe;
		wireframeLinewidth = source.wireframeLinewidth;
		return this;
	}

}