import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.materials.Material;
import three.math.Color;
import three.math.Euler;
import three.math.Vector2;

class MeshLambertMaterial extends Material {

	public var isMeshLambertMaterial:Bool = true;
	public var type:String = "MeshLambertMaterial";

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
	public var wireframeLinewidth:Float;
	public var wireframeLinecap:String;
	public var wireframeLinejoin:String;
	public var flatShading:Bool;
	public var fog:Bool;

	public function new(parameters:Dynamic = null) {
		super();

		this.color = new Color(0xffffff); // diffuse

		this.lightMapIntensity = 1.0;
		this.aoMapIntensity = 1.0;
		this.emissive = new Color(0x000000);
		this.emissiveIntensity = 1.0;
		this.bumpScale = 1;
		this.normalMapType = TangentSpaceNormalMap;
		this.normalScale = new Vector2(1, 1);
		this.displacementScale = 1;
		this.displacementBias = 0;
		this.combine = MultiplyOperation;
		this.reflectivity = 1;
		this.refractionRatio = 0.98;
		this.wireframeLinewidth = 1;
		this.wireframeLinecap = "round";
		this.wireframeLinejoin = "round";

		this.setValues(parameters);
	}

	public function copy(source:MeshLambertMaterial):MeshLambertMaterial {
		super.copy(source);

		this.color.copy(source.color);

		this.map = source.map;

		this.lightMap = source.lightMap;
		this.lightMapIntensity = source.lightMapIntensity;

		this.aoMap = source.aoMap;
		this.aoMapIntensity = source.aoMapIntensity;

		this.emissive.copy(source.emissive);
		this.emissiveMap = source.emissiveMap;
		this.emissiveIntensity = source.emissiveIntensity;

		this.bumpMap = source.bumpMap;
		this.bumpScale = source.bumpScale;

		this.normalMap = source.normalMap;
		this.normalMapType = source.normalMapType;
		this.normalScale.copy(source.normalScale);

		this.displacementMap = source.displacementMap;
		this.displacementScale = source.displacementScale;
		this.displacementBias = source.displacementBias;

		this.specularMap = source.specularMap;

		this.alphaMap = source.alphaMap;

		this.envMap = source.envMap;
		this.envMapRotation.copy(source.envMapRotation);
		this.combine = source.combine;
		this.reflectivity = source.reflectivity;
		this.refractionRatio = source.refractionRatio;

		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;
		this.wireframeLinecap = source.wireframeLinecap;
		this.wireframeLinejoin = source.wireframeLinejoin;

		this.flatShading = source.flatShading;

		this.fog = source.fog;

		return this;
	}
}