Here is the converted Haxe code:
```
package three.js.examples.jsm.postprocessing;

import three.DataTexture;
import three.FloatType;
import three.MathUtils;
import three.RedFormat;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Pass;
import three.FullScreenQuad;
import shaders.DigitalGlitch;

class GlitchPass extends Pass {

    public var dt_size:Int;
    public var goWild:Bool;
    public var curF:Int;
    public var randX:Int;
    public var uniforms:Dynamic;
    public var material:ShaderMaterial;
    public var fsQuad:FullScreenQuad;
    public var heightMap:DataTexture;

    public function new(?dt_size:Int = 64) {
        super();

        var shader:Dynamic = DigitalGlitch;

        uniforms = UniformsUtils.clone(shader.uniforms);

        heightMap = generateHeightmap(dt_size);

        uniforms['tDisp'].value = heightMap;

        material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader
        });

        fsQuad = new FullScreenQuad(material);

        goWild = false;
        curF = 0;
        generateTrigger();
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic /*, deltaTime:Float, maskActive:Bool */ ) {
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

    private function generateTrigger() {
        randX = MathUtils.randInt(120, 240);
    }

    private function generateHeightmap(dt_size:Int):DataTexture {
        var data_arr:Array<Float> = new Array<Float>();
        for (i in 0...dt_size * dt_size) {
            var val:Float = MathUtils.randFloat(0, 1);
            data_arr.push(val);
        }

        var texture:DataTexture = new DataTexture(data_arr, dt_size, dt_size, RedFormat, FloatType);
        texture.needsUpdate = true;
        return texture;
    }

    public function dispose() {
        material.dispose();
        heightMap.dispose();
        fsQuad.dispose();
    }
}

// export class
@:keep
@:expose
class GlitchPassExport {
    public static function main() {
        // do nothing, this is just to expose the class
    }
}
```
Note that I've used the `Dynamic` type to represent the `shader` variable, as it's not clear what type it should be. You may need to adjust this depending on the actual type of the `DigitalGlitch` shader. Additionally, I've kept the `Pass` and `FullScreenQuad` classes as is, assuming they are part of the `three` library. If this is not the case, you may need to modify the code accordingly.