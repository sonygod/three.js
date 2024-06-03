import haxe.extern.Either;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Vector2;

class MeshNormalMaterial extends Material {

	public var isMeshNormalMaterial:Bool = true;
	public var type:String = "MeshNormalMaterial";

	public var bumpMap:Either<Null<Dynamic>,Dynamic> = null;
	public var bumpScale:Float = 1;

	public var normalMap:Either<Null<Dynamic>,Dynamic> = null;
	public var normalMapType:TangentSpaceNormalMap = TangentSpaceNormalMap.TangentSpaceNormalMap;
	public var normalScale:Vector2 = new Vector2(1, 1);

	public var displacementMap:Either<Null<Dynamic>,Dynamic> = null;
	public var displacementScale:Float = 1;
	public var displacementBias:Float = 0;

	public var wireframe:Bool = false;
	public var wireframeLinewidth:Float = 1;

	public var flatShading:Bool = false;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) this.setValues(parameters);
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