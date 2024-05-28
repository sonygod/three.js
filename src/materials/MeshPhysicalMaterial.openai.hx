package three.materials;

import three.math.Vector2;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.MathUtils;

class MeshPhysicalMaterial extends MeshStandardMaterial {
    public var isMeshPhysicalMaterial:Bool = true;

    public var defines:Dynamic = {
        STANDARD: '',
        PHYSICAL: ''
    };

    public var type:String = 'MeshPhysicalMaterial';

    public var anisotropyRotation:Float = 0;
    public var anisotropyMap:Null<Texture> = null;

    public var clearcoatMap:Null<Texture> = null;
    public var clearcoatRoughness:Float = 0.0;
    public var clearcoatRoughnessMap:Null<Texture> = null;
    public var clearcoatNormalScale:Vector2 = new Vector2(1, 1);
    public var clearcoatNormalMap:Null<Texture> = null;

    public var ior:Float = 1.5;

    private var _reflectivity:Float = MathUtils.clamp(2.5 * (ior - 1) / (ior + 1), 0, 1);

    public var iridescenceMap:Null<Texture> = null;
    public var iridescenceIOR:Float = 1.3;
    public var iridescenceThicknessRange:Array<Float> = [100, 400];
    public var iridescenceThicknessMap:Null<Texture> = null;

    public var sheenColor:Color = new Color(0x000000);
    public var sheenColorMap:Null<Texture> = null;
    public var sheenRoughness:Float = 1.0;
    public var sheenRoughnessMap:Null<Texture> = null;

    public var transmissionMap:Null<Texture> = null;

    public var thickness:Float = 0;
    public var thicknessMap:Null<Texture> = null;
    public var attenuationDistance:Float = Math.POSITIVE_INFINITY;
    public var attenuationColor:Color = new Color(1, 1, 1);

    public var specularIntensity:Float = 1.0;
    public var specularIntensityMap:Null<Texture> = null;
    public var specularColor:Color = new Color(1, 1, 1);
    public var specularColorMap:Null<Texture> = null;

    private var _anisotropy:Float = 0;
    private var _clearcoat:Float = 0;
    private var _dispersion:Float = 0;
    private var _iridescence:Float = 0;
    private var _sheen:Float = 0.0;
    private var _transmission:Float = 0;

    public function new(parameters:Dynamic = null) {
        super();

        this.setValues(parameters);
    }

    public var anisotropy(get, set):Float;

    private function get_anisotropy():Float {
        return _anisotropy;
    }

    private function set_anisotropy(value:Float):Float {
        if (_anisotropy > 0 != value > 0) {
            version++;
        }
        return _anisotropy = value;
    }

    public var clearcoat(get, set):Float;

    private function get_clearcoat():Float {
        return _clearcoat;
    }

    private function set_clearcoat(value:Float):Float {
        if (_clearcoat > 0 != value > 0) {
            version++;
        }
        return _clearcoat = value;
    }

    public var iridescence(get, set):Float;

    private function get_iridescence():Float {
        return _iridescence;
    }

    private function set_iridescence(value:Float):Float {
        if (_iridescence > 0 != value > 0) {
            version++;
        }
        return _iridescence = value;
    }

    public var dispersion(get, set):Float;

    private function get_dispersion():Float {
        return _dispersion;
    }

    private function set_dispersion(value:Float):Float {
        if (_dispersion > 0 != value > 0) {
            version++;
        }
        return _dispersion = value;
    }

    public var sheen(get, set):Float;

    private function get_sheen():Float {
        return _sheen;
    }

    private function set_sheen(value:Float):Float {
        if (_sheen > 0 != value > 0) {
            version++;
        }
        return _sheen = value;
    }

    public var transmission(get, set):Float;

    private function get_transmission():Float {
        return _transmission;
    }

    private function set_transmission(value:Float):Float {
        if (_transmission > 0 != value > 0) {
            version++;
        }
        return _transmission = value;
    }

    override public function copy(source:MeshPhysicalMaterial):MeshPhysicalMaterial {
        super.copy(source);

        defines = {
            STANDARD: '',
            PHYSICAL: ''
        };

        anisotropy = source.anisotropy;
        anisotropyRotation = source.anisotropyRotation;
        anisotropyMap = source.anisotropyMap;

        clearcoat = source.clearcoat;
        clearcoatMap = source.clearcoatMap;
        clearcoatRoughness = source.clearcoatRoughness;
        clearcoatRoughnessMap = source.clearcoatRoughnessMap;
        clearcoatNormalMap = source.clearcoatNormalMap;
        clearcoatNormalScale.copyFrom(source.clearcoatNormalScale);

        dispersion = source.dispersion;
        ior = source.ior;

        iridescence = source.iridescence;
        iridescenceMap = source.iridescenceMap;
        iridescenceIOR = source.iridescenceIOR;
        iridescenceThicknessRange = source.iridescenceThicknessRange.copy();
        iridescenceThicknessMap = source.iridescenceThicknessMap;

        sheen = source.sheen;
        sheenColor.copyFrom(source.sheenColor);
        sheenColorMap = source.sheenColorMap;
        sheenRoughness = source.sheenRoughness;
        sheenRoughnessMap = source.sheenRoughnessMap;

        transmission = source.transmission;
        transmissionMap = source.transmissionMap;

        thickness = source.thickness;
        thicknessMap = source.thicknessMap;
        attenuationDistance = source.attenuationDistance;
        attenuationColor.copyFrom(source.attenuationColor);

        specularIntensity = source.specularIntensity;
        specularIntensityMap = source.specularIntensityMap;
        specularColor.copyFrom(source.specularColor);
        specularColorMap = source.specularColorMap;

        return this;
    }
}