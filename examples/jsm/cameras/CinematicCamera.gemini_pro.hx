import three.core.Mesh;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.geometries.PlaneGeometry;
import three.scenes.Scene;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderer;
import three.uniforms.UniformsUtils;
import three.renderers.WebGLRenderTarget;

import BokehShader from "../shaders/BokehShader2";
import BokehDepthShader from "../shaders/BokehDepthShader";

class CinematicCamera extends PerspectiveCamera {

	public var postprocessing: {
		enabled: Bool;
		scene: Scene;
		camera: OrthographicCamera;
		rtTextureDepth: WebGLRenderTarget;
		rtTextureColor: WebGLRenderTarget;
		bokeh_uniforms: {
			tColor: { value: Dynamic };
			tDepth: { value: Dynamic };
			manualdof: { value: Float };
			shaderFocus: { value: Float };
			fstop: { value: Float };
			showFocus: { value: Float };
			focalDepth: { value: Float };
			znear: { value: Float };
			zfar: { value: Float };
			textureWidth: { value: Int };
			textureHeight: { value: Int };
		};
		materialBokeh: ShaderMaterial;
		quad: Mesh;
	};

	public var shaderSettings: {
		rings: Int;
		samples: Int;
	};

	public var materialDepth: ShaderMaterial;

	public var filmGauge: Float;
	public var fNumber: Float;
	public var coc: Float;
	public var aperture: Float;
	public var hyperFocal: Float;
	public var focus: Float;
	public var nearPoint: Float;
	public var farPoint: Float;
	public var depthOfField: Float;
	public var sdistance: Float;
	public var ldistance: Float;

	public function new(fov: Float, aspect: Float, near: Float, far: Float) {
		super(fov, aspect, near, far);
		this.type = "CinematicCamera";
		this.postprocessing = {
			enabled: true,
			scene: null,
			camera: null,
			rtTextureDepth: null,
			rtTextureColor: null,
			bokeh_uniforms: null,
			materialBokeh: null,
			quad: null
		};
		this.shaderSettings = {
			rings: 3,
			samples: 4
		};
		this.materialDepth = new ShaderMaterial({
			uniforms: BokehDepthShader.uniforms,
			vertexShader: BokehDepthShader.vertexShader,
			fragmentShader: BokehDepthShader.fragmentShader
		});
		this.materialDepth.uniforms["mNear"].value = near;
		this.materialDepth.uniforms["mFar"].value = far;
		this.setLens();
		this.initPostProcessing();
	}

	public function setLens(focalLength: Float = 35, filmGauge: Float = 35, fNumber: Float = 8, coc: Float = 0.019) {
		this.filmGauge = filmGauge;
		this.setFocalLength(focalLength);
		this.fNumber = fNumber;
		this.coc = coc;
		this.aperture = focalLength / this.fNumber;
		this.hyperFocal = (focalLength * focalLength) / (this.aperture * this.coc);
	}

	public function linearize(depth: Float): Float {
		return - this.far * this.near / (depth * (this.far - this.near) - this.far);
	}

	public function smoothstep(near: Float, far: Float, depth: Float): Float {
		var x = this.saturate((depth - near) / (far - near));
		return x * x * (3 - 2 * x);
	}

	public function saturate(x: Float): Float {
		return Math.max(0, Math.min(1, x));
	}

	public function focusAt(focusDistance: Float = 20) {
		this.focus = focusDistance;
		this.nearPoint = (this.hyperFocal * this.focus) / (this.hyperFocal + (this.focus - this.getFocalLength()));
		this.farPoint = (this.hyperFocal * this.focus) / (this.hyperFocal - (this.focus - this.getFocalLength()));
		this.depthOfField = this.farPoint - this.nearPoint;
		if (this.depthOfField < 0) this.depthOfField = 0;
		this.sdistance = this.smoothstep(this.near, this.far, this.focus);
		this.ldistance = this.linearize(1 - this.sdistance);
		this.postprocessing.bokeh_uniforms["focalDepth"].value = this.ldistance;
	}

	public function initPostProcessing() {
		if (this.postprocessing.enabled) {
			this.postprocessing.scene = new Scene();
			this.postprocessing.camera = new OrthographicCamera(Std.int(-window.innerWidth / 2), Std.int(window.innerWidth / 2), Std.int(window.innerHeight / 2), Std.int(window.innerHeight / -2), -10000, 10000);
			this.postprocessing.scene.add(this.postprocessing.camera);
			this.postprocessing.rtTextureDepth = new WebGLRenderTarget(Std.int(window.innerWidth), Std.int(window.innerHeight));
			this.postprocessing.rtTextureColor = new WebGLRenderTarget(Std.int(window.innerWidth), Std.int(window.innerHeight));
			this.postprocessing.bokeh_uniforms = UniformsUtils.clone(BokehShader.uniforms);
			this.postprocessing.bokeh_uniforms["tColor"].value = this.postprocessing.rtTextureColor.texture;
			this.postprocessing.bokeh_uniforms["tDepth"].value = this.postprocessing.rtTextureDepth.texture;
			this.postprocessing.bokeh_uniforms["manualdof"].value = 0;
			this.postprocessing.bokeh_uniforms["shaderFocus"].value = 0;
			this.postprocessing.bokeh_uniforms["fstop"].value = 2.8;
			this.postprocessing.bokeh_uniforms["showFocus"].value = 1;
			this.postprocessing.bokeh_uniforms["focalDepth"].value = 0.1;
			this.postprocessing.bokeh_uniforms["znear"].value = this.near;
			this.postprocessing.bokeh_uniforms["zfar"].value = this.far;
			this.postprocessing.bokeh_uniforms["textureWidth"].value = Std.int(window.innerWidth);
			this.postprocessing.bokeh_uniforms["textureHeight"].value = Std.int(window.innerHeight);
			this.postprocessing.materialBokeh = new ShaderMaterial({
				uniforms: this.postprocessing.bokeh_uniforms,
				vertexShader: BokehShader.vertexShader,
				fragmentShader: BokehShader.fragmentShader,
				defines: {
					RINGS: this.shaderSettings.rings,
					SAMPLES: this.shaderSettings.samples,
					DEPTH_PACKING: 1
				}
			});
			this.postprocessing.quad = new Mesh(new PlaneGeometry(Std.int(window.innerWidth), Std.int(window.innerHeight)), this.postprocessing.materialBokeh);
			this.postprocessing.quad.position.z = -500;
			this.postprocessing.scene.add(this.postprocessing.quad);
		}
	}

	public function renderCinematic(scene: Scene, renderer: WebGLRenderer) {
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

export class CinematicCamera {
}