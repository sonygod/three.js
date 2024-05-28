import openfl.geom.Vector2;
import openfl.display.Color;
import js.Browser;

class MeshMatcapMaterial extends Material {

	public var isMeshMatcapMaterial:Bool;
	public var defines:Map<String, String>;
	public var type:String;
	public var color:Color;
	public var matcap:Dynamic;
	public var map:Dynamic;
	public var bumpMap:Dynamic;
	public var bumpScale:Float;
	public var normalMap:Dynamic;
	public var normalMapType:Int;
	public var normalScale:Vector2;
	public var displacementMap:Dynamic;
	public var displacementScale:Float;
	public var displacementBias:Float;
	public var alphaMap:Dynamic;
	public var flatShading:Bool;
	public var fog:Bool;

	public function new(parameters:Dynamic) {
		super();
		isMeshMatcapMaterial = true;
		defines = { 'MATCAP': '' };
		type = 'MeshMatcapMaterial';
		color = new Color(0xffffff);
		bumpScale = 1.0;
		normalScale = new Vector2(1.0, 1.0);
		displacementScale = 1.0;
		displacementBias = 0.0;
		flatShading = false;
		fog = true;
		setValues(parameters);
	}

	public function copy(source:Dynamic):Void {
		super.copy(source);
		defines = { 'MATCAP': '' };
		color.copy(source.color);
		matcap = source.matcap;
		map = source.map;
		bumpMap = source.bumpMap;
		bumpScale = source.bumpScale;
		normalMap = source.normalMap;
		normalMapType = source.normalMapType;
		normalScale.copy(source.normalScale);
		displacementMap = source.displacementMap;
		displacementScale = source.displacementScale;
		displacementBias = source.displacementBias;
		alphaMap = source.alphaMap;
		flatShading = source.flatShading;
		fog = source.fog;
	}

}

class Material {
	public function copy(source:Dynamic):Void {}
	public function setValues(parameters:Dynamic):Void {}
}