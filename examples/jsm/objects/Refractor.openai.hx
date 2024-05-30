package three.js.objects;

import three.js.Color;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.PerspectiveCamera;
import three.js.Plane;
import three.js.Quaternion;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;
import three.js.Vector3;
import three.js.Vector4;
import three.js.WebGLRenderTarget;
import three.js.HalfFloatType;

class Refractor extends Mesh {
    public var isRefractor:Bool = true;
    public var type:String = 'Refractor';
    public var camera:PerspectiveCamera;

    public function new(geometry:Geometry, ?options:Dynamic) {
        super(geometry);

        camera = new PerspectiveCamera();

        var color:Color = (options != null && options.color != null) ? new Color(options.color) : new Color(0x7F7F7F);
        var textureWidth:Int = (options != null && options.textureWidth != null) ? options.textureWidth : 512;
        var textureHeight:Int = (options != null && options.textureHeight != null) ? options.textureHeight : 512;
        var clipBias:Float = (options != null && options.clipBias != null) ? options.clipBias : 0;
        var shader:Dynamic = (options != null && options.shader != null) ? options.shader : Refractor.RefractorShader;
        var multisample:Int = (options != null && options.multisample != null) ? options.multisample : 4;

        var virtualCamera:PerspectiveCamera = camera;
        virtualCamera.matrixAutoUpdate = false;
        virtualCamera.userData.refractor = true;

        var refractorPlane:Plane = new Plane();
        var textureMatrix:Matrix4 = new Matrix4();

        var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

        material = new ShaderMaterial({
            name: (shader.name != null) ? shader.name : 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true // ensures, refractors are drawn from farthest to closest
        });

        material.uniforms['color'].value = color;
        material.uniforms['tDiffuse'].value = renderTarget.texture;
        material.uniforms['textureMatrix'].value = textureMatrix;

        var visible:Bool->Void = function(camera:PerspectiveCamera) {
            // implementation omitted for brevity
        };

        var updateRefractorPlane:Void->Void = function() {
            // implementation omitted for brevity
        };

        var updateVirtualCamera:PerspectiveCamera->Void = function(camera:PerspectiveCamera) {
            // implementation omitted for brevity
        };

        var updateTextureMatrix:PerspectiveCamera->Void = function(camera:PerspectiveCamera) {
            // implementation omitted for brevity
        };

        var render:Renderer->Scene->PerspectiveCamera->Void = function(renderer:Renderer, scene:Scene, camera:PerspectiveCamera) {
            // implementation omitted for brevity
        };

        onBeforeRender = function(renderer:Renderer, scene:Scene, camera:PerspectiveCamera) {
            // implementation omitted for brevity
        };

        getRenderTarget = function() {
            return renderTarget;
        };

        dispose = function() {
            renderTarget.dispose();
            material.dispose();
        };
    }
}

class RefractorShader {
    public var name:String = 'RefractorShader';
    public var uniforms:Dynamic = {
        'color': { value: null },
        'tDiffuse': { value: null },
        'textureMatrix': { value: null }
    };
    public var vertexShader:String = '
        uniform mat4 textureMatrix;

        varying vec4 vUv;

        void main() {
            vUv = textureMatrix * vec4( position, 1.0 );
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }
    ';
    public var fragmentShader:String = '
        uniform vec3 color;
        uniform sampler2D tDiffuse;

        varying vec4 vUv;

        float blendOverlay( float base, float blend ) {
            // implementation omitted for brevity
        }

        vec3 blendOverlay( vec3 base, vec3 blend ) {
            // implementation omitted for brevity
        }

        void main() {
            // implementation omitted for brevity
        }
    ';
}