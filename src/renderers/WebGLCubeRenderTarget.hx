package renderers;

import three.constants.BackSide;
import three.constants.LinearFilter;
import three.constants.LinearMipmapLinearFilter;
import three.constants.NoBlending;
import three.objects.Mesh;
import three.geometries.BoxGeometry;
import three.materials.ShaderMaterial;
import three.shaders.UniformsUtils.cloneUniforms;
import three.renderers.WebGLRenderTarget;
import three.cameras.CubeCamera;
import three.textures.CubeTexture;

class WebGLCubeRenderTarget extends WebGLRenderTarget {

    public var isWebGLCubeRenderTarget:Bool = true;

    public function new(size:Int = 1, options:Dynamic = {}) {
        super(size, size, options);

        var image = { width: size, height: size, depth: 1 };
        var images:Array<Dynamic> = [image, image, image, image, image, image];

        texture = new CubeTexture(images, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

        texture.isRenderTargetTexture = true;

        texture.generateMipmaps = options.generateMipmaps != null ? options.generateMipmaps : false;
        texture.minFilter = options.minFilter != null ? options.minFilter : LinearFilter;
    }

    public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):WebGLCubeRenderTarget {
        texture.type = texture.type;
        texture.colorSpace = texture.colorSpace;

        texture.generateMipmaps = texture.generateMipmaps;
        texture.minFilter = texture.minFilter;
        texture.magFilter = texture.magFilter;

        var shader:Dynamic = {
            uniforms: {
                tEquirect: { value: null },
            },
            vertexShader: '
                varying vec3 vWorldDirection;

                vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
                    return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
                }

                void main() {
                    vWorldDirection = transformDirection( position, modelMatrix );
                    #include <begin_vertex>
                    #include <project_vertex>
                }
            ',
            fragmentShader: '
                uniform sampler2D tEquirect;

                varying vec3 vWorldDirection;

                #include <common>

                void main() {
                    vec3 direction = normalize( vWorldDirection );
                    vec2 sampleUV = equirectUv( direction );
                    gl_FragColor = texture2D( tEquirect, sampleUV );
                }
            '
        };

        var geometry = new BoxGeometry(5, 5, 5);

        var material = new ShaderMaterial({
            name: 'CubemapFromEquirect',
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

    public function clear(renderer:Dynamic, color:Dynamic, depth:Dynamic, stencil:Dynamic) {
        var currentRenderTarget = renderer.getRenderTarget();

        for (i in 0...6) {
            renderer.setRenderTarget(this, i);
            renderer.clear(color, depth, stencil);
        }

        renderer.setRenderTarget(currentRenderTarget);
    }
}