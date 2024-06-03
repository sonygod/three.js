import haxe.io.Bytes;
import three.math.Color;
import three.math.MathUtils;
import three.math.Vector2;
import three.materials.MeshStandardMaterial;

class MeshPhysicalMaterial extends MeshStandardMaterial {

	public var isMeshPhysicalMaterial:Bool = true;

	public var defines:Map<String,String> = new Map<String,String>([
		'STANDARD', '',
		'PHYSICAL', ''
	]);

	public var type:String = 'MeshPhysicalMaterial';

	public var anisotropyRotation:Float;
	public var anisotropyMap:Dynamic;

	public var clearcoatMap:Dynamic;
	public var clearcoatRoughness:Float = 0.0;
	public var clearcoatRoughnessMap:Dynamic;
	public var clearcoatNormalScale:Vector2 = new Vector2(1, 1);
	public var clearcoatNormalMap:Dynamic;

	public var ior:Float = 1.5;

	public var reflectivity:Float;

	public var iridescenceMap:Dynamic;
	public var iridescenceIOR:Float = 1.3;
	public var iridescenceThicknessRange:Array<Float> = [100, 400];
	public var iridescenceThicknessMap:Dynamic;

	public var sheenColor:Color = new Color(0x000000);
	public var sheenColorMap:Dynamic;
	public var sheenRoughness:Float = 1.0;
	public var sheenRoughnessMap:Dynamic;

	public var transmissionMap:Dynamic;

	public var thickness:Float = 0;
	public var thicknessMap:Dynamic;
	public var attenuationDistance:Float = Infinity;
	public var attenuationColor:Color = new Color(1, 1, 1);

	public var specularIntensity:Float = 1.0;
	public var specularIntensityMap:Dynamic;
	public var specularColor:Color = new Color(1, 1, 1);
	public var specularColorMap:Dynamic;

	private var _anisotropy:Float = 0;
	private var _clearcoat:Float = 0;
	private var _dispersion:Float = 0;
	private var _iridescence:Float = 0;
	private var _sheen:Float = 0.0;
	private var _transmission:Float = 0;

	public function new(parameters:Dynamic = null) {
		super();
		if (parameters != null) {
			this.setValues(parameters);
		}
	}

	public function get_anisotropy():Float {
		return this._anisotropy;
	}

	public function set_anisotropy(value:Float):Float {
		if (this._anisotropy > 0 != value > 0) {
			this.version++;
		}
		this._anisotropy = value;
		return value;
	}

	public function get_clearcoat():Float {
		return this._clearcoat;
	}

	public function set_clearcoat(value:Float):Float {
		if (this._clearcoat > 0 != value > 0) {
			this.version++;
		}
		this._clearcoat = value;
		return value;
	}

	public function get_iridescence():Float {
		return this._iridescence;
	}

	public function set_iridescence(value:Float):Float {
		if (this._iridescence > 0 != value > 0) {
			this.version++;
		}
		this._iridescence = value;
		return value;
	}

	public function get_dispersion():Float {
		return this._dispersion;
	}

	public function set_dispersion(value:Float):Float {
		if (this._dispersion > 0 != value > 0) {
			this.version++;
		}
		this._dispersion = value;
		return value;
	}

	public function get_sheen():Float {
		return this._sheen;
	}

	public function set_sheen(value:Float):Float {
		if (this._sheen > 0 != value > 0) {
			this.version++;
		}
		this._sheen = value;
		return value;
	}

	public function get_transmission():Float {
		return this._transmission;
	}

	public function set_transmission(value:Float):Float {
		if (this._transmission > 0 != value > 0) {
			this.version++;
		}
		this._transmission = value;
		return value;
	}

	public function copy(source:MeshPhysicalMaterial):MeshPhysicalMaterial {
		super.copy(source);

		this.defines = new Map<String,String>([
			'STANDARD', '',
			'PHYSICAL', ''
		]);

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
		this.iridescenceThicknessRange = [ ...source.iridescenceThicknessRange ];
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

	public function get_reflectivity():Float {
		return MathUtils.clamp(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
	}

	public function set_reflectivity(reflectivity:Float):Float {
		this.ior = (1 + 0.4 * reflectivity) / (1 - 0.4 * reflectivity);
		return reflectivity;
	}
}