import threejs.materials.Material;
import threejs.math.Color;

class SpriteMaterial extends Material {

	public var isSpriteMaterial:Bool;
	public var color:Color;
	public var map:Dynamic;
	public var alphaMap:Dynamic;
	public var rotation:Float;
	public var sizeAttenuation:Bool;
	public var fog:Bool;

	public function new(parameters:Dynamic) {

		super();

		this.isSpriteMaterial = true;

		this.type = 'SpriteMaterial';

		this.color = new Color(0xffffff);

		this.map = null;

		this.alphaMap = null;

		this.rotation = 0;

		this.sizeAttenuation = true;

		this.transparent = true;

		this.fog = true;

		this.setValues(parameters);

	}

	public function copy(source:SpriteMaterial):SpriteMaterial {

		super.copy(source);

		this.color.copy(source.color);

		this.map = source.map;

		this.alphaMap = source.alphaMap;

		this.rotation = source.rotation;

		this.sizeAttenuation = source.sizeAttenuation;

		this.fog = source.fog;

		return this;

	}

}