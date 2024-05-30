import three.js.examples.jsm.objects.Reflector;
import three.js.examples.jsm.shaders.ReflectorShader;
import three.js.examples.jsm.utils.UniformsUtils;
import three.js.examples.jsm.math.Color;
import three.js.examples.jsm.math.Matrix4;
import three.js.examples.jsm.math.Vector3;
import three.js.examples.jsm.math.Vector4;
import three.js.examples.jsm.cameras.PerspectiveCamera;
import three.js.examples.jsm.geometries.Plane;
import three.js.examples.jsm.materials.ShaderMaterial;
import three.js.examples.jsm.renderers.WebGLRenderTarget;
import three.js.examples.jsm.constants.HalfFloatType;

class Reflector extends three.js.examples.jsm.objects.Reflector {

	public function new(geometry:three.js.examples.jsm.geometries.Geometry, options:Dynamic) {

		super(geometry);

		this.isReflector = true;

		this.type = 'Reflector';
		this.camera = new PerspectiveCamera();

		var scope = this;

		var color:Color;
		if (options.color != null) {
			color = new Color(options.color);
		} else {
			color = new Color(0x7F7F7F);
		}
		var textureWidth:Int = options.textureWidth != null ? options.textureWidth : 512;
		var textureHeight:Int = options.textureHeight != null ? options.textureHeight : 512;
		var clipBias:Float = options.clipBias != null ? options.clipBias : 0;
		var shader:ReflectorShader = options.shader != null ? options.shader : ReflectorShader;
		var multisample:Int = options.multisample != null ? options.multisample : 4;

		// ...

		var reflectorPlane:Plane = new Plane();
		var normal:Vector3 = new Vector3();
		var reflectorWorldPosition:Vector3 = new Vector3();
		var cameraWorldPosition:Vector3 = new Vector3();
		var rotationMatrix:Matrix4 = new Matrix4();
		var lookAtPosition:Vector3 = new Vector3(0, 0, -1);
		var clipPlane:Vector4 = new Vector4();

		var view:Vector3 = new Vector3();
		var target:Vector3 = new Vector3();
		var q:Vector4 = new Vector4();

		var textureMatrix:Matrix4 = new Matrix4();
		var virtualCamera:PerspectiveCamera = this.camera;

		var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

		var material:ShaderMaterial = new ShaderMaterial({
			name: shader.name != null ? shader.name : 'unspecified',
			uniforms: UniformsUtils.clone(shader.uniforms),
			fragmentShader: shader.fragmentShader,
			vertexShader: shader.vertexShader
		});

		material.uniforms['tDiffuse'].value = renderTarget.texture;
		material.uniforms['color'].value = color;
		material.uniforms['textureMatrix'].value = textureMatrix;

		this.material = material;

		this.onBeforeRender = function(renderer, scene, camera) {

			reflectorWorldPosition.setFromMatrixPosition(scope.matrixWorld);
			cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

			rotationMatrix.extractRotation(scope.matrixWorld);

			normal.set(0, 0, 1);
			normal.applyMatrix4(rotationMatrix);

			view.subVectors(reflectorWorldPosition, cameraWorldPosition);

			// ...

		};

		this.getRenderTarget = function() {

			return renderTarget;

		};

		this.dispose = function() {

			renderTarget.dispose();
			scope.material.dispose();

		};

	}

}

Reflector.ReflectorShader = {

	name: 'ReflectorShader',

	uniforms: {

		'color': {
			value: null
		},

		'tDiffuse': {
			value: null
		},

		'textureMatrix': {
			value: null
		}

	},

	vertexShader: /* glsl */`
		uniform mat4 textureMatrix;
		varying vec4 vUv;

		#include <common>
		#include <logdepthbuf_pars_vertex>

		void main() {

			vUv = textureMatrix * vec4( position, 1.0 );

			gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

			#include <logdepthbuf_vertex>

		}`,

	fragmentShader: /* glsl */`
		uniform vec3 color;
		uniform sampler2D tDiffuse;
		varying vec4 vUv;

		#include <logdepthbuf_pars_fragment>

		float blendOverlay( float base, float blend ) {

			return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );

		}

		vec3 blendOverlay( vec3 base, vec3 blend ) {

			return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );

		}

		void main() {

			#include <logdepthbuf_fragment>

			vec4 base = texture2DProj( tDiffuse, vUv );
			gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );

			#include <tonemapping_fragment>
			#include <colorspace_fragment>

		}`
};

export Reflector;