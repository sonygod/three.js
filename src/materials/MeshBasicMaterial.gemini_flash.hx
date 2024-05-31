import three.constants.MultiplyOperation;
import three.math.Color;
import three.math.Euler;
import three.materials.Material;

class MeshBasicMaterial extends Material {

	public var isMeshBasicMaterial : Bool = true;
	public var type : String = "MeshBasicMaterial";
	public var color : Color = new Color(0xffffff); // emissive
	public var map : Dynamic = null;
	public var lightMap : Dynamic = null;
	public var lightMapIntensity : Float = 1.0;
	public var aoMap : Dynamic = null;
	public var aoMapIntensity : Float = 1.0;
	public var specularMap : Dynamic = null;
	public var alphaMap : Dynamic = null;
	public var envMap : Dynamic = null;
	public var envMapRotation : Euler = new Euler();
	public var combine : Int = MultiplyOperation;
	public var reflectivity : Float = 1;
	public var refractionRatio : Float = 0.98;
	public var wireframe : Bool = false;
	public var wireframeLinewidth : Float = 1;
	public var wireframeLinecap : String = "round";
	public var wireframeLinejoin : String = "round";
	public var fog : Bool = true;

	public function new(parameters : Dynamic = null) {
		super();
		this.setValues(parameters);
	}

	public function copy(source : MeshBasicMaterial) : MeshBasicMaterial {
		super.copy(source);
		this.color.copy(source.color);
		this.map = source.map;
		this.lightMap = source.lightMap;
		this.lightMapIntensity = source.lightMapIntensity;
		this.aoMap = source.aoMap;
		this.aoMapIntensity = source.aoMapIntensity;
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
		this.fog = source.fog;
		return this;
	}
}