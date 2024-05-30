import threejs.materials.Material;
import threejs.constants.BasicDepthPacking;

class MeshDepthMaterial extends Material {

	public var isMeshDepthMaterial:Bool;
	public var type:String;
	public var depthPacking:Int;
	public var map:Dynamic;
	public var alphaMap:Dynamic;
	public var displacementMap:Dynamic;
	public var displacementScale:Float;
	public var displacementBias:Float;
	public var wireframe:Bool;
	public var wireframeLinewidth:Float;

	public function new(parameters:Dynamic) {

		super();

		this.isMeshDepthMaterial = true;

		this.type = 'MeshDepthMaterial';

		this.depthPacking = BasicDepthPacking;

		this.map = null;

		this.alphaMap = null;

		this.displacementMap = null;
		this.displacementScale = 1;
		this.displacementBias = 0;

		this.wireframe = false;
		this.wireframeLinewidth = 1;

		this.setValues(parameters);

	}

	public override function copy(source:MeshDepthMaterial):MeshDepthMaterial {

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