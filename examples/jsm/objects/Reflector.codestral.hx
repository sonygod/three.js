import three.Color;
import three.Matrix4;
import three.Mesh;
import three.PerspectiveCamera;
import three.Plane;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector3;
import three.Vector4;
import three.WebGLRenderTarget;
import three.HalfFloatType;

class Reflector extends Mesh {
    public var camera: PerspectiveCamera;
    private var scope: Reflector;
    private var reflectorPlane: Plane;
    private var normal: Vector3;
    private var reflectorWorldPosition: Vector3;
    private var cameraWorldPosition: Vector3;
    private var rotationMatrix: Matrix4;
    private var lookAtPosition: Vector3;
    private var clipPlane: Vector4;
    private var view: Vector3;
    private var target: Vector3;
    private var q: Vector4;
    private var textureMatrix: Matrix4;
    private var virtualCamera: PerspectiveCamera;
    private var renderTarget: WebGLRenderTarget;

    public function new(geometry: three.Geometry, options:haxe.ds.StringMap<Dynamic> = null) {
        super(geometry);

        this.isReflector = true;
        this.type = 'Reflector';
        this.camera = new PerspectiveCamera();
        this.scope = this;
        this.reflectorPlane = new Plane();
        this.normal = new Vector3();
        this.reflectorWorldPosition = new Vector3();
        this.cameraWorldPosition = new Vector3();
        this.rotationMatrix = new Matrix4();
        this.lookAtPosition = new Vector3(0, 0, -1);
        this.clipPlane = new Vector4();
        this.view = new Vector3();
        this.target = new Vector3();
        this.q = new Vector4();
        this.textureMatrix = new Matrix4();
        this.virtualCamera = this.camera;

        var color: Color;
        if (options != null && options.exists('color')) {
            color = new Color(Std.parseInt(options.get('color')));
        } else {
            color = new Color(0x7F7F7F);
        }

        var textureWidth: Int = options != null && options.exists('textureWidth') ? Std.parseInt(options.get('textureWidth')) : 512;
        var textureHeight: Int = options != null && options.exists('textureHeight') ? Std.parseInt(options.get('textureHeight')) : 512;
        var clipBias: Float = options != null && options.exists('clipBias') ? options.get('clipBias') : 0;
        var shader: haxe.ds.StringMap<Dynamic> = options != null && options.exists('shader') ? cast options.get('shader') : Reflector.ReflectorShader;
        var multisample: Int = options != null && options.exists('multisample') ? Std.parseInt(options.get('multisample')) : 4;

        this.renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, {samples: multisample, type: HalfFloatType.HalfFloatType});

        var material = new ShaderMaterial({
            name: shader.get('name') != null ? shader.get('name') : 'unspecified',
            uniforms: UniformsUtils.clone(shader.get('uniforms')),
            fragmentShader: shader.get('fragmentShader'),
            vertexShader: shader.get('vertexShader')
        });

        material.uniforms['tDiffuse'].value = this.renderTarget.texture;
        material.uniforms['color'].value = color;
        material.uniforms['textureMatrix'].value = this.textureMatrix;

        this.material = material;

        this.onBeforeRender = function(renderer: three.WebGLRenderer, scene: three.Scene, camera: PerspectiveCamera) {
            // Implementation of onBeforeRender function goes here
        };

        this.getRenderTarget = function() {
            return this.renderTarget;
        };

        this.dispose = function() {
            this.renderTarget.dispose();
            this.material.dispose();
        };
    }
}

class ReflectorShader {
    public static var ReflectorShader: haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap<Dynamic>();
    static {
        ReflectorShader.set('name', 'ReflectorShader');
        ReflectorShader.set('uniforms', {
            'color': { value: null },
            'tDiffuse': { value: null },
            'textureMatrix': { value: null }
        });
        ReflectorShader.set('vertexShader', /* glsl */`
            uniform mat4 textureMatrix;
            varying vec4 vUv;

            #include <common>
            #include <logdepthbuf_pars_vertex>

            void main() {
                vUv = textureMatrix * vec4(position, 1.0);
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
                #include <logdepthbuf_vertex>
            }`);
        ReflectorShader.set('fragmentShader', /* glsl */`
            uniform vec3 color;
            uniform sampler2D tDiffuse;
            varying vec4 vUv;

            #include <logdepthbuf_pars_fragment>

            float blendOverlay(float base, float blend) {
                return (base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
            }

            vec3 blendOverlay(vec3 base, vec3 blend) {
                return vec3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
            }

            void main() {
                #include <logdepthbuf_fragment>
                vec4 base = texture2DProj(tDiffuse, vUv);
                gl_FragColor = vec4(blendOverlay(base.rgb, color), 1.0);
                #include <tonemapping_fragment>
                #include <colorspace_fragment>
            }`);
    }
}