import three.Cameras.PerspectiveCamera;
import three.Core.Object3D;
import three.Geometries.PlaneGeometry;
import three.Materials.ShaderMaterial;
import three.Math.Math;
import three.Renderers.WebGLRenderTarget;
import three.Scenes.Scene;
import three.ShaderLib;
import three.UniformsUtils;

class CinematicCamera extends PerspectiveCamera {

	public var postprocessing : {
		enabled : Bool,
		scene : Scene,
		camera : OrthographicCamera,
		rtTextureDepth : WebGLRenderTarget,
		rtTextureColor : WebGLRenderTarget,
		bokeh_uniforms : Dynamic,
		materialBokeh : ShaderMaterial,
		quad : Mesh
	};

	public var shaderSettings : {
		rings : Int,
		samples : Int
	};

	public var filmGauge : Float;
	public var fNumber : Float;
	public var coc : Float;
	public var aperture : Float;
	public var hyperFocal : Float;
	public var focus : Float;
	public var nearPoint : Float;
	public var farPoint : Float;
	public var depthOfField : Float;
	public var sdistance : Float;
	public var ldistance : Float;

	public function new(fov : Float, aspect : Float, near : Float, far : Float) {

		super(fov, aspect, near, far);

		this.type = 'CinematicCamera';

		this.postprocessing = {
			enabled: true
		};
		this.shaderSettings = {
			rings: 3,
			samples: 4
		};

		var depthShader = ShaderLib["depthRGBA"];

		this.materialDepth = new ShaderMaterial({
			uniforms: depthShader.uniforms,
			vertexShader: depthShader.vertexShader,
			fragmentShader: depthShader.fragmentShader
		});

		this.materialDepth.uniforms["mNear"].value = near;
		this.materialDepth.uniforms["mFar"].value = far;

		// In case of cinematicCamera, having a default lens set is important
		this.setLens();

		this.initPostProcessing();

	}

	// providing fnumber and coc(Circle of Confusion) as extra arguments
	// In case of cinematicCamera, having a default lens set is important
	// if fnumber and coc are not provided, cinematicCamera tries to act as a basic PerspectiveCamera
	public function setLens(focalLength : Float = 35, filmGauge : Float = 35, fNumber : Float = 8, coc : Float = 0.019) {

		this.filmGauge = filmGauge;

		this.setFocalLength(focalLength);

		this.fNumber = fNumber;
		this.coc = coc;

		// fNumber is focalLength by aperture
		this.aperture = focalLength / this.fNumber;

		// hyperFocal is required to calculate depthOfField when a lens tries to focus at a distance with given fNumber and focalLength
		this.hyperFocal = (focalLength * focalLength) / (this.aperture * this.coc);

	}

	public function linearize(depth : Float) : Float {

		var zfar = this.far;
		var znear = this.near;
		return -zfar * znear / (depth * (zfar - znear) - zfar);

	}

	public function smoothstep(near : Float, far : Float, depth : Float) : Float {

		var x = this.saturate((depth - near) / (far - near));
		return x * x * (3 - 2 * x);

	}

	public function saturate(x : Float) : Float {

		return Math.max(0, Math.min(1, x));

	}

	// function for focusing at a distance from the camera
	public function focusAt(focusDistance : Float = 20) {

		var focalLength = this.getFocalLength();

		// distance from the camera (normal to frustrum) to focus on
		this.focus = focusDistance;

		// the nearest point from the camera which is in focus (unused)
		this.nearPoint = (this.hyperFocal * this.focus) / (this.hyperFocal + (this.focus - focalLength));

		// the farthest point from the camera which is in focus (unused)
		this.farPoint = (this.hyperFocal * this.focus) / (this.hyperFocal - (this.focus - focalLength));

		// the gap or width of the space in which is everything is in focus (unused)
		this.depthOfField = this.farPoint - this.nearPoint;

		// Considering minimum distance of focus for a standard lens (unused)
		if (this.depthOfField < 0) this.depthOfField = 0;

		this.sdistance = this.smoothstep(this.near, this.far, this.focus);

		this.ldistance = this.linearize(1 - this.sdistance);

		this.postprocessing.bokeh_uniforms["focalDepth"].value = this.ldistance;

	}

	public function initPostProcessing() {

		if (this.postprocessing.enabled) {

			this.postprocessing.scene = new Scene();

			this.postprocessing.camera = new OrthographicCamera(Lib.window.innerWidth / -2, Lib.window.innerWidth / 2, Lib.window.innerHeight / 2, Lib.window.innerHeight / -2, -10000, 10000);

			this.postprocessing.scene.add(this.postprocessing.camera);

			this.postprocessing.rtTextureDepth = new WebGLRenderTarget(Lib.window.innerWidth, Lib.window.innerHeight);
			this.postprocessing.rtTextureColor = new WebGLRenderTarget(Lib.window.innerWidth, Lib.window.innerHeight);

			var bokeh_shader = BokehShader2; // Assuming you have a BokehShader2 class

			this.postprocessing.bokeh_uniforms = UniformsUtils.clone(bokeh_shader.uniforms);

			this.postprocessing.bokeh_uniforms["tColor"].value = this.postprocessing.rtTextureColor.texture;
			this.postprocessing.bokeh_uniforms["tDepth"].value = this.postprocessing.rtTextureDepth.texture;

			this.postprocessing.bokeh_uniforms["manualdof"].value = 0;
			this.postprocessing.bokeh_uniforms["shaderFocus"].value = 0;

			this.postprocessing.bokeh_uniforms["fstop"].value = 2.8;

			this.postprocessing.bokeh_uniforms["showFocus"].value = 1;

			this.postprocessing.bokeh_uniforms["focalDepth"].value = 0.1;

			//console.log( this.postprocessing.bokeh_uniforms[ "focalDepth" ].value );

			this.postprocessing.bokeh_uniforms["znear"].value = this.near;
			this.postprocessing.bokeh_uniforms["zfar"].value = this.near;

			this.postprocessing.bokeh_uniforms["textureWidth"].value = Lib.window.innerWidth;

			this.postprocessing.bokeh_uniforms["textureHeight"].value = Lib.window.innerHeight;

			this.postprocessing.materialBokeh = new ShaderMaterial({
				uniforms: this.postprocessing.bokeh_uniforms,
				vertexShader: bokeh_shader.vertexShader,
				fragmentShader: bokeh_shader.fragmentShader,
				defines: {
					"RINGS": this.shaderSettings.rings,
					"SAMPLES": this.shaderSettings.samples,
					"DEPTH_PACKING": 1
				}
			});

			this.postprocessing.quad = new Mesh(new PlaneGeometry(Lib.window.innerWidth, Lib.window.innerHeight), this.postprocessing.materialBokeh);
			this.postprocessing.quad.position.z = -500;
			this.postprocessing.scene.add(this.postprocessing.quad);

		}

	}

	public function renderCinematic(scene : Scene, renderer : WebGLRenderer) {

		if (this.postprocessing.enabled) {

			var currentRenderTarget = renderer.getRenderTarget();

			renderer.clear();

			// Render scene into texture
			scene.overrideMaterial = null;
			renderer.setRenderTarget(this.postprocessing.rtTextureColor);
			renderer.clear();
			renderer.render(scene, this);

			// Render depth into texture
			scene.overrideMaterial = this.materialDepth;
			renderer.setRenderTarget(this.postprocessing.rtTextureDepth);
			renderer.clear();
			renderer.render(scene, this);

			// Render bokeh composite
			renderer.setRenderTarget(null);
			renderer.render(this.postprocessing.scene, this.postprocessing.camera);

			renderer.setRenderTarget(currentRenderTarget);

		}

	}

}