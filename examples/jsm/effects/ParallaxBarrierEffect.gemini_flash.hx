import three.cameras.OrthographicCamera;
import three.cameras.StereoCamera;
import three.core.Mesh;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.math.Color;
import three.objects.Scene;
import three.renderers.WebGLRenderer;
import three.scenes.Fog;
import three.textures.Texture;
import three.textures.WebGLRenderTarget;

class ParallaxBarrierEffect {

	var _camera:OrthographicCamera;
	var _scene:Scene;
	var _stereo:StereoCamera;
	var _renderTargetL:WebGLRenderTarget;
	var _renderTargetR:WebGLRenderTarget;
	var _material:ShaderMaterial;

	public function new(renderer:WebGLRenderer) {

		_camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);

		_scene = new Scene();

		_stereo = new StereoCamera();

		_renderTargetL = new WebGLRenderTarget(512, 512, {
			minFilter: three.constants.LinearFilter,
			magFilter: three.constants.NearestFilter,
			format: three.constants.RGBAFormat
		});

		_renderTargetR = new WebGLRenderTarget(512, 512, {
			minFilter: three.constants.LinearFilter,
			magFilter: three.constants.NearestFilter,
			format: three.constants.RGBAFormat
		});

		_material = new ShaderMaterial({
			uniforms: {
				'mapLeft': { value: _renderTargetL.texture },
				'mapRight': { value: _renderTargetR.texture }
			},
			vertexShader: [
				'varying vec2 vUv;',

				'void main() {',

				'	vUv = vec2( uv.x, uv.y );',
				'	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',

				'}'
			].join('\n'),
			fragmentShader: [
				'uniform sampler2D mapLeft;',
				'uniform sampler2D mapRight;',
				'varying vec2 vUv;',

				'void main() {',

				'	vec2 uv = vUv;',

				'	if ( ( mod( gl_FragCoord.y, 2.0 ) ) > 1.00 ) {',

				'		gl_FragColor = texture2D( mapLeft, uv );',

				'	} else {',

				'		gl_FragColor = texture2D( mapRight, uv );',

				'	}',

				'	#include <tonemapping_fragment>',
				'	#include <colorspace_fragment>',

				'}'
			].join('\n')
		});

		var mesh = new Mesh(new PlaneGeometry(2, 2), _material);
		_scene.add(mesh);

		this.setSize = function (width:Int, height:Int) {

			renderer.setSize(width, height);

			var pixelRatio = renderer.getPixelRatio();

			_renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
			_renderTargetR.setSize(width * pixelRatio, height * pixelRatio);

		};

		this.render = function (scene:Scene, camera:three.cameras.Camera) {

			if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

			if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

			_stereo.update(camera);

			renderer.setRenderTarget(_renderTargetL);
			renderer.clear();
			renderer.render(scene, _stereo.cameraL);

			renderer.setRenderTarget(_renderTargetR);
			renderer.clear();
			renderer.render(scene, _stereo.cameraR);

			renderer.setRenderTarget(null);
			renderer.render(_scene, _camera);

		};

	}

}