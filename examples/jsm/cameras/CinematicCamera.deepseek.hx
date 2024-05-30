import three.Mesh;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;

import BokehShader2.BokehShader;
import BokehShader2.BokehDepthShader;

class CinematicCamera extends PerspectiveCamera {

	public function new(fov:Float, aspect:Float, near:Float, far:Float) {
		super(fov, aspect, near, far);

		this.type = 'CinematicCamera';

		this.postprocessing = { enabled: true };
		this.shaderSettings = {
			rings: 3,
			samples: 4
		};

		var depthShader = BokehDepthShader;

		this.materialDepth = new ShaderMaterial({
			uniforms: depthShader.uniforms,
			vertexShader: depthShader.vertexShader,
			fragmentShader: depthShader.fragmentShader
		});

		this.materialDepth.uniforms['mNear'].value = near;
		this.materialDepth.uniforms['mFar'].value = far;

		this.setLens();

		this.initPostProcessing();
	}

	public function setLens(focalLength:Float = 35, filmGauge:Float = 35, fNumber:Float = 8, coc:Float = 0.019):Void {
		this.filmGauge = filmGauge;

		this.setFocalLength(focalLength);

		this.fNumber = fNumber;
		this.coc = coc;

		this.aperture = focalLength / this.fNumber;

		this.hyperFocal = (focalLength * focalLength) / (this.aperture * this.coc);
	}

	public function linearize(depth:Float):Float {
		var zfar = this.far;
		var znear = this.near;
		return -zfar * znear / (depth * (zfar - znear) - zfar);
	}

	public function smoothstep(near:Float, far:Float, depth:Float):Float {
		var x = this.saturate((depth - near) / (far - near));
		return x * x * (3 - 2 * x);
	}

	public function saturate(x:Float):Float {
		return Math.max(0, Math.min(1, x));
	}

	public function focusAt(focusDistance:Float = 20):Void {
		var focalLength = this.getFocalLength();

		this.focus = focusDistance;

		this.nearPoint = (this.hyperFocal * this.focus) / (this.hyperFocal + (this.focus - focalLength));

		this.farPoint = (this.hyperFocal * this.focus) / (this.hyperFocal - (this.focus - focalLength));

		this.depthOfField = this.farPoint - this.nearPoint;

		if (this.depthOfField < 0) this.depthOfField = 0;

		this.sdistance = this.smoothstep(this.near, this.far, this.focus);

		this.ldistance = this.linearize(1 - this.sdistance);

		this.postprocessing.bokeh_uniforms['focalDepth'].value = this.ldistance;
	}

	public function initPostProcessing():Void {
		if (this.postprocessing.enabled) {
			this.postprocessing.scene = new Scene();

			this.postprocessing.camera = new OrthographicCamera(window.innerWidth / -2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / -2, -10000, 10000);

			this.postprocessing.scene.add(this.postprocessing.camera);

			this.postprocessing.rtTextureDepth = new WebGLRenderTarget(window.innerWidth, window.innerHeight);
			this.postprocessing.rtTextureColor = new WebGLRenderTarget(window.innerWidth, window.innerHeight);

			var bokeh_shader = BokehShader;

			this.postprocessing.bokeh_uniforms = UniformsUtils.clone(bokeh_shader.uniforms);

			this.postprocessing.bokeh_uniforms['tColor'].value = this.postprocessing.rtTextureColor.texture;
			this.postprocessing.bokeh_uniforms['tDepth'].value = this.postprocessing.rtTextureDepth.texture;

			this.postprocessing.bokeh_uniforms['manualdof'].value = 0;
			this.postprocessing.bokeh_uniforms['shaderFocus'].value = 0;

			this.postprocessing.bokeh_uniforms['fstop'].value = 2.8;

			this.postprocessing.bokeh_uniforms['showFocus'].value = 1;

			this.postprocessing.bokeh_uniforms['focalDepth'].value = 0.1;

			this.postprocessing.bokeh_uniforms['znear'].value = this.near;
			this.postprocessing.bokeh_uniforms['zfar'].value = this.near;

			this.postprocessing.bokeh_uniforms['textureWidth'].value = window.innerWidth;

			this.postprocessing.bokeh_uniforms['textureHeight'].value = window.innerHeight;

			this.postprocessing.materialBokeh = new ShaderMaterial({
				uniforms: this.postprocessing.bokeh_uniforms,
				vertexShader: bokeh_shader.vertexShader,
				fragmentShader: bokeh_shader.fragmentShader,
				defines: {
					RINGS: this.shaderSettings.rings,
					SAMPLES: this.shaderSettings.samples,
					DEPTH_PACKING: 1
				}
			});

			this.postprocessing.quad = new Mesh(new PlaneGeometry(window.innerWidth, window.innerHeight), this.postprocessing.materialBokeh);
			this.postprocessing.quad.position.z = -500;
			this.postprocessing.scene.add(this.postprocessing.quad);
		}
	}

	public function renderCinematic(scene:Scene, renderer:Renderer):Void {
		if (this.postprocessing.enabled) {
			var currentRenderTarget = renderer.getRenderTarget();

			renderer.clear();

			scene.overrideMaterial = null;
			renderer.setRenderTarget(this.postprocessing.rtTextureColor);
			renderer.clear();
			renderer.render(scene, this);

			scene.overrideMaterial = this.materialDepth;
			renderer.setRenderTarget(this.postprocessing.rtTextureDepth);
			renderer.clear();
			renderer.render(scene, this);

			renderer.setRenderTarget(null);
			renderer.render(this.postprocessing.scene, this.postprocessing.camera);

			renderer.setRenderTarget(currentRenderTarget);
		}
	}
}