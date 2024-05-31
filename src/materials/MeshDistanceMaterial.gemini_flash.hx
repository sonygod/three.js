package three;

import three.materials.Material;

class MeshDistanceMaterial extends Material {

	public var isMeshDistanceMaterial:Bool = true;

	public var type(default,null):String = "MeshDistanceMaterial";

	public var map:Texture = null;

	public var alphaMap:Texture = null;

	public var displacementMap:Texture = null;
	public var displacementScale:Float = 1;
	public var displacementBias:Float = 0;

	public function new(parameters:Dynamic) {
		super();
		this.setValues(parameters);
	}

	public function copy(source:MeshDistanceMaterial):MeshDistanceMaterial {
		super.copy(source);

		this.map = source.map;
		this.alphaMap = source.alphaMap;

		this.displacementMap = source.displacementMap;
		this.displacementScale = source.displacementScale;
		this.displacementBias = source.displacementBias;

		return this;
	}

}