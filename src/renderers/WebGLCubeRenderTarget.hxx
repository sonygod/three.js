package three.js.src.renderers;

import three.js.src.constants.*;
import three.js.src.objects.Mesh;
import three.js.src.geometries.BoxGeometry;
import three.js.src.materials.ShaderMaterial;
import three.js.src.renderers.shaders.UniformsUtils;
import three.js.src.renderers.WebGLRenderTarget;
import three.js.src.cameras.CubeCamera;
import three.js.src.textures.CubeTexture;

class WebGLCubeRenderTarget extends WebGLRenderTarget {

    public function new(size:Int = 1, options:Dynamic = {}) {
        super(size, size, options);

        this.isWebGLCubeRenderTarget = true;

        var image = { width: size, height: size, depth: 1 };
        var images = [ image, image, image, image, image, image ];

        this.texture = new CubeTexture(images, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

        this.texture.isRenderTargetTexture = true;

        this.texture.generateMipmaps = options.generateMipmaps !== undefined ? options.generateMipmaps : false;
        this.texture.minFilter = options.minFilter !== undefined ? options.minFilter : LinearFilter;
    }

    public function fromEquirectangularTexture(renderer:Dynamic, texture:Dynamic):WebGLCubeRenderTarget {

        this.texture.type = texture.type;
        this.texture.colorSpace = texture.colorSpace;

        this.texture.generateMipmaps = texture.generateMipmaps;
        this.texture.minFilter = texture.minFilter;
        this.texture.magFilter = texture.magFilter;

        var shader = {

            uniforms: {
                tEquirect: { value: null },
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

        var geometry = new BoxGeometry( 5, 5, 5 );

        var material = new ShaderMaterial( {

            name: 'CubemapFromEquirect',

            uniforms: UniformsUtils.cloneUniforms( shader.uniforms ),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            side: BackSide,
            blending: NoBlending

        } );

        material.uniforms.tEquirect.value = texture;

        var mesh = new Mesh( geometry, material );

        var currentMinFilter = texture.minFilter;

        if ( texture.minFilter === LinearMipmapLinearFilter ) texture.minFilter = LinearFilter;

        var camera = new CubeCamera( 1, 10, this );
        camera.update( renderer, mesh );

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