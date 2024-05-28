import Material from './Material.hx';

class MeshDistanceMaterial extends Material {
	public var isMeshDistanceMaterial:Bool;
	public var type:String;
	public var map:Null<Dynamic>;
	public var alphaMap:Null<Dynamic>;
	public var displacementMap:Null<Dynamic>;
	public var displacementScale:Float;
	public var displacementBias:Float;

	public function new(parameters:Dynamic) {
		super();
		isMeshDistanceMaterial = true;
		type = 'MeshDistanceMaterial';
		map = null;
		alphaMap = null;
		displacementMap = null;
		displacementScale = 1.0;
		displacementBias = 0.0;
		setValues(parameters);
	}

	public function copy(source:MeshDistanceMaterial):MeshDistanceMaterial {
		super.copy(source);
		map = source.map;
		alphaMap = source.alphaMap;
		displacementMap = source.displacementMap;
		displacementScale = source.displacementScale;
		displacementBias = source.displacementBias;
		return this;
	}
}