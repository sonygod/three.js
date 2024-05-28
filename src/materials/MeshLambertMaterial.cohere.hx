import openfl.geom.Vector2;
import openfl.geom.Color;
import openfl.geom.Euler;

class MeshLambertMaterial extends Material {

	public var isMeshLambertMaterial:Bool;
	public var type:String;
	public var color:Color;
	public var map:Dynamic;
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
	public var specularMap:Dynamic;
	public var alphaMap:Dynamic;
	public var envMap:Dynamic;
	public var envMapRotation:Euler;
	public var combine:Int;
	public var reflectivity:Float;
	public var refractionRatio:Float;
	public var wireframe:Bool;
	public var wireframeLinewidth:Int;
	public var wireframeLinecap:String;
	public var wireframeLinejoin:String;
	public var flatShading:Bool;
	public var fog:Bool;

	public function new (parameters:Dynamic = null) {
		super();
		isMeshLambertMaterial = true;
		type = 'MeshLambertMaterial';
		color = new Color(0xffffff);
		lightMapIntensity = 1.0;
		aoMapIntensity = 1.0;
		emissive = new Color(0x000000);
		emissiveIntensity = 1.0;
		bumpScale = 1;
		displacementScale = 1;
		displacementBias = 0;
		reflectivity = 1;
		refractionRatio = 0.98;
		wireframeLinewidth = 1;
		wireframeLinecap = 'round';
		wireframeLinejoin = 'round';
		flatShading = false;
		fog = true;
		setValues(parameters);
	}

	public function copy (source:MeshLambertMaterial):MeshLambertMaterial {
		super.copy(source);
		color.copy(source.color);
		map = source.map;
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
		specularMap = source.specularMap;
		alphaMap = source.alphaMap;
		envMap = source.envMap;
		envMapRotation.copy(source.envMapRotation);
		combine = source.combine;
		reflectivity = source.reflectivity;
		refractionRatio = source.refractionRatio;
		wireframe = source.wireframe;
		wireframeLinewidth = source.wireframeLinewidth;
		wireframeLinecap = source.wireframeLinecap;
		wireframeLinejoin = source.wireframeLinejoin;
		flatShading = source.flatShading;
		fog = source.fog;
		return this;
	}

}