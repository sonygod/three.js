import three.math.MathUtils;
import three.textures.DataTexture;
import three.textures.RedFormat;
import three.textures.FloatType;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.cameras.Camera;
import three.renderers.RenderTarget;
import three.utils.UniformsUtils;
import three.objects.Mesh;
import three.geometries.PlaneGeometry;
import three.shaders.DigitalGlitch;
import three.passes.Pass;

class GlitchPass extends Pass {
	
	private var dt_size:Int;
	private var uniforms:Dynamic;
	private var heightMap:DataTexture;
	private var material:ShaderMaterial;
	private var fsQuad:Mesh;
	private var goWild:Bool;
	private var curF:Int;
	private var randX:Int;

	public function new(dt_size:Int = 64) {
		super();
		this.dt_size = dt_size;

		var shader = DigitalGlitch;

		this.uniforms = UniformsUtils.clone(shader.uniforms);
		this.heightMap = generateHeightmap(dt_size);

		this.uniforms['tDisp'].value = this.heightMap;

		this.material = new ShaderMaterial({
			uniforms: this.uniforms,
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader
		});

		this.fsQuad = new Mesh(new PlaneGeometry(2, 2), this.material);

		this.goWild = false;
		this.curF = 0;
		generateTrigger();
	}

	override public function render(renderer:WebGLRenderer, writeBuffer:RenderTarget, readBuffer:RenderTarget, ?deltaTime:Float, ?maskActive:Bool):Void {
		this.uniforms['tDiffuse'].value = readBuffer.texture;
		this.uniforms['seed'].value = Math.random(); // default seeding
		this.uniforms['byp'].value = 0;

		if (this.curF % this.randX == 0 || this.goWild) {
			this.uniforms['amount'].value = Math.random() / 30;
			this.uniforms['angle'].value = MathUtils.randFloat(-Math.PI, Math.PI);
			this.uniforms['seed_x'].value = MathUtils.randFloat(-1, 1);
			this.uniforms['seed_y'].value = MathUtils.randFloat(-1, 1);
			this.uniforms['distortion_x'].value = MathUtils.randFloat(0, 1);
			this.uniforms['distortion_y'].value = MathUtils.randFloat(0, 1);
			this.curF = 0;
			generateTrigger();
		} else if (this.curF % this.randX < this.randX / 5) {
			this.uniforms['amount'].value = Math.random() / 90;
			this.uniforms['angle'].value = MathUtils.randFloat(-Math.PI, Math.PI);
			this.uniforms['distortion_x'].value = MathUtils.randFloat(0, 1);
			this.uniforms['distortion_y'].value = MathUtils.randFloat(0, 1);
			this.uniforms['seed_x'].value = MathUtils.randFloat(-0.3, 0.3);
			this.uniforms['seed_y'].value = MathUtils.randFloat(-0.3, 0.3);
		} else if (!this.goWild) {
			this.uniforms['byp'].value = 1;
		}

		this.curF++;

		if (this.renderToScreen) {
			renderer.setRenderTarget(null);
			renderer.render(new Scene(), new Camera(), this.fsQuad);
		} else {
			renderer.setRenderTarget(writeBuffer);
			if (this.clear) renderer.clear();
			renderer.render(new Scene(), new Camera(), this.fsQuad);
		}
	}

	private function generateTrigger():Void {
		this.randX = MathUtils.randInt(120, 240);
	}

	private function generateHeightmap(dt_size:Int):DataTexture {
		var data_arr = new Float32Array(dt_size * dt_size);
		var length = dt_size * dt_size;

		for (var i = 0; i < length; i++) {
			var val = MathUtils.randFloat(0, 1);
			data_arr[i] = val;
		}

		var texture = new DataTexture(data_arr, dt_size, dt_size, RedFormat, FloatType);
		texture.needsUpdate = true;
		return texture;
	}

	override public function dispose():Void {
		this.material.dispose();
		this.heightMap.dispose();
		this.fsQuad.dispose();
	}

}