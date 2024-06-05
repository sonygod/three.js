import three.constants.TangentSpaceNormalMap;
import three.math.Vector2;
import three.materials.Material;

class MeshNormalMaterial extends Material {

	public var isMeshNormalMaterial:Bool;
	public var bumpMap:Dynamic;
	public var bumpScale:Float;
	public var normalMap:Dynamic;
	public var normalMapType:Int;
	public var normalScale:Vector2;
	public var displacementMap:Dynamic;
	public var displacementScale:Float;
	public var displacementBias:Float;
	public var wireframe:Bool;
	public var wireframeLinewidth:Float;
	public var flatShading:Bool;

	public function new(parameters:Dynamic = null) {
		super();
		this.isMeshNormalMaterial = true;
		this.type = "MeshNormalMaterial";

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