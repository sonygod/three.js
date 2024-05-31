import three.constants.MultiplyOperation;
import three.constants.TangentSpaceNormalMap;
import three.math.Color;
import three.math.Euler;
import three.math.Vector2;
import three.materials.Material;

class MeshLambertMaterial extends Material {
	public var isMeshLambertMaterial:Bool = true;
	public var type(default, null):String = "MeshLambertMaterial";
	public var color(default, null):Color = new Color(0xffffff); // diffuse
	public var map:Dynamic = null;
	public var lightMap:Dynamic = null;
	public var lightMapIntensity(default, null):Float = 1.0;
	public var aoMap:Dynamic = null;
	public var aoMapIntensity(default, null):Float = 1.0;
	public var emissive(default, null):Color = new Color(0x000000);
	public var emissiveIntensity(default, null):Float = 1.0;
	public var emissiveMap:Dynamic = null;
	public var bumpMap:Dynamic = null;
	public var bumpScale(default, null):Float = 1;
	public var normalMap:Dynamic = null;
	public var normalMapType(default, null):Int = TangentSpaceNormalMap;
	public var normalScale(default, null):Vector2 = new Vector2(1, 1);
	public var displacementMap:Dynamic = null;
	public var displacementScale(default, null):Float = 1;
	public var displacementBias(default, null):Float = 0;
	public var specularMap:Dynamic = null;
	public var alphaMap:Dynamic = null;
	public var envMap:Dynamic = null;
	public var envMapRotation(default, null):Euler = new Euler();
	public var combine(default, null):Int = MultiplyOperation;
	public var reflectivity(default, null):Float = 1;
	public var refractionRatio(default, null):Float = 0.98;
	public var wireframe(default, null):Bool = false;
	public var wireframeLinewidth(default, null):Float = 1;
	public var wireframeLinecap(default, null):String = "round";
	public var wireframeLinejoin(default, null):String = "round";
	public var flatShading(default, null):Bool = false;
	public var fog(default, null):Bool = true;

	public function new(?parameters:Dynamic) {
		super();
		if (parameters != null) {
			this.setValues(parameters);
		}
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