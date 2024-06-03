import three.materials.ShaderMaterial;
import three.materials.UniformsUtils;
import three.math.Vector2;
import three.renderers.WebGLRenderTarget;
import three.scenes.HalfFloatType;
import three.scenes.AdditiveBlending;
import three.core.Pass;
import three.extras.FullScreenQuad;
import three.shaders.ConvolutionShader;

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

        this.renderTargetX = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        this.renderTargetX.texture.name = 'BloomPass.x';
        this.renderTargetY = new WebGLRenderTarget(1, 1, { type: HalfFloatType });
        this.renderTargetY.texture.name = 'BloomPass.y';

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

        this.convolutionUniforms = UniformsUtils.clone(ConvolutionShader.uniforms);
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;
        this.convolutionUniforms['cKernel'].value = ConvolutionShader.buildKernel(sigma);

        this.materialConvolution = new ShaderMaterial({
            name: ConvolutionShader.name,
            uniforms: this.convolutionUniforms,
            vertexShader: ConvolutionShader.vertexShader,
            fragmentShader: ConvolutionShader.fragmentShader,
            defines: {
                'KERNEL_SIZE_FLOAT': kernelSize.toString(),
                'KERNEL_SIZE_INT': kernelSize.toString()
            }
        });

        this.needsSwap = false;
        this.fsQuad = new FullScreenQuad(null);
    }

    public function render(renderer, writeBuffer, readBuffer, deltaTime, maskActive) {
        if (maskActive) renderer.state.buffers.stencil.setTest(false);

        this.fsQuad.material = this.materialConvolution;
        this.convolutionUniforms['tDiffuse'].value = readBuffer.texture;
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;

        renderer.setRenderTarget(this.renderTargetX);
        renderer.clear();
        this.fsQuad.render(renderer);

        this.convolutionUniforms['tDiffuse'].value = this.renderTargetX.texture;
        this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurY;

        renderer.setRenderTarget(this.renderTargetY);
        renderer.clear();
        this.fsQuad.render(renderer);

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
    static var name:String = 'CombineShader';
    static var uniforms = {
        'tDiffuse': { value: null },
        'strength': { value: 1.0 }
    };
    static var vertexShader:String = `
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }`;
    static var fragmentShader:String = `
        uniform float strength;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 texel = texture2D( tDiffuse, vUv );
            gl_FragColor = strength * texel;
        }`;
}

static var BloomPass_blurX = new Vector2(0.001953125, 0.0);
static var BloomPass_blurY = new Vector2(0.0, 0.001953125);