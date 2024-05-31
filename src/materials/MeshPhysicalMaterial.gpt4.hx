import three.math.Vector2;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.MathUtils;

class MeshPhysicalMaterial extends MeshStandardMaterial {
    
    public var isMeshPhysicalMaterial:Bool = true;
    
    public var defines:Map<String, String>;
    public var anisotropyRotation:Float = 0;
    public var anisotropyMap:Dynamic = null;
    
    public var clearcoatMap:Dynamic = null;
    public var clearcoatRoughness:Float = 0.0;
    public var clearcoatRoughnessMap:Dynamic = null;
    public var clearcoatNormalScale:Vector2 = new Vector2(1, 1);
    public var clearcoatNormalMap:Dynamic = null;
    
    public var ior:Float = 1.5;

    public var iridescenceMap:Dynamic = null;
    public var iridescenceIOR:Float = 1.3;
    public var iridescenceThicknessRange:Array<Float> = [100, 400];
    public var iridescenceThicknessMap:Dynamic = null;

    public var sheenColor:Color = new Color(0x000000);
    public var sheenColorMap:Dynamic = null;
    public var sheenRoughness:Float = 1.0;
    public var sheenRoughnessMap:Dynamic = null;

    public var transmissionMap:Dynamic = null;

    public var thickness:Float = 0;
    public var thicknessMap:Dynamic = null;
    public var attenuationDistance:Float = Math.POSITIVE_INFINITY;
    public var attenuationColor:Color = new Color(1, 1, 1);

    public var specularIntensity:Float = 1.0;
    public var specularIntensityMap:Dynamic = null;
    public var specularColor:Color = new Color(1, 1, 1);
    public var specularColorMap:Dynamic = null;

    private var _anisotropy:Float = 0;
    private var _clearcoat:Float = 0;
    private var _dispersion:Float = 0;
    private var _iridescence:Float = 0;
    private var _sheen:Float = 0.0;
    private var _transmission:Float = 0;

    public function new(parameters:Dynamic) {
        super();
        this.defines = new Map();
        this.defines.set('STANDARD', '');
        this.defines.set('PHYSICAL', '');
        this.type = 'MeshPhysicalMaterial';
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

    public function get_reflectivity():Float {
        return MathUtils.clamp(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
    }

    public function set_reflectivity(reflectivity:Float):Void {
        this.ior = (1 + 0.4 * reflectivity) / (1 - 0.4 * reflectivity);
    }

    public function copy(source:MeshPhysicalMaterial):MeshPhysicalMaterial {
        super.copy(source);

        this.defines.set('STANDARD', '');
        this.defines.set('PHYSICAL', '');

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