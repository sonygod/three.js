import three.materials.ShaderMaterial;
import three.materials.UniformsUtils;
import three.constants.BlendingEquation;
import three.constants.BlendingDestinationFactor;
import three.constants.BlendingFactor;
import three.constants.NormalMapTypes;
import three.constants.Combine;

class MMDToonMaterial extends ShaderMaterial {

	public var isMMDToonMaterial:Bool = true;
	public var type:String = "MMDToonMaterial";
	public var _matcapCombine:BlendingEquation = BlendingEquation.Add;
	public var emissiveIntensity:Float = 1.0;
	public var normalMapType:NormalMapTypes = NormalMapTypes.TangentSpaceNormalMap;
	public var combine:Combine = Combine.Multiply;
	public var wireframeLinecap:String = "round";
	public var wireframeLinejoin:String = "round";
	public var flatShading:Bool = false;
	public var lights:Bool = true;

	public var _shininess:Float = 30.0;
	public var shininess(get, set):Float;
	public var color(get, set):three.math.Color;

	public function new(parameters:Dynamic) {
		super();
		this.vertexShader = MMDToonShader.vertexShader;
		this.fragmentShader = MMDToonShader.fragmentShader;
		this.defines = cast parameters.defines;
		this.uniforms = UniformsUtils.clone(MMDToonShader.uniforms);

		var exposePropertyNames = [
			"specular",
			"opacity",
			"diffuse",
			"map",
			"matcap",
			"gradientMap",
			"lightMap",
			"lightMapIntensity",
			"aoMap",
			"aoMapIntensity",
			"emissive",
			"emissiveMap",
			"bumpMap",
			"bumpScale",
			"normalMap",
			"normalScale",
			"displacemantBias",
			"displacemantMap",
			"displacemantScale",
			"specularMap",
			"alphaMap",
			"reflectivity",
			"refractionRatio"
		];
		for (propertyName in exposePropertyNames) {
			setProperty(propertyName);
		}

		this.setValues(parameters);
	}

	public function copy(source:MMDToonMaterial):MMDToonMaterial {
		super.copy(source);
		this.matcapCombine = source.matcapCombine;
		this.emissiveIntensity = source.emissiveIntensity;
		this.normalMapType = source.normalMapType;
		this.combine = source.combine;
		this.wireframeLinecap = source.wireframeLinecap;
		this.wireframeLinejoin = source.wireframeLinejoin;
		this.flatShading = source.flatShading;
		return this;
	}

	private function setProperty(propertyName:String) {
		var property = this.uniforms[propertyName];
		if (property == null) return;
		var propertyValue = property.value;

		var getter = function() {
			return propertyValue;
		};

		var setter = function(value:Dynamic) {
			propertyValue = value;
		};

		Reflect.setField(this, propertyName, getter, setter);
	}

	public function get_matcapCombine():BlendingEquation {
		return this._matcapCombine;
	}

	public function set_matcapCombine(value:BlendingEquation):BlendingEquation {
		this._matcapCombine = value;

		switch (value) {
			case BlendingEquation.Multiply:
				this.defines.MATCAP_BLENDING_MULTIPLY = true;
				delete this.defines.MATCAP_BLENDING_ADD;
			default:
			case BlendingEquation.Add:
				this.defines.MATCAP_BLENDING_ADD = true;
				delete this.defines.MATCAP_BLENDING_MULTIPLY;
		}

		return value;
	}

	public function get_shininess():Float {
		return this._shininess;
	}

	public function set_shininess(value:Float):Float {
		this._shininess = value;
		this.uniforms.shininess.value = Math.max(this._shininess, 1e-4);
		return value;
	}

	public function get_color():three.math.Color {
		return this.uniforms.diffuse.value;
	}

	public function set_color(value:three.math.Color):three.math.Color {
		this.uniforms.diffuse.value = value;
		return value;
	}

}