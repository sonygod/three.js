import js.three.DataTexture;
import js.three.Math as MathUtils;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.WebGLFloatType;
import js.three.WebGLRedFormat;

import js.three.Pass;
import js.three.FullScreenQuad;
import js.three.DigitalGlitch;

class GlitchPass extends Pass {
    public var heightMap:DataTexture;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var goWild:Bool;
    public var curF:Int;
    public var randX:Int;

    public function new(dt_size:Int = 64) {
        super();
        var shader = DigitalGlitch;
        uniforms = UniformsUtils.clone(shader.uniforms);
        heightMap = generateHeightmap(dt_size);
        uniforms['tDisp'].value = heightMap;
        material = ShaderMaterial({
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });
        fsQuad = FullScreenQuad(material);
        goWild = false;
        curF = 0;
        generateTrigger();
    }

    public function render(renderer, writeBuffer, readBuffer:Dynamic /*, deltaTime, maskActive */) {
        uniforms['tDiffuse'].value = readBuffer.texture;
        uniforms['seed'].value = Math.random(); // default seeding
        uniforms['byp'].value = 0;

        if (curF % randX == 0 || goWild) {
            uniforms['amount'].value = Math.random() / 30;
            uniforms['angle'].value = MathUtils.randFloat(-Math.PI, Math.PI);
            uniforms['seed_x'].value = MathUtils.randFloat(-1, 1);
            uniforms['seed_y'].value = MathUtils.randFloat(-1, 1);
            uniforms['distortion_x'].value = MathUtils.randFloat(0, 1);
            uniforms['distortion_y'].value = MathUtils.randFloat(0, 1);
            curF = 0;
            generateTrigger();
        } else if (curF % randX < randX / 5) {
            uniforms['amount'].value = Math.random() / 90;
            uniforms['angle'].value = MathUtils.randFloat(-Math.PI, Math.PI);
            uniforms['distortion_x'].value = MathUtils.randFloat(0, 1);
            uniforms['distortion_y'].value = MathUtils.randFloat(0, 1);
            uniforms['seed_x'].value = MathUtils.randFloat(-0.3, 0.3);
            uniforms['seed_y'].value = MathUtils.randFloat(-0.3, 0.3);
        } else if (!goWild) {
            uniforms['byp'].value = 1;
        }

        curF++;

        if (renderToScreen) {
            renderer.setRenderTarget(null);
            fsQuad.render(renderer);
        } else {
            renderer.setRenderTarget(writeBuffer);
            if (clear) renderer.clear();
            fsQuad.render(renderer);
        }
    }

    public function generateTrigger() {
        randX = MathUtils.randInt(120, 240);
    }

    public function generateHeightmap(dt_size:Int):DataTexture {
        var data_arr = new Float32Array(dt_size * dt_size);
        var length = dt_size * dt_size;
        var i = 0;
        while (i < length) {
            data_arr[i] = MathUtils.randFloat(0, 1);
            i++;
        }
        var texture = DataTexture(data_arr, dt_size, dt_size, WebGLRedFormat, WebGLFloatType);
        texture.needsUpdate = true;
        return texture;
    }

    public function dispose() {
        material.dispose();
        heightMap.dispose();
        fsQuad.dispose();
    }
}

class DigitalGlitch {
    public static var uniforms:Dynamic;
    public static var vertexShader:String;
    public static var fragmentShader:String;
}