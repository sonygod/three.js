package three.js.examples.jsm.lines;

import three.js.Lib;
import three.js_math.Vector2;

class LineMaterial extends ShaderMaterial {
    public function new(parameters:Dynamic) {
        super({
            type: 'LineMaterial',
            uniforms: UniformsUtils.clone(ShaderLib.line.uniforms),
            vertexShader: ShaderLib.line.vertexShader,
            fragmentShader: ShaderLib.line.fragmentShader,
            clipping: true // required for clipping support
        });
        this.isLineMaterial = true;
        this.setValues(parameters);
    }

    public var isLineMaterial: Bool;

    public function get_color(): Vector3 {
        return this.uniforms.diffuse.value;
    }

    public function set_color(value: Vector3) {
        this.uniforms.diffuse.value = value;
    }

    public function get_worldUnits(): Bool {
        return 'WORLD_UNITS' in this.defines;
    }

    public function set_worldUnits(value: Bool) {
        if (value) {
            this.defines.WORLD_UNITS = '';
        } else {
            delete this.defines.WORLD_UNITS;
        }
    }

    public function get_linewidth(): Float {
        return this.uniforms.linewidth.value;
    }

    public function set_linewidth(value: Float) {
        if (!this.uniforms.linewidth) return;
        this.uniforms.linewidth.value = value;
    }

    public function get_dashed(): Bool {
        return 'USE_DASH' in this.defines;
    }

    public function set_dashed(value: Bool) {
        if ((value === true) !== this.dashed) {
            this.needsUpdate = true;
        }
        if (value) {
            this.defines.USE_DASH = '';
        } else {
            delete this.defines.USE_DASH;
        }
    }

    public function get_dashScale(): Float {
        return this.uniforms.dashScale.value;
    }

    public function set_dashScale(value: Float) {
        this.uniforms.dashScale.value = value;
    }

    public function get_dashSize(): Float {
        return this.uniforms.dashSize.value;
    }

    public function set_dashSize(value: Float) {
        this.uniforms.dashSize.value = value;
    }

    public function get_gapSize(): Float {
        return this.uniforms.gapSize.value;
    }

    public function set_gapSize(value: Float) {
        this.uniforms.gapSize.value = value;
    }

    public function get_opacity(): Float {
        return this.uniforms.opacity.value;
    }

    public function set_opacity(value: Float) {
        if (!this.uniforms) return;
        this.uniforms.opacity.value = value;
    }

    public function get_resolution(): Vector2 {
        return this.uniforms.resolution.value;
    }

    public function set_resolution(value: Vector2) {
        this.uniforms.resolution.value.copy(value);
    }

    public function get_alphaToCoverage(): Bool {
        return 'USE_ALPHA_TO_COVERAGE' in this.defines;
    }

    public function set_alphaToCoverage(value: Bool) {
        if (!this.defines) return;
        if ((value === true) !== this.alphaToCoverage) {
            this.needsUpdate = true;
        }
        if (value) {
            this.defines.USE_ALPHA_TO_COVERAGE = '';
        } else {
            delete this.defines.USE_ALPHA_TO_COVERAGE;
        }
    }
}