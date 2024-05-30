package three.jsm.postprocessing;

import three.AdditiveBlending;
import three.Color;
import three.HalfFloatType;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.jsm.postprocessing.Pass;
import three.jsm.postprocessing.FullScreenQuad;
import three.jsm.shaders.CopyShader;

class SSAARenderPass extends Pass {

	var scene:Scene;
	var camera:Camera;
	var sampleLevel:Int = 4;
	var unbiased:Bool = true;
	var clearColor:Int = 0x000000;
	var clearAlpha:Float = 0;
	var _oldClearColor:Color;
	var copyUniforms:Dynamic;
	var copyMaterial:ShaderMaterial;
	var fsQuad:FullScreenQuad;
	var sampleRenderTarget:WebGLRenderTarget;

	public function new(scene:Scene, camera:Camera, clearColor:Int, clearAlpha:Float) {
		super();
		this.scene = scene;
		this.camera = camera;
		this.clearColor = clearColor != null ? clearColor : 0x000000;
		this.clearAlpha = clearAlpha != null ? clearAlpha : 0;
		this._oldClearColor = new Color();

		var copyShader = CopyShader;
		this.copyUniforms = UniformsUtils.clone(copyShader.uniforms);

		this.copyMaterial = new ShaderMaterial({
			uniforms: this.copyUniforms,
			vertexShader: copyShader.vertexShader,
			fragmentShader: copyShader.fragmentShader,
			transparent: true,
			depthTest: false,
			depthWrite: false,
			premultipliedAlpha: true,
			blending: AdditiveBlending
		});

		this.fsQuad = new FullScreenQuad(this.copyMaterial);
	}

	public function dispose() {
		if (this.sampleRenderTarget != null) {
			this.sampleRenderTarget.dispose();
			this.sampleRenderTarget = null;
		}
		this.copyMaterial.dispose();
		this.fsQuad.dispose();
	}

	public function setSize(width:Int, height:Int) {
		if (this.sampleRenderTarget != null) this.sampleRenderTarget.setSize(width, height);
	}

	public function render(renderer:WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget) {
		if (this.sampleRenderTarget == null) {
			this.sampleRenderTarget = new WebGLRenderTarget(readBuffer.width, readBuffer.height, {type: HalfFloatType});
			this.sampleRenderTarget.texture.name = 'SSAARenderPass.sample';
		}

		var jitterOffsets = _JitterVectors[Math.max(0, Math.min(this.sampleLevel, 5))];

		var autoClear = renderer.autoClear;
		renderer.autoClear = false;

		renderer.getClearColor(this._oldClearColor);
		var oldClearAlpha = renderer.getClearAlpha();

		var baseSampleWeight = 1.0 / jitterOffsets.length;
		var roundingRange = 1 / 32;
		this.copyUniforms['tDiffuse'].value = this.sampleRenderTarget.texture;

		var viewOffset = {
			fullWidth: readBuffer.width,
			fullHeight: readBuffer.height,
			offsetX: 0,
			offsetY: 0,
			width: readBuffer.width,
			height: readBuffer.height
		};

		var originalViewOffset = Object.assign({}, this.camera.view);

		if (originalViewOffset.enabled) Object.assign(viewOffset, originalViewOffset);

		for (i in 0...jitterOffsets.length) {
			var jitterOffset = jitterOffsets[i];

			if (this.camera.setViewOffset) {
				this.camera.setViewOffset(
					viewOffset.fullWidth, viewOffset.fullHeight,
					viewOffset.offsetX + jitterOffset[0] * 0.0625, viewOffset.offsetY + jitterOffset[1] * 0.0625,
					viewOffset.width, viewOffset.height
				);
			}

			var sampleWeight = baseSampleWeight;

			if (this.unbiased) {
				var uniformCenteredDistribution = (-0.5 + (i + 0.5) / jitterOffsets.length);
				sampleWeight += roundingRange * uniformCenteredDistribution;
			}

			this.copyUniforms['opacity'].value = sampleWeight;
			renderer.setClearColor(this.clearColor, this.clearAlpha);
			renderer.setRenderTarget(this.sampleRenderTarget);
			renderer.clear();
			renderer.render(this.scene, this.camera);

			renderer.setRenderTarget(this.renderToScreen ? null : writeBuffer);

			if (i == 0) {
				renderer.setClearColor(0x000000, 0.0);
				renderer.clear();
			}

			this.fsQuad.render(renderer);
		}

		if (this.camera.setViewOffset && originalViewOffset.enabled) {
			this.camera.setViewOffset(
				originalViewOffset.fullWidth, originalViewOffset.fullHeight,
				originalViewOffset.offsetX, originalViewOffset.offsetY,
				originalViewOffset.width, originalViewOffset.height
			);
		} else if (this.camera.clearViewOffset) {
			this.camera.clearViewOffset();
		}

		renderer.autoClear = autoClear;
		renderer.setClearColor(this._oldClearColor, oldClearAlpha);
	}
}

var _JitterVectors = [
	[
		[0, 0]
	],
	[
		[4, 4], [-4, -4]
	],
	[
		[-2, -6], [6, -2], [-6, 2], [2, 6]
	],
	[
		[1, -3], [-1, 3], [5, 1], [-3, -5],
		[-5, 5], [-7, -1], [3, 7], [7, -7]
	],
	[
		[1, 1], [-1, -3], [-3, 2], [4, -1],
		[-5, -2], [2, 5], [5, 3], [3, -5],
		[-2, 6], [0, -7], [-4, -6], [-6, 4],
		[-8, 0], [7, -4], [6, 7], [-7, -8]
	],
	[
		[-4, -7], [-7, -5], [-3, -5], [-5, -4],
		[-1, -4], [-2, -2], [-6, -1], [-4, 0],
		[-7, 1], [-1, 2], [-6, 3], [-3, 3],
		[-7, 6], [-3, 6], [-5, 7], [-1, 7],
		[5, -7], [1, -6], [6, -5], [4, -4],
		[2, -3], [7, -2], [1, -1], [4, -1],
		[2, 1], [6, 2], [0, 4], [4, 4],
		[2, 5], [7, 5], [5, 6], [3, 7]
	]
];