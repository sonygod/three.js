import three.WebGLRenderTarget;
import three.MeshNormalMaterial;
import three.ShaderMaterial;
import three.Vector2;
import three.Vector4;
import three.DepthTexture;
import three.NearestFilter;
import three.HalfFloatType;
import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;

class RenderPixelatedPass extends Pass {

	var pixelSize:Float;
	var resolution:Vector2;
	var renderResolution:Vector2;
	var pixelatedMaterial:ShaderMaterial;
	var normalMaterial:MeshNormalMaterial;
	var fsQuad:FullScreenQuad;
	var scene:Dynamic;
	var camera:Dynamic;
	var normalEdgeStrength:Float;
	var depthEdgeStrength:Float;
	var beautyRenderTarget:WebGLRenderTarget;
	var normalRenderTarget:WebGLRenderTarget;

	public function new(pixelSize:Float, scene:Dynamic, camera:Dynamic, options:Dynamic = null) {
		super();

		this.pixelSize = pixelSize;
		this.resolution = new Vector2();
		this.renderResolution = new Vector2();

		this.pixelatedMaterial = this.createPixelatedMaterial();
		this.normalMaterial = new MeshNormalMaterial();

		this.fsQuad = new FullScreenQuad(this.pixelatedMaterial);
		this.scene = scene;
		this.camera = camera;

		this.normalEdgeStrength = (options != null && options.normalEdgeStrength != null) ? options.normalEdgeStrength : 0.3;
		this.depthEdgeStrength = (options != null && options.depthEdgeStrength != null) ? options.depthEdgeStrength : 0.4;

		this.beautyRenderTarget = new WebGLRenderTarget();
		this.beautyRenderTarget.texture.minFilter = NearestFilter;
		this.beautyRenderTarget.texture.magFilter = NearestFilter;
		this.beautyRenderTarget.texture.type = HalfFloatType;
		this.beautyRenderTarget.depthTexture = new DepthTexture();

		this.normalRenderTarget = new WebGLRenderTarget();
		this.normalRenderTarget.texture.minFilter = NearestFilter;
		this.normalRenderTarget.texture.magFilter = NearestFilter;
		this.normalRenderTarget.texture.type = HalfFloatType;
	}

	public function dispose() {
		this.beautyRenderTarget.dispose();
		this.normalRenderTarget.dispose();
		this.pixelatedMaterial.dispose();
		this.normalMaterial.dispose();
		this.fsQuad.dispose();
	}

	public function setSize(width:Float, height:Float) {
		this.resolution.set(width, height);
		this.renderResolution.set((width / this.pixelSize) | 0, (height / this.pixelSize) | 0);
		var x = this.renderResolution.x;
		var y = this.renderResolution.y;
		this.beautyRenderTarget.setSize(x, y);
		this.normalRenderTarget.setSize(x, y);
		this.fsQuad.material.uniforms.resolution.value.set(x, y, 1 / x, 1 / y);
	}

	public function setPixelSize(pixelSize:Float) {
		this.pixelSize = pixelSize;
		this.setSize(this.resolution.x, this.resolution.y);
	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic) {
		var uniforms = this.fsQuad.material.uniforms;
		uniforms.normalEdgeStrength.value = this.normalEdgeStrength;
		uniforms.depthEdgeStrength.value = this.depthEdgeStrength;

		renderer.setRenderTarget(this.beautyRenderTarget);
		renderer.render(this.scene, this.camera);

		var overrideMaterial_old = this.scene.overrideMaterial;
		renderer.setRenderTarget(this.normalRenderTarget);
		this.scene.overrideMaterial = this.normalMaterial;
		renderer.render(this.scene, this.camera);
		this.scene.overrideMaterial = overrideMaterial_old;

		uniforms.tDiffuse.value = this.beautyRenderTarget.texture;
		uniforms.tDepth.value = this.beautyRenderTarget.depthTexture;
		uniforms.tNormal.value = this.normalRenderTarget.texture;

		if (this.renderToScreen) {
			renderer.setRenderTarget(null);
		} else {
			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear();
		}

		this.fsQuad.render(renderer);
	}

	public function createPixelatedMaterial():ShaderMaterial {
		// ... 省略了 createPixelatedMaterial 方法的实现，因为它太长了。
	}
}