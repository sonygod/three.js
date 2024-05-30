import three.ShaderLib;
import three.ShaderMaterial;
import three.UniformsLib;
import three.UniformsUtils;
import three.Vector2;

class LineMaterial extends ShaderMaterial {

    public function new(parameters:Dynamic) {
        super({
            type: 'LineMaterial',
            uniforms: UniformsUtils.clone(ShaderLib['line'].uniforms),
            vertexShader: ShaderLib['line'].vertexShader,
            fragmentShader: ShaderLib['line'].fragmentShader,
            clipping: true // required for clipping support
        });

        this.isLineMaterial = true;
        this.setValues(parameters);
    }

    public function get color():Dynamic {
        return this.uniforms.diffuse.value;
    }

    public function set color(value:Dynamic):Void {
        this.uniforms.diffuse.value = value;
    }

    public function get worldUnits():Bool {
        return 'WORLD_UNITS' in this.defines;
    }

    public function set worldUnits(value:Bool):Void {
        if (value == true) {
            this.defines.WORLD_UNITS = '';
        } else {
            delete this.defines.WORLD_UNITS;
        }
    }

    public function get linewidth():Float {
        return this.uniforms.linewidth.value;
    }

    public function set linewidth(value:Float):Void {
        if (!this.uniforms.linewidth) return;
        this.uniforms.linewidth.value = value;
    }

    public function get dashed():Bool {
        return 'USE_DASH' in this.defines;
    }

    public function set dashed(value:Bool):Void {
        if ((value == true) != this.dashed) {
            this.needsUpdate = true;
        }

        if (value == true) {
            this.defines.USE_DASH = '';
        } else {
            delete this.defines.USE_DASH;
        }
    }

    public function get dashScale():Float {
        return this.uniforms.dashScale.value;
    }

    public function set dashScale(value:Float):Void {
        this.uniforms.dashScale.value = value;
    }

    public function get dashSize():Float {
        return this.uniforms.dashSize.value;
    }

    public function set dashSize(value:Float):Void {
        this.uniforms.dashSize.value = value;
    }

    public function get dashOffset():Float {
        return this.uniforms.dashOffset.value;
    }

    public function set dashOffset(value:Float):Void {
        this.uniforms.dashOffset.value = value;
    }

    public function get gapSize():Float {
        return this.uniforms.gapSize.value;
    }

    public function set gapSize(value:Float):Void {
        this.uniforms.gapSize.value = value;
    }

    public function get opacity():Float {
        return this.uniforms.opacity.value;
    }

    public function set opacity(value:Float):Void {
        if (!this.uniforms) return;
        this.uniforms.opacity.value = value;
    }

    public function get resolution():Vector2 {
        return this.uniforms.resolution.value;
    }

    public function set resolution(value:Vector2):Void {
        this.uniforms.resolution.value.copy(value);
    }

    public function get alphaToCoverage():Bool {
        return 'USE_ALPHA_TO_COVERAGE' in this.defines;
    }

    public function set alphaToCoverage(value:Bool):Void {
        if (!this.defines) return;

        if ((value == true) != this.alphaToCoverage) {
            this.needsUpdate = true;
        }

        if (value == true) {
            this.defines.USE_ALPHA_TO_COVERAGE = '';
        } else {
            delete this.defines.USE_ALPHA_TO_COVERAGE;
        }
    }
}