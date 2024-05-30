import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;
import three.examples.jsm.shaders.ConvolutionShader;
import three.AdditiveBlending;
import three.HalfFloatType;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector2;
import three.WebGLRenderTarget;

class BloomPass extends Pass {
    public var renderTargetX:WebGLRenderTarget;
    public var renderTargetY:WebGLRenderTarget;
    public var combineUniforms:Dynamic;
    public var materialCombine:ShaderMaterial;
    public var convolutionUniforms:Dynamic;
    public var materialConvolution:ShaderMaterial;
    public var fsQuad:FullScreenQuad;

    public function new(strength:Float = 1, kernelSize:Int = 25, sigma:Float = 4) {
        super();

        // render targets
        this.renderTargetX = new WebGLRenderTarget(1, 1, {type: HalfFloatType});
        this.renderTargetX.texture.name = 'BloomPass.x';
        this.renderTargetY = new WebGLRenderTarget(1, 1, {type: HalfFloatType});
        this.renderTargetY.texture.name = 'BloomPass.y';

        // combine material
        this.combineUniforms = UniformsUtils.clone(CombineShader.uniforms);
        this.combineUniforms['strength'].value = strength;
        this.materialCombine = new ShaderMaterial({
            name: CombineShader.name,
            uniforms: this.combineUniforms,
            vertexShader: CombineShader.vertexShader,
            fragmentShader: CombineShader.fragmentShader,
            blending: AdditiveBlending,
            transparent: true
        });

        // convolution material
        const convolutionShader = ConvolutionShader;
        this.convolutionUniforms = UniformsUtils.clone(convolutionShader.uniforms);
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;
        this.convolutionUniforms['cKernel'].value = ConvolutionShader.buildKernel(sigma);
        this.materialConvolution = new ShaderMaterial({
            name: convolutionShader.name,
            uniforms: this.convolutionUniforms,
            vertexShader: convolutionShader.vertexShader,
            fragmentShader: convolutionShader.fragmentShader,
            defines: {
                'KERNEL_SIZE_FLOAT': kernelSize.toFixed(1),
                'KERNEL_SIZE_INT': kernelSize.toFixed(0)
            }
        });

        this.needsSwap = false;
        this.fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic, deltaTime:Float, maskActive:Bool) {
        if (maskActive) renderer.state.buffers.stencil.setTest(false);

        // Render quad with blured scene into texture (convolution pass 1)
        this.fsQuad.material = this.materialConvolution;
        this.convolutionUniforms['tDiffuse'].value = readBuffer.texture;
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;
        renderer.setRenderTarget(this.renderTargetX);
        renderer.clear();
        this.fsQuad.render(renderer);

        // Render quad with blured scene into texture (convolution pass 2)
        this.convolutionUniforms['tDiffuse'].value = this.renderTargetX.texture;
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurY;
        renderer.setRenderTarget(this.renderTargetY);
        renderer.clear();
        this.fsQuad.render(renderer);

        // Render original scene with superimposed blur to texture
        this.fsQuad.material = this.materialCombine;
        this.combineUniforms['tDiffuse'].value = this.renderTargetY.texture;
        if (maskActive) renderer.state.buffers.stencil.setTest(true);
        renderer.setRenderTarget(readBuffer);
        if (this.clear) renderer.clear();
        this.fsQuad.render(renderer);
    }

    public function setSize(width:Int, height:Int) {
        this.renderTargetX.setSize(width, height);
        this.renderTargetY.setSize(width, height);
    }

    public function dispose() {
        this.renderTargetX.dispose();
        this.renderTargetY.dispose();
        this.materialCombine.dispose();
        this.materialConvolution.dispose();
        this.fsQuad.dispose();
    }
}

class CombineShader {
    public static var name:String = 'CombineShader';
    public static var uniforms:Dynamic = {
        'tDiffuse': {value: null},
        'strength': {value: 1.0}
    };
    public static var vertexShader:String = '
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }';
    public static var fragmentShader:String = '
        uniform float strength;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 texel = texture2D(tDiffuse, vUv);
            gl_FragColor = strength * texel;
        }';
}

class BloomPass {
    public static var blurX:Vector2 = new Vector2(0.001953125, 0.0);
    public static var blurY:Vector2 = new Vector2(0.0, 0.001953125);
}