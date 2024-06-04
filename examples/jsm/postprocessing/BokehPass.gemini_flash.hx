import three.Color;
import three.HalfFloatType;
import three.MeshDepthMaterial;
import three.NearestFilter;
import three.NoBlending;
import three.RGBADepthPacking;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;
import three.passes.Pass;
import three.passes.FullScreenQuad;
import three.shaders.BokehShader;

/**
 * Depth-of-field post-process with bokeh shader
 */

class BokehPass extends Pass {

	public var scene:three.Scene;
	public var camera:three.Camera;

	public var renderTargetDepth:WebGLRenderTarget;
	public var materialDepth:MeshDepthMaterial;
	public var materialBokeh:ShaderMaterial;
	public var uniforms:Dynamic<three.IUniforms>;

	public var fsQuad:FullScreenQuad;

	public var _oldClearColor:Color;

	public function new(scene:three.Scene, camera:three.Camera, params:Dynamic) {
		super();

		this.scene = scene;
		this.camera = camera;

		var focus = params.focus != null ? params.focus : 1.0;
		var aperture = params.aperture != null ? params.aperture : 0.025;
		var maxblur = params.maxblur != null ? params.maxblur : 1.0;

		// render targets

		this.renderTargetDepth = new WebGLRenderTarget(1, 1, { // will be resized later
			minFilter: NearestFilter,
			magFilter: NearestFilter,
			type: HalfFloatType
		});

		this.renderTargetDepth.texture.name = "BokehPass.depth";

		// depth material

		this.materialDepth = new MeshDepthMaterial();
		this.materialDepth.depthPacking = RGBADepthPacking;
		this.materialDepth.blending = NoBlending;

		// bokeh material

		var bokehShader = BokehShader;
		var bokehUniforms = UniformsUtils.clone(bokehShader.uniforms);

		bokehUniforms["tDepth"].value = this.renderTargetDepth.texture;

		bokehUniforms["focus"].value = focus;
		bokehUniforms["aspect"].value = camera.aspect;
		bokehUniforms["aperture"].value = aperture;
		bokehUniforms["maxblur"].value = maxblur;
		bokehUniforms["nearClip"].value = camera.near;
		bokehUniforms["farClip"].value = camera.far;

		this.materialBokeh = new ShaderMaterial({
			defines:  Cast.to(bokehShader.defines, Dynamic),
			uniforms: bokehUniforms,
			vertexShader: bokehShader.vertexShader,
			fragmentShader: bokehShader.fragmentShader
		});

		this.uniforms = bokehUniforms;

		this.fsQuad = new FullScreenQuad(this.materialBokeh);

		this._oldClearColor = new Color();
	}

	public function render(renderer:three.Renderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float, maskActive:Bool) {

		// Render depth into texture

		this.scene.overrideMaterial = this.materialDepth;

		renderer.getClearColor(this._oldClearColor);
		var oldClearAlpha = renderer.getClearAlpha();
		var oldAutoClear = renderer.autoClear;
		renderer.autoClear = false;

		renderer.setClearColor(0xffffff);
		renderer.setClearAlpha(1.0);
		renderer.setRenderTarget(this.renderTargetDepth);
		renderer.clear();
		renderer.render(this.scene, this.camera);

		// Render bokeh composite

		this.uniforms["tColor"].value = readBuffer.texture;
		this.uniforms["nearClip"].value = this.camera.near;
		this.uniforms["farClip"].value = this.camera.far;

		if (this.renderToScreen) {

			renderer.setRenderTarget(null);
			this.fsQuad.render(renderer);

		} else {

			renderer.setRenderTarget(writeBuffer);
			renderer.clear();
			this.fsQuad.render(renderer);

		}

		this.scene.overrideMaterial = null;
		renderer.setClearColor(this._oldClearColor);
		renderer.setClearAlpha(oldClearAlpha);
		renderer.autoClear = oldAutoClear;

	}

	public function setSize(width:Int, height:Int) {

		this.materialBokeh.uniforms["aspect"].value = width / height;

		this.renderTargetDepth.setSize(width, height);

	}

	public function dispose() {

		this.renderTargetDepth.dispose();

		this.materialDepth.dispose();
		this.materialBokeh.dispose();

		this.fsQuad.dispose();

	}

}