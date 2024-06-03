import three.ShaderLib;
import three.ShaderMaterial;
import three.UniformsLib;
import three.UniformsUtils;
import three.Vector2;
import three.Vector3;
import three.Color;

class LineMaterial extends ShaderMaterial {

    public var color:Color;
    public var worldUnits(default, null):Bool;
    public var linewidth(default, 1.0):Float;
    public var dashed(default, null):Bool;
    public var dashScale(default, 1.0):Float;
    public var dashSize(default, 1.0):Float;
    public var dashOffset(default, 0.0):Float;
    public var gapSize(default, 1.0):Float;
    public var opacity(default, 1.0):Float;
    public var resolution:Vector2;
    public var alphaToCoverage(default, null):Bool;

    public function new(parameters:Dynamic = null) {
        super({
            type: 'LineMaterial',
            uniforms: UniformsUtils.clone(ShaderLib['line'].uniforms),
            vertexShader: ShaderLib['line'].vertexShader,
            fragmentShader: ShaderLib['line'].fragmentShader,
            clipping: true
        });

        this.isLineMaterial = true;

        if (parameters != null) {
            this.setValues(parameters);
        }
    }

    public function set color(value:Color) {
        this.uniforms.diffuse.value = value;
    }

    public function get color():Color {
        return this.uniforms.diffuse.value;
    }

    public function set worldUnits(value:Bool) {
        if (value) {
            this.defines['WORLD_UNITS'] = '';
        } else {
            this.defines.remove('WORLD_UNITS');
        }
    }

    public function get worldUnits():Bool {
        return this.defines.exists('WORLD_UNITS');
    }

    public function set linewidth(value:Float) {
        this.uniforms.linewidth.value = value;
    }

    public function get linewidth():Float {
        return this.uniforms.linewidth.value;
    }

    public function set dashed(value:Bool) {
        if (value != this.dashed) {
            this.needsUpdate = true;
        }
        if (value) {
            this.defines['USE_DASH'] = '';
        } else {
            this.defines.remove('USE_DASH');
        }
    }

    public function get dashed():Bool {
        return this.defines.exists('USE_DASH');
    }

    public function set dashScale(value:Float) {
        this.uniforms.dashScale.value = value;
    }

    public function get dashScale():Float {
        return this.uniforms.dashScale.value;
    }

    public function set dashSize(value:Float) {
        this.uniforms.dashSize.value = value;
    }

    public function get dashSize():Float {
        return this.uniforms.dashSize.value;
    }

    public function set dashOffset(value:Float) {
        this.uniforms.dashOffset.value = value;
    }

    public function get dashOffset():Float {
        return this.uniforms.dashOffset.value;
    }

    public function set gapSize(value:Float) {
        this.uniforms.gapSize.value = value;
    }

    public function get gapSize():Float {
        return this.uniforms.gapSize.value;
    }

    public function set opacity(value:Float) {
        this.uniforms.opacity.value = value;
    }

    public function get opacity():Float {
        return this.uniforms.opacity.value;
    }

    public function set resolution(value:Vector2) {
        this.uniforms.resolution.value.copy(value);
    }

    public function get resolution():Vector2 {
        return this.uniforms.resolution.value;
    }

    public function set alphaToCoverage(value:Bool) {
        if (value != this.alphaToCoverage) {
            this.needsUpdate = true;
        }
        if (value) {
            this.defines['USE_ALPHA_TO_COVERAGE'] = '';
        } else {
            this.defines.remove('USE_ALPHA_TO_COVERAGE');
        }
    }

    public function get alphaToCoverage():Bool {
        return this.defines.exists('USE_ALPHA_TO_COVERAGE');
    }
}