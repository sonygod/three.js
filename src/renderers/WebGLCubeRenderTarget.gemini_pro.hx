import three.constants.BackSide;
import three.constants.LinearFilter;
import three.constants.LinearMipmapLinearFilter;
import three.constants.NoBlending;
import three.geometries.BoxGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.renderers.WebGLRenderTarget;
import three.cameras.CubeCamera;
import three.textures.CubeTexture;
import three.shaders.UniformsUtils.cloneUniforms;

class WebGLCubeRenderTarget extends WebGLRenderTarget {

	public var isWebGLCubeRenderTarget:Bool = true;

	public function new(size:Float = 1, options:Dynamic = {}) {
		super(size, size, options);

		var image = { width: size, height: size, depth: 1 };
		var images:Array<Dynamic> = [image, image, image, image, image, image];

		this.texture = new CubeTexture(images, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

		// By convention -- likely based on the RenderMan spec from the 1990's -- cube maps are specified by WebGL (and three.js)
		// in a coordinate system in which positive-x is to the right when looking up the positive-z axis -- in other words,
		// in a left-handed coordinate system. By continuing this convention, preexisting cube maps continued to render correctly.

		// three.js uses a right-handed coordinate system. So environment maps used in three.js appear to have px and nx swapped
		// and the flag isRenderTargetTexture controls this conversion. The flip is not required when using WebGLCubeRenderTarget.texture
		// as a cube texture (this is detected when isRenderTargetTexture is set to true for cube textures).

		this.texture.isRenderTargetTexture = true;

		this.texture.generateMipmaps = if (options.generateMipmaps != null) options.generateMipmaps else false;
		this.texture.minFilter = if (options.minFilter != null) options.minFilter else LinearFilter;
	}

	public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):WebGLCubeRenderTarget {
		this.texture.type = texture.type;
		this.texture.colorSpace = texture.colorSpace;

		this.texture.generateMipmaps = texture.generateMipmaps;
		this.texture.minFilter = texture.minFilter;
		this.texture.magFilter = texture.magFilter;

		var shader = {
			uniforms: {
				tEquirect: { value: null }
			},
			vertexShader: /* glsl */`
				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,
			fragmentShader: /* glsl */`
				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`
		};

		var geometry = new BoxGeometry(5, 5, 5);

		var material = new ShaderMaterial({
			name: "CubemapFromEquirect",
			uniforms: cloneUniforms(shader.uniforms),
			vertexShader: shader.vertexShader,
			fragmentShader: shader.fragmentShader,
			side: BackSide,
			blending: NoBlending
		});

		material.uniforms.tEquirect.value = texture;

		var mesh = new Mesh(geometry, material);

		var currentMinFilter = texture.minFilter;

		// Avoid blurred poles
		if (texture.minFilter == LinearMipmapLinearFilter) texture.minFilter = LinearFilter;

		var camera = new CubeCamera(1, 10, this);
		camera.update(renderer, mesh);

		texture.minFilter = currentMinFilter;

		mesh.geometry.dispose();
		mesh.material.dispose();

		return this;
	}

	public function clear(renderer:Dynamic, color:Dynamic, depth:Dynamic, stencil:Dynamic):Void {
		var currentRenderTarget = renderer.getRenderTarget();

		for (i in 0...6) {
			renderer.setRenderTarget(this, i);

			renderer.clear(color, depth, stencil);
		}

		renderer.setRenderTarget(currentRenderTarget);
	}

}