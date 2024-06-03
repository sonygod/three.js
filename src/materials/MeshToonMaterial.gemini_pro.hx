import js.lib.Math;
import js.lib.Object;
import js.lib.Array;
import js.lib.String;
import haxe.ds.StringMap;
import haxe.io.Bytes;

class MeshToonMaterial extends Material {

	public var isMeshToonMaterial:Bool;
	public var defines:StringMap<String>;
	public var type:String;
	public var color:Color;
	public var map:Dynamic;
	public var gradientMap:Dynamic;
	public var lightMap:Dynamic;
	public var lightMapIntensity:Float;
	public var aoMap:Dynamic;
	public var aoMapIntensity:Float;
	public var emissive:Color;
	public var emissiveIntensity:Float;
	public var emissiveMap:Dynamic;
	public var bumpMap:Dynamic;
	public var bumpScale:Float;
	public var normalMap:Dynamic;
	public var normalMapType:Int;
	public var normalScale:Vector2;
	public var displacementMap:Dynamic;
	public var displacementScale:Float;
	public var displacementBias:Float;
	public var alphaMap:Dynamic;
	public var wireframe:Bool;
	public var wireframeLinewidth:Float;
	public var wireframeLinecap:String;
	public var wireframeLinejoin:String;
	public var fog:Bool;

	public function new(parameters:Dynamic = null) {
		super();
		isMeshToonMaterial = true;
		defines = new StringMap<String>();
		defines.set("TOON", "");
		type = "MeshToonMaterial";
		color = new Color(0xffffff);
		map = null;
		gradientMap = null;
		lightMap = null;
		lightMapIntensity = 1.0;
		aoMap = null;
		aoMapIntensity = 1.0;
		emissive = new Color(0x000000);
		emissiveIntensity = 1.0;
		emissiveMap = null;
		bumpMap = null;
		bumpScale = 1;
		normalMap = null;
		normalMapType = TangentSpaceNormalMap;
		normalScale = new Vector2(1, 1);
		displacementMap = null;
		displacementScale = 1;
		displacementBias = 0;
		alphaMap = null;
		wireframe = false;
		wireframeLinewidth = 1;
		wireframeLinecap = "round";
		wireframeLinejoin = "round";
		fog = true;
		if (parameters != null) {
			setValues(parameters);
		}
	}

	public function copy(source:MeshToonMaterial):MeshToonMaterial {
		super.copy(source);
		color.copy(source.color);
		map = source.map;
		gradientMap = source.gradientMap;
		lightMap = source.lightMap;
		lightMapIntensity = source.lightMapIntensity;
		aoMap = source.aoMap;
		aoMapIntensity = source.aoMapIntensity;
		emissive.copy(source.emissive);
		emissiveMap = source.emissiveMap;
		emissiveIntensity = source.emissiveIntensity;
		bumpMap = source.bumpMap;
		bumpScale = source.bumpScale;
		normalMap = source.normalMap;
		normalMapType = source.normalMapType;
		normalScale.copy(source.normalScale);
		displacementMap = source.displacementMap;
		displacementScale = source.displacementScale;
		displacementBias = source.displacementBias;
		alphaMap = source.alphaMap;
		wireframe = source.wireframe;
		wireframeLinewidth = source.wireframeLinewidth;
		wireframeLinecap = source.wireframeLinecap;
		wireframeLinejoin = source.wireframeLinejoin;
		fog = source.fog;
		return this;
	}

}