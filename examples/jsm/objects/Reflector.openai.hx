package three.js.objects;

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
    public var isReflector:Bool = true;
    public var type:String = 'Reflector';
    public var camera:PerspectiveCamera;

    public function new(geometry:Geometry, ?options:ReflectorOptions) {
        super(geometry);
        camera = new PerspectiveCamera();
        var scope:Reflector = this;

        var color:Color = options != null && options.color != null ? new Color(options.color) : new Color(0x7F7F7F);
        var textureWidth:Int = options != null ? options.textureWidth : 512;
        var textureHeight:Int = options != null ? options.textureHeight : 512;
        var clipBias:Float = options != null ? options.clipBias : 0;
        var shader:ShaderMaterial = options != null ? options.shader : Reflector.ReflectorShader;
        var multisample:Int = options != null ? options.multisample : 4;

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
        var virtualCamera:PerspectiveCamera = camera;

        var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples:multisample, type:HalfFloatType });

        var material:ShaderMaterial = new ShaderMaterial({
            name: shader.name,
            uniforms: UniformsUtils.clone(shader.uniforms),
            fragmentShader: shader.fragmentShader,
            vertexShader: shader.vertexShader
        });

        material.uniforms['tDiffuse'].value = renderTarget.texture;
        material.uniforms['color'].value = color;
        material.uniforms['textureMatrix'].value = textureMatrix;

        this.material = material;

        this.onBeforeRender = function(renderer:.renderer, scene:Scene, camera:Camera) {
            // ...
        };

        this.getRenderTarget = function() {
            return renderTarget;
        };

        this.dispose = function() {
            renderTarget.dispose();
            material.dispose();
        };
    }
}

class ReflectorOptions {
    public var color:Int;
    public var textureWidth:Int;
    public var textureHeight:Int;
    public var clipBias:Float;
    public var shader:ShaderMaterial;
    public var multisample:Int;
}

class Reflector {
    public static var ReflectorShader:ShaderMaterial = {
        name: 'ReflectorShader',
        uniforms: {
            color: { value: null },
            tDiffuse: { value: null },
            textureMatrix: { value: null }
        },
        vertexShader: '
            uniform mat4 textureMatrix;
            varying vec4 vUv;

            #include <common>
            #include <logdepthbuf_pars_vertex>

            void main() {
                vUv = textureMatrix * vec4(position, 1.0);
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);

                #include <logdepthbuf_vertex>
            }
        ',
        fragmentShader: '
            uniform vec3 color;
            uniform sampler2D tDiffuse;
            varying vec4 vUv;

            #include <logdepthbuf_pars_fragment>

            float blendOverlay(float base, float blend) {
                return base < 0.5 ? 2.0 * base * blend : 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
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
            }
        '
    };
}