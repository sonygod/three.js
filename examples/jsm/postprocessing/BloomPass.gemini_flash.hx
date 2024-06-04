import three.AdditiveBlending;
import three.HalfFloatType;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector2;
import three.WebGLRenderTarget;
import Pass from "./Pass";
import FullScreenQuad from "./FullScreenQuad";
import ConvolutionShader from "../shaders/ConvolutionShader";
import CombineShader from "../shaders/CombineShader";

class BloomPass extends Pass {

	public strength: Float;
	public kernelSize: Int;
	public sigma: Float;
	public renderTargetX: WebGLRenderTarget;
	public renderTargetY: WebGLRenderTarget;
	public combineUniforms: { [key: string]: { value: dynamic } };
	public materialCombine: ShaderMaterial;
	public convolutionUniforms: { [key: string]: { value: dynamic } };
	public materialConvolution: ShaderMaterial;
	public fsQuad: FullScreenQuad;

	public function new(strength: Float = 1, kernelSize: Int = 25, sigma: Float = 4) {
		super();

		this.strength = strength;
		this.kernelSize = kernelSize;
		this.sigma = sigma;

		// render targets

		this.renderTargetX = new WebGLRenderTarget(1, 1, { type: HalfFloatType }); // will be resized later
		this.renderTargetX.texture.name = 'BloomPass.x';
		this.renderTargetY = new WebGLRenderTarget(1, 1, { type: HalfFloatType }); // will be resized later
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

		this.convolutionUniforms = UniformsUtils.clone(ConvolutionShader.uniforms);

		this.convolutionUniforms['uImageIncrement'].value = BloomPass.blurX;
		this.convolutionUniforms['cKernel'].value = ConvolutionShader.buildKernel(sigma);

		this.materialConvolution = new ShaderMaterial({
			name: ConvolutionShader.name,
			uniforms: this.convolutionUniforms,
			vertexShader: ConvolutionShader.vertexShader,
			fragmentShader: ConvolutionShader.fragmentShader,
			defines: {
				'KERNEL_SIZE_FLOAT': kernelSize.toFixed(1),
				'KERNEL_SIZE_INT': kernelSize.toFixed(0)
			}
		});

		this.needsSwap = false;

		this.fsQuad = new FullScreenQuad(null);
	}

	public function render(renderer: dynamic, writeBuffer: dynamic, readBuffer: dynamic, deltaTime: Float, maskActive: Bool) {
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

	public function setSize(width: Int, height: Int) {
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

	public static var name: String = 'CombineShader';

	public static var uniforms: { [key: string]: { value: dynamic } } = {
		'tDiffuse': { value: null },
		'strength': { value: 1.0 }
	};

	public static var vertexShader: String = /* glsl */`

		varying vec2 vUv;

		void main() {

			vUv = uv;
			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

		}`;

	public static var fragmentShader: String = /* glsl */`

		uniform float strength;

		uniform sampler2D tDiffuse;

		varying vec2 vUv;

		void main() {

			vec4 texel = texture2D( tDiffuse, vUv );
			gl_FragColor = strength * texel;

		}`;

}

BloomPass.blurX = new Vector2(0.001953125, 0.0);
BloomPass.blurY = new Vector2(0.0, 0.001953125);

export { BloomPass };