import three.materials.Material;
import three.math.Color;

class LineBasicMaterial extends Material {
	
	public var isLineBasicMaterial:Bool;
	public var type:String;
	public var color:Color;
	public var map:Dynamic;
	public var linewidth:Float;
	public var linecap:String;
	public var linejoin:String;
	public var fog:Bool;

	public function new(parameters:Dynamic) {
		super();
		
		this.isLineBasicMaterial = true;
		this.type = 'LineBasicMaterial';
		
		this.color = new Color(0xffffff);
		this.map = null;
		
		this.linewidth = 1;
		this.linecap = 'round';
		this.linejoin = 'round';
		
		this.fog = true;
		
		this.setValues(parameters);
	}
	
	public function copy(source:LineBasicMaterial):LineBasicMaterial {
		super.copy(source);
		
		this.color.copy(source.color);
		this.map = source.map;
		this.linewidth = source.linewidth;
		this.linecap = source.linecap;
		this.linejoin = source.linejoin;
		this.fog = source.fog;
		
		return this;
	}
}