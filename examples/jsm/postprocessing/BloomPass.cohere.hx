import js.three.WebGLRenderTarget;
import js.three.ShaderMaterial;
import js.three.AdditiveBlending;
import js.three.UniformsUtils;
import js.three.HalfFloatType;
import js.three.Vector2;

import js.three.Pass;
import js.three.FullScreenQuad;
import js.three.ConvolutionShader;

class BloomPass extends Pass {

    var renderTargetX:WebGLRenderTarget;
    var renderTargetY:WebGLRenderTarget;
    var materialCombine:ShaderMaterial;
    var materialConvolution:ShaderMaterial;
    var combineUniforms:Dynamic;
    var convolutionUniforms:Dynamic;
    var fsQuad:FullScreenQuad;

    public function new(strength:Float = 1., kernelSize:Int = 25, sigma:Float = 4.) {
        super();

        renderTargetX = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        renderTargetX.texture.name = 'BloomPass.x';
        renderTargetY = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        renderTargetY.texture.name = 'BloomPass.y';

        combineUniforms = js.threelabs.UniformsUtils.clone(CombineShader.uniforms);
        combineUniforms.strength.value = strength;
        materialCombine = new ShaderMaterial({
            name: CombineShader.name,
            uniforms: combineUniforms,
            vertexShader: CombineShader.vertexShader,
            fragmentShader: CombineShader.fragmentShader,
            blending: AdditiveBlending,
            transparent: true
        });

        convolutionUniforms = js.threelabs.UniformsUtils.clone(ConvolutionShader.uniforms);
        convolutionUniforms.uImageIncrement.value = BloomPass.blurX;
        convolutionUniforms.cKernel.value = ConvolutionShader.buildKernel(sigma);
        materialConvolution = new ShaderMaterial({
            name: ConvolutionShader.name,
            uniforms: convolutionUniforms,
            vertexShader: ConvolutionShader.vertexShader,
            fragmentShader: ConvolutionShader.fragmentShader,
            defines: {
                'KERNEL_SIZE_FLOAT': kernelSize.toFloat().toFixed(1),
                'KERNEL_SIZE_INT': kernelSize.toString()
            }
        });

        fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer, writeBuffer, readBuffer, deltaTime, maskActive) {
        if (maskActive) renderer.state.buffers.stencil.setTest(false);

        // Render quad with blurred scene into texture (convolution pass 1)
        fsQuad.material = materialConvolution;
        convolutionUniforms.tDiffuse.value = readBuffer.texture;
        convolutionUniforms.uImageIncrement.value = BloomPass.blurX;

        renderer.setRenderTarget(renderTargetX);
        renderer.clear();
        fsQuad.render(renderer);

        // Render quad with blurred scene into texture (convolution pass 2)
        convolutionUniforms.tDiffuse.value = renderTargetX.texture;
        convolutionUniforms.uImageIncrement.value = BloomPass.blurY;

        renderer.setRenderTarget(renderTargetY);
        renderer.clear();
        fsQuad.render(renderer);

        // Render original scene with superimposed blur to texture
        fsQuad.material = materialCombine;
        combineUniforms.tDiffuse.value = renderTargetY.texture;

        if (maskActive) renderer.state.buffers.stencil.setTest(true);

        renderer.setRenderTarget(readBuffer);
        if (this.clear) renderer.clear();
        fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int):Void {
        renderTargetX.setSize(width, height);
        renderTargetY.setSize(width, height);
    }

    public function dispose():Void {
        renderTargetX.dispose();
        renderTargetY.dispose();
        materialCombine.dispose();
        materialConvolution.dispose();
        fsQuad.dispose();
    }
}

class CombineShader {
    public static var name:String = 'CombineShader';
    public static var uniforms:Dynamic = {
        tDiffuse: { value: null },
        strength: { value: 1.0 }
    };
    public static var vertexShader:String = '''
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ''';
    public static var fragmentShader:String = '''
        uniform float strength;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = strength * texel;
        }
    ''';
}

static var blurX = new Vector2(0.001953125, 0.0);
static var blurY = new Vector2(0.0, 0.001953125);