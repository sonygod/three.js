import Material from './Material.hx';
import Color from '../math/Color.hx';

class LineBasicMaterial extends Material {
	public var isLineBasicMaterial:Bool;
	public var type:String;
	public var color:Color;
	public var map:Null<Dynamic>;
	public var linewidth:Float;
	public var linecap:String;
	public var linejoin:String;
	public var fog:Bool;

	public function new(parameters:Null<Dynamic>) {
		super();
		isLineBasicMaterial = true;
		type = 'LineBasicMaterial';
		color = new Color(0xffffff);
		map = null;
		linewidth = 1.0;
		linecap = 'round';
		linejoin = 'round';
		fog = true;
		setValues(parameters);
	}

	public function copy(source:LineBasicMaterial):LineBasicMaterial {
		super.copy(source);
		color.copy(source.color);
		map = source.map;
		linewidth = source.linewidth;
		linecap = source.linecap;
		linejoin = source.linejoin;
		fog = source.fog;
		return this;
	}
}