import three.math.Vector2;
import three.materials.MeshStandardMaterial;
import three.math.Color;
import three.math.MathUtils;

class MeshPhysicalMaterial extends MeshStandardMaterial {

    public var isMeshPhysicalMaterial: Bool = true;

    public var defines: Map<String, String> = new Map<String, String>();

    public var type: String = "MeshPhysicalMaterial";

    public var anisotropyRotation: Float = 0;
    public var anisotropyMap: Dynamic;

    public var clearcoatMap: Dynamic;
    public var clearcoatRoughness: Float = 0.0;
    public var clearcoatRoughnessMap: Dynamic;
    public var clearcoatNormalScale: Vector2 = new Vector2(1, 1);
    public var clearcoatNormalMap: Dynamic;

    public var ior: Float = 1.5;

    public var iridescenceMap: Dynamic;
    public var iridescenceIOR: Float = 1.3;
    public var iridescenceThicknessRange: Array<Float> = [100, 400];
    public var iridescenceThicknessMap: Dynamic;

    public var sheenColor: Color = new Color(0x000000);
    public var sheenColorMap: Dynamic;
    public var sheenRoughness: Float = 1.0;
    public var sheenRoughnessMap: Dynamic;

    public var transmissionMap: Dynamic;

    public var thickness: Float = 0;
    public var thicknessMap: Dynamic;
    public var attenuationDistance: Float = Float.POSITIVE_INFINITY;
    public var attenuationColor: Color = new Color(1, 1, 1);

    public var specularIntensity: Float = 1.0;
    public var specularIntensityMap: Dynamic;
    public var specularColor: Color = new Color(1, 1, 1);
    public var specularColorMap: Dynamic;

    private var _anisotropy: Float = 0;
    private var _clearcoat: Float = 0;
    private var _dispersion: Float = 0;
    private var _iridescence: Float = 0;
    private var _sheen: Float = 0.0;
    private var _transmission: Float = 0;

    public function new(parameters: Dynamic) {
        super();

        defines.set('STANDARD', '');
        defines.set('PHYSICAL', '');

        setValues(parameters);
    }

    public function get_reflectivity(): Float {
        return MathUtils.clamp(2.5 * (ior - 1) / (ior + 1), 0, 1);
    }

    public function set_reflectivity(reflectivity: Float): Void {
        ior = (1 + 0.4 * reflectivity) / (1 - 0.4 * reflectivity);
    }

    public function get_anisotropy(): Float {
        return _anisotropy;
    }

    public function set_anisotropy(value: Float): Void {
        if (this._anisotropy > 0 != value > 0) {
            this.version++;
        }

        this._anisotropy = value;
    }

    // Repeat the same pattern for clearcoat, iridescence, dispersion, sheen, transmission

    public function copy(source: MeshPhysicalMaterial): MeshPhysicalMaterial {
        super.copy(source);

        defines.set('STANDARD', '');
        defines.set('PHYSICAL', '');

        anisotropy = source.anisotropy;
        anisotropyRotation = source.anisotropyRotation;
        anisotropyMap = source.anisotropyMap;

        // Repeat the same pattern for the other properties

        return this;
    }
}