import Vector2 from '../math/Vector2.hx';
import MeshStandardMaterial from './MeshStandardMaterial.hx';
import Color from '../math/Color.hx';
import MathUtils from '../math/MathUtils.hx';

class MeshPhysicalMaterial extends MeshStandardMaterial {
    public isMeshPhysicalMaterial: Bool;
    public var defines: { [key: String]: String };
    public var type: String;
    public var anisotropyRotation: Float;
    public var anisotropyMap: Dynamic;
    public var clearcoatMap: Dynamic;
    public var clearcoatRoughness: Float;
    public var clearcoatRoughnessMap: Dynamic;
    public var clearcoatNormalScale: Vector2;
    public var clearcoatNormalMap: Dynamic;
    public var ior: Float;
    public var reflectivity: Float;
    public var iridescenceMap: Dynamic;
    public var iridescenceIOR: Float;
    public var iridescenceThicknessRange: Array<Int>;
    public var iridescenceThicknessMap: Dynamic;
    public var sheenColor: Color;
    public var sheenColorMap: Dynamic;
    public var sheenRoughness: Float;
    public var sheenRoughnessMap: Dynamic;
    public var transmissionMap: Dynamic;
    public var thickness: Float;
    public var thicknessMap: Dynamic;
    public var attenuationDistance: Float;
    public var attenuationColor: Color;
    public var specularIntensity: Float;
    public var specularIntensityMap: Dynamic;
    public var specularColor: Color;
    public var specularColorMap: Dynamic;
    public var _anisotropy: Float;
    public var _clearcoat: Float;
    public var _dispersion: Float;
    public var _iridescence: Float;
    public var _sheen: Float;
    public var _transmission: Float;

    public function new(parameters: { [key: String]: Dynamic } = null) {
        super();
        this.isMeshPhysicalMaterial = true;
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
        this.clearcoatNormalScale = new Vector2(1, 1);
        this.clearcoatNormalMap = null;
        this.ior = 1.5;
        this.reflectivity = MathUtils.clamp(2.5 * (this.ior - 1) / (this.ior + 1), 0, 1);
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
        this.attenuationDistance = Infinity;
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
        if (parameters != null) {
            this.setValues(parameters);
        }
    }

    public function set anisotropy(value: Float) {
        if (this._anisotropy > 0 != value > 0) {
            this.version++;
        }
        this._anisotropy = value;
    }

    public function get anisotropy(): Float {
        return this._anisotropy;
    }

    public function set clearcoat(value: Float) {
        if (this._clearcoat > 0 != value > 0) {
            this.version++;
        }
        this._clearcoat = value;
    }

    public function get clearcoat(): Float {
        return this._clearcoat;
    }

    public function set iridescence(value: Float) {
        if (this._iridescence > 0 != value > 0) {
            this.version++;
        }
        this._iridescence = value;
    }

    public function get iridescence(): Float {
        return this._iridescence;
    }

    public function set dispersion(value: Float) {
        if (this._dispersion > 0 != value > 0) {
            this.version++;
        }
        this._dispersion = value;
    }

    public function get dispersion(): Float {
        return this._dispersion;
    }

    public function set sheen(value: Float) {
        if (this._sheen > 0 != value > 0) {
            this.version++;
        }
        this._sheen = value;
    }

    public function get sheen(): Float {
        return this._sheen;
    }

    public function set transmission(value: Float) {
        if (this._transmission > 0 != value > 0) {
            this.version++;
        }
        this._transmission = value;
    }

    public function get transmission(): Float {
        return this._transmission;
    }

    public function copy(source: MeshPhysicalMaterial) {
        super.copy(source);
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
        this.clearcoatNormalScale.copy(source.clearcoatNormalScale);
        this.dispersion = source.dispersion;
        this.ior = source.ior;
        this.iridescence = source.iridescence;
        this.iridescenceMap = source.iridescenceMap;
        this.iridescenceIOR = source.iridescenceIOR;
        this.iridescenceThicknessRange = source.iridescenceThicknessRange.slice();
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

export { MeshPhysicalMaterial };