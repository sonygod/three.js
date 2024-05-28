import Material from './Material.hx';
import Color from '../math/Color.hx';

class SpriteMaterial extends Material {

	public var isSpriteMaterial:Bool;
	public var type:String;
	public var color:Color;
	public var map:Null<Dynamic>;
	public var alphaMap:Null<Dynamic>;
	public var rotation:Float;
	public var sizeAttenuation:Bool;
	public var transparent:Bool;
	public var fog:Bool;

	public function new(parameters:Dynamic) {
		super();
		isSpriteMaterial = true;
		type = 'SpriteMaterial';
		color = new Color(0xffffff);
		map = null;
		alphaMap = null;
		rotation = 0;
		sizeAttenuation = true;
		transparent = true;
		fog = true;
		setValues(parameters);
	}

	public function copy(source:SpriteMaterial):Void {
		super.copy(source);
		color.copy(source.color);
		map = source.map;
		alphaMap = source.alphaMap;
		rotation = source.rotation;
		sizeAttenuation = source.sizeAttenuation;
		fog = source.fog;
	}

}

export { SpriteMaterial };