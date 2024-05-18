import three.core.UniformsLib;
import three.math.Vector2;
import three.shaders.ShaderLib;
import three.shaders.UniformsUtils;

class LineMaterial extends three.ShaderMaterial {

    public var worldUnits:Bool;
    public var linewidth:Float;
    public var resolution:Vector2;
    public var dashOffset:Float;
    public var dashScale:Float;
    public var dashSize:Float;
    public var gapSize:Float;

    public function new(parameters:Dynamic = null) {
        super(createUniforms());

        this.isLineMaterial = true;

        this.setValues(parameters);
    }

    private static function createUniforms():Dynamic {
        return UniformsUtils.merge([
            UniformsLib.common,
            UniformsLib.fog,
            UniformsLib.line
        ]);
    }

    public function get color():three.Vector3 {
        return this.uniforms.diffuse.value;
    }

    public function set color(value:three.Vector3) {
        this.uniforms.diffuse.value = value;
    }

    public function get worldUnits():Bool {
        return 'WORLD_UNITS' in this.defines;
    }

    public function set worldUnits(value:Bool) {
        if (value === true) {
            this.defines.WORLD_UNITS = '';
        } else {
            delete this.defines.WORLD_UNITS;
        }
    }

    public function get linewidth():Float {
        return this.uniforms.linewidth.value;
    }

    public function set linewidth(value:Float) {
        if (this.uniforms.linewidth != null) {
            this.uniforms.linewidth.value = value;
        }
    }

    public function get dashed():Bool {
        return 'USE_DASH' in this.defines;
    }

    public function set dashed(value:Bool) {
        if ((value === true) !== this.dashed) {
            this.needsUpdate = true;
        }

        if (value === true) {
            this.defines.USE_DASH = '';
        } else {
            delete this.defines.USE_DASH;
        }
    }

    public function get dashScale():Float {
        return this.uniforms.dashScale.value;
    }

    public function set dashScale(value:Float) {
        this.uniforms.dashScale.value = value;
    }

    public function get dashSize():Float {
        return this.uniforms.dashSize.value;
    }

    public function set dashSize(value:Float) {
        this.uniforms.dashSize.value = value;
    }

    public function get dashOffset():Float {
        return this.uniforms.dashOffset.value;
    }

    public function set dashOffset(value:Float) {
        this.uniforms.dashOffset.value = value;
    }

    public function get gapSize():Float {
        return this.uniforms.gapSize.value;
    }

    public function set gapSize(value:Float) {
        this.uniforms.gapSize.value = value;
    }

    public function get opacity():Float {
        return this.uniforms.opacity.value;
    }

    public function set opacity(value:Float) {
        if (this.uniforms != null) {
            this.uniforms.opacity.value = value;
        }
    }

    public function get resolution():Vector2 {
        return this.uniforms.resolution.value;
    }

    public function set resolution(value:Vector2) {
        this.uniforms.resolution.value.copy(value);
    }

    public function get alphaToCoverage():Bool {
        return 'USE_ALPHA_TO_COVERAGE' in this.defines;
    }

    public function set alphaToCoverage(value:Bool) {
        if (!this.defines) return;

        if ((value === true) !== this.alphaToCoverage) {
            this.needsUpdate = true;
        }

        if (value === true) {
            this.defines.USE_ALPHA_TO_COVERAGE = '';
        } else {
            delete this.defines.USE_ALPHA_TO_COVERAGE;
        }
    }
}