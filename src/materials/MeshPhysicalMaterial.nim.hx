import three.math.Vector2;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.MathUtils;

class MeshPhysicalMaterial extends MeshStandardMaterial {

	public var isMeshPhysicalMaterial:Bool = true;

	public var defines:Map<String, String> = {
		'STANDARD': '',
		'PHYSICAL': ''
	};

	public var type:String = 'MeshPhysicalMaterial';

	public var anisotropyRotation:Float = 0;
	public var anisotropyMap:Null<Dynamic> = null;

	public var clearcoatMap:Null<Dynamic> = null;
	public var clearcoatRoughness:Float = 0.0;
	public var clearcoatRoughnessMap:Null<Dynamic> = null;
	public var clearcoatNormalScale:Vector2 = new Vector2( 1, 1 );
	public var clearcoatNormalMap:Null<Dynamic> = null;

	public var ior:Float = 1.5;

	private var _reflectivity:Float;
	public function get reflectivity():Float {
		return _reflectivity;
	}
	public function set reflectivity(value:Float) {
		_reflectivity = value;
		this.ior = ( 1 + 0.4 * _reflectivity ) / ( 1 - 0.4 * _reflectivity );
	}

	public var iridescenceMap:Null<Dynamic> = null;
	public var iridescenceIOR:Float = 1.3;
	public var iridescenceThicknessRange:Array<Float> = [ 100, 400 ];
	public var iridescenceThicknessMap:Null<Dynamic> = null;

	public var sheenColor:Color = new Color( 0x000000 );
	public var sheenColorMap:Null<Dynamic> = null;
	public var sheenRoughness:Float = 1.0;
	public var sheenRoughnessMap:Null<Dynamic> = null;

	public var transmissionMap:Null<Dynamic> = null;

	public var thickness:Float = 0;
	public var thicknessMap:Null<Dynamic> = null;
	public var attenuationDistance:Float = Infinity;
	public var attenuationColor:Color = new Color( 1, 1, 1 );

	public var specularIntensity:Float = 1.0;
	public var specularIntensityMap:Null<Dynamic> = null;
	public var specularColor:Color = new Color( 1, 1, 1 );
	public var specularColorMap:Null<Dynamic> = null;

	private var _anisotropy:Float = 0;
	public function get anisotropy():Float {
		return _anisotropy;
	}
	public function set anisotropy(value:Float) {
		if ( _anisotropy > 0 !== value > 0 ) {
			this.version ++;
		}
		_anisotropy = value;
	}

	private var _clearcoat:Float = 0;
	public function get clearcoat():Float {
		return _clearcoat;
	}
	public function set clearcoat(value:Float) {
		if ( _clearcoat > 0 !== value > 0 ) {
			this.version ++;
		}
		_clearcoat = value;
	}

	private var _iridescence:Float = 0;
	public function get iridescence():Float {
		return _iridescence;
	}
	public function set iridescence(value:Float) {
		if ( _iridescence > 0 !== value > 0 ) {
			this.version ++;
		}
		_iridescence = value;
	}

	private var _dispersion:Float = 0;
	public function get dispersion():Float {
		return _dispersion;
	}
	public function set dispersion(value:Float) {
		if ( _dispersion > 0 !== value > 0 ) {
			this.version ++;
		}
		_dispersion = value;
	}

	private var _sheen:Float = 0.0;
	public function get sheen():Float {
		return _sheen;
	}
	public function set sheen(value:Float) {
		if ( _sheen > 0 !== value > 0 ) {
			this.version ++;
		}
		_sheen = value;
	}

	private var _transmission:Float = 0;
	public function get transmission():Float {
		return _transmission;
	}
	public function set transmission(value:Float) {
		if ( _transmission > 0 !== value > 0 ) {
			this.version ++;
		}
		_transmission = value;
	}

	public function new(parameters:Map<String, Dynamic>) {
		super();

		this.defines = {
			'STANDARD': '',
			'PHYSICAL': ''
		};

		this.type = 'MeshPhysicalMaterial';

		this.anisotropyRotation = 0;
		this.anisotropyMap = null;

		this.clearcoatMap = null;
		this.clearcoatRoughness = 0.0;
		this.clearcoatRoughnessMap = null;
		this.clearcoatNormalScale = new Vector2( 1, 1 );
		this.clearcoatNormalMap = null;

		this.ior = 1.5;

		this.iridescenceMap = null;
		this.iridescenceIOR = 1.3;
		this.iridescenceThicknessRange = [ 100, 400 ];
		this.iridescenceThicknessMap = null;

		this.sheenColor = new Color( 0x000000 );
		this.sheenColorMap = null;
		this.sheenRoughness = 1.0;
		this.sheenRoughnessMap = null;

		this.transmissionMap = null;

		this.thickness = 0;
		this.thicknessMap = null;
		this.attenuationDistance = Infinity;
		this.attenuationColor = new Color( 1, 1, 1 );

		this.specularIntensity = 1.0;
		this.specularIntensityMap = null;
		this.specularColor = new Color( 1, 1, 1 );
		this.specularColorMap = null;

		this._anisotropy = 0;
		this._clearcoat = 0;
		this._dispersion = 0;
		this._iridescence = 0;
		this._sheen = 0.0;
		this._transmission = 0;

		this.setValues( parameters );
	}

	public function copy(source:MeshPhysicalMaterial):MeshPhysicalMaterial {
		super.copy( source );

		this.defines = {
			'STANDARD': '',
			'PHYSICAL': ''
		};

		this.anisotropy = source.anisotropy;
		this.anisotropyRotation = source.anisotropyRotation;
		this.anisotropyMap = source.anisotropyMap;

		this.clearcoat = source.clearcoat;
		this.clearcoatMap = source.clearcoatMap;
		this.clearcoatRoughness = source.clearcoatRoughness;
		this.clearcoatRoughnessMap = source.clearcoatRoughnessMap;
		this.clearcoatNormalMap = source.clearcoatNormalMap;
		this.clearcoatNormalScale.copy( source.clearcoatNormalScale );

		this.dispersion = source.dispersion;
		this.ior = source.ior;

		this.iridescence = source.iridescence;
		this.iridescenceMap = source.iridescenceMap;
		this.iridescenceIOR = source.iridescenceIOR;
		this.iridescenceThicknessRange = [ ...source.iridescenceThicknessRange ];
		this.iridescenceThicknessMap = source.iridescenceThicknessMap;

		this.sheen = source.sheen;
		this.sheenColor.copy( source.sheenColor );
		this.sheenColorMap = source.sheenColorMap;
		this.sheenRoughness = source.sheenRoughness;
		this.sheenRoughnessMap = source.sheenRoughnessMap;

		this.transmission = source.transmission;
		this.transmissionMap = source.transmissionMap;

		this.thickness = source.thickness;
		this.thicknessMap = source.thicknessMap;
		this.attenuationDistance = source.attenuationDistance;
		this.attenuationColor.copy( source.attenuationColor );

		this.specularIntensity = source.specularIntensity;
		this.specularIntensityMap = source.specularIntensityMap;
		this.specularColor.copy( source.specularColor );
		this.specularColorMap = source.specularColorMap;

		return this;
	}

}