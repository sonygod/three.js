import three.math.Vector2;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.MathUtils;

class MeshPhysicalMaterial extends MeshStandardMaterial {
	
	public var isMeshPhysicalMaterial:Bool;
	public var defines:Map<String, String>;
	public var type:String;
	public var anisotropyRotation:Float;
	public var anisotropyMap:Dynamic;
	public var clearcoatMap:Dynamic;
	public var clearcoatRoughness:Float;
	public var clearcoatRoughnessMap:Dynamic;
	public var clearcoatNormalScale:Vector2;
	public var clearcoatNormalMap:Dynamic;
	public var ior:Float;
	public var iridescenceMap:Dynamic;
	public var iridescenceIOR:Float;
	public var iridescenceThicknessRange:Array<Float>;
	public var iridescenceThicknessMap:Dynamic;
	public var sheenColor:Color;
	public var sheenColorMap:Dynamic;
	public var sheenRoughness:Float;
	public var sheenRoughnessMap:Dynamic;
	public var transmissionMap:Dynamic;
	public var thickness:Float;
	public var thicknessMap:Dynamic;
	public var attenuationDistance:Float;
	public var attenuationColor:Color;
	public var specularIntensity:Float;
	public var specularIntensityMap:Dynamic;
	public var specularColor:Color;
	public var specularColorMap:Dynamic;
	private var _anisotropy:Float;
	private var _clearcoat:Float;
	private var _dispersion:Float;
	private var _iridescence:Float;
	private var _sheen:Float;
	private var _transmission:Float;

	public function new(parameters:Dynamic) {
		super();
		
		this.isMeshPhysicalMaterial = true;
		this.defines = [
			'STANDARD' => '',
			'PHYSICAL' => ''
		];
		this.type = 'MeshPhysicalMaterial';
		this.anisotropyRotation = 0;
		this.anisotropyMap = null;
		this.clearcoatMap = null;
		this.clearcoatRoughness = 0.0;
		this.clearcoatRoughnessMap = null;
		this.clearcoatNormalScale = new Vector2(1, 1);
		this.clearcoatNormalMap = null;
		this.ior = 1.5;

		Reflect.setProperty(this, 'reflectivity', {
			get: function() {
				return MathUtils.clamp(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
			},
			set: function(reflectivity) {
				this.ior = (1 + 0.4 * reflectivity) / (1 - 0.4 * reflectivity);
			}
		});

		this.iridescenceMap = null;
		this.iridescenceIOR = 1.3;
		this.iridescenceThicknessRange = [100, 400];
		this.iridescenceThicknessMap = null;
		this.sheenColor = new Color(0x000000);
		this.sheenColorMap = null;
		this.sheenRoughness = 1.0;
		this.sheenRoughnessMap = null;
		this.transmissionMap = null;
		this.thickness = 0;
		this.thicknessMap = null;
		this.attenuationDistance = Math.POSITIVE_INFINITY;
		this.attenuationColor = new Color(1, 1, 1);
		this.specularIntensity = 1.0;
		this.specularIntensityMap = null;
		this.specularColor = new Color(1, 1, 1);
		this.specularColorMap = null;
		this._anisotropy = 0;
		this._clearcoat = 0;
		this._dispersion = 0;
		this._iridescence = 0;
		this._sheen = 0.0;
		this._transmission = 0;

		this.setValues(parameters);
	}

	public function get_anisotropy():Float {
		return this._anisotropy;
	}

	public function set_anisotropy(value:Float):Float {
		if ((this._anisotropy > 0) != (value > 0)) {
			this.version++;
		}
		return this._anisotropy = value;
	}

	public function get_clearcoat():Float {
		return this._clearcoat;
	}

	public function set_clearcoat(value:Float):Float {
		if ((this._clearcoat > 0) != (value > 0)) {
			this.version++;
		}
		return this._clearcoat = value;
	}

	public function get_iridescence():Float {
		return this._iridescence;
	}

	public function set_iridescence(value:Float):Float {
		if ((this._iridescence > 0) != (value > 0)) {
			this.version++;
		}
		return this._iridescence = value;
	}

	public function get_dispersion():Float {
		return this._dispersion;
	}

	public function set_dispersion(value:Float):Float {
		if ((this._dispersion > 0) != (value > 0)) {
			this.version++;
		}
		return this._dispersion = value;
	}

	public function get_sheen():Float {
		return this._sheen;
	}

	public function set_sheen(value:Float):Float {
		if ((this._sheen > 0) != (value > 0)) {
			this.version++;
		}
		return this._sheen = value;
	}

	public function get_transmission():Float {
		return this._transmission;
	}

	public function set_transmission(value:Float):Float {
		if ((this._transmission > 0) != (value > 0)) {
			this.version++;
		}
		return this._transmission = value;
	}

	override public function copy(source:MeshPhysicalMaterial):MeshPhysicalMaterial {
		super.copy(source);
		this.defines = [
			'STANDARD' => '',
			'PHYSICAL' => ''
		];

		this.anisotropy = source.anisotropy;
		this.anisotropyRotation = source.anisotropyRotation;
		this.anisotropyMap = source.anisotropyMap;
		this.clearcoat = source.clearcoat;
		this.clearcoatMap = source.clearcoatMap;
		this.clearcoatRoughness = source.clearcoatRoughness;
		this.clearcoatRoughnessMap = source.clearcoatRoughnessMap;
		this.clearcoatNormalMap = source.clearcoatNormalMap;
		this.clearcoatNormalScale.copy(source.clearcoatNormalScale);
		this.dispersion = source.dispersion;
		this.ior = source.ior;
		this.iridescence = source.iridescence;
		this.iridescenceMap = source.iridescenceMap;
		this.iridescenceIOR = source.iridescenceIOR;
		this.iridescenceThicknessRange = source.iridescenceThicknessRange.copy();
		this.iridescenceThicknessMap = source.iridescenceThicknessMap;
		this.sheen = source.sheen;
		this.sheenColor.copy(source.sheenColor);
		this.sheenColorMap = source.sheenColorMap;
		this.sheenRoughness = source.sheenRoughness;
		this.sheenRoughnessMap = source.sheenRoughnessMap;
		this.transmission = source.transmission;
		this.transmissionMap = source.transmissionMap;
		this.thickness = source.thickness;
		this.thicknessMap = source.thicknessMap;
		this.attenuationDistance = source.attenuationDistance;
		this.attenuationColor.copy(source.attenuationColor);
		this.specularIntensity = source.specularIntensity;
		this.specularIntensityMap = source.specularIntensityMap;
		this.specularColor.copy(source.specularColor);
		this.specularColorMap = source.specularColorMap;

		return this;
	}
}