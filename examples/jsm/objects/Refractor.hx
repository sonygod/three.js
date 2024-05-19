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
    public var isRefractor:Bool;
    public var type:String;
    public var camera:PerspectiveCamera;
    public var material:ShaderMaterial;
    public var renderTarget:WebGLRenderTarget;

    public function new(geometry:Geometry, ?options:Dynamic) {
        super(geometry);

        isRefractor = true;
        type = 'Refractor';
        camera = new PerspectiveCamera();

        var color:Color = (options.color != null) ? new Color(options.color) : new Color(0x7F7F7F);
        var textureWidth:Int = options.textureWidth != null ? options.textureWidth : 512;
        var textureHeight:Int = options.textureHeight != null ? options.textureHeight : 512;
        var clipBias:Float = options.clipBias != null ? options.clipBias : 0;
        var shader:Dynamic = options.shader != null ? options.shader : Refractor.RefractorShader;
        var multisample:Int = options.multisample != null ? options.multisample : 4;

        var virtualCamera:PerspectiveCamera = camera;
        virtualCamera.matrixAutoUpdate = false;
        virtualCamera.userData.refractor = true;

        var refractorPlane:Plane = new Plane();
        var textureMatrix:Matrix4 = new Matrix4();

        renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

        material = new ShaderMaterial({
            name: shader.name != null ? shader.name : 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true
        });

        material.uniforms['color'].value = color;
        material.uniforms['tDiffuse'].value = renderTarget.texture;
        material.uniforms['textureMatrix'].value = textureMatrix;

        var visible:Dynamic = function(camera:PerspectiveCamera):Bool {
            var refractorWorldPosition:Vector3 = new Vector3();
            var cameraWorldPosition:Vector3 = new Vector3();
            var rotationMatrix:Matrix4 = new Matrix4();

            var view:Vector3 = new Vector3();
            var normal:Vector3 = new Vector3();

            refractorWorldPosition.setFromMatrixPosition(matrixWorld);
            cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

            view.subVectors(refractorWorldPosition, cameraWorldPosition);

            rotationMatrix.extractRotation(matrixWorld);

            normal.set(0, 0, 1);
            normal.applyMatrix4(rotationMatrix);

            return view.dot(normal) < 0;
        };

        var updateRefractorPlane:Dynamic = function():Void {
            var normal:Vector3 = new Vector3();
            var position:Vector3 = new Vector3();
            var quaternion:Quaternion = new Quaternion();
            var scale:Vector3 = new Vector3();

            matrixWorld.decompose(position, quaternion, scale);
            normal.set(0, 0, 1).applyQuaternion(quaternion).normalize();

            normal.negate();

            refractorPlane.setFromNormalAndCoplanarPoint(normal, position);
        };

        var updateVirtualCamera:Dynamic = function(camera:PerspectiveCamera):Void {
            var clipPlane:Plane = new Plane();
            var clipVector:Vector4 = new Vector4();
            var q:Vector4 = new Vector4();

            virtualCamera.matrixWorld.copy(camera.matrixWorld);
            virtualCamera.matrixWorldInverse.copy(virtualCamera.matrixWorld).invert();
            virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
            virtualCamera.far = camera.far;

            clipPlane.copy(refractorPlane);
            clipPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

            clipVector.set(clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.constant);

            q.x = (Math.sign(clipVector.x) + virtualCamera.projectionMatrix.elements[8]) / virtualCamera.projectionMatrix.elements[0];
            q.y = (Math.sign(clipVector.y) + virtualCamera.projectionMatrix.elements[9]) / virtualCamera.projectionMatrix.elements[5];
            q.z = -1.0;
            q.w = (1.0 + virtualCamera.projectionMatrix.elements[10]) / virtualCamera.projectionMatrix.elements[14];

            clipVector.multiplyScalar(2.0 / clipVector.dot(q));

            virtualCamera.projectionMatrix.elements[2] = clipVector.x;
            virtualCamera.projectionMatrix.elements[6] = clipVector.y;
            virtualCamera.projectionMatrix.elements[10] = clipVector.z + 1.0 - clipBias;
            virtualCamera.projectionMatrix.elements[14] = clipVector.w;
        };

        var updateTextureMatrix:Dynamic = function(camera:PerspectiveCamera):Void {
            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );

            textureMatrix.multiply(camera.projectionMatrix);
            textureMatrix.multiply(camera.matrixWorldInverse);
            textureMatrix.multiply(matrixWorld);
        };

        function render(renderer:Dynamic, scene:Dynamic, camera:PerspectiveCamera):Void {
            visible = false;

            var currentRenderTarget:Dynamic = renderer.getRenderTarget();
            var currentXrEnabled:Bool = renderer.xr.enabled;
            var currentShadowAutoUpdate:Bool = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false;
            renderer.shadowMap.autoUpdate = false;

            renderer.setRenderTarget(renderTarget);
            if (!renderer.autoClear) renderer.clear();
            renderer.render(scene, virtualCamera);

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
            renderer.setRenderTarget(currentRenderTarget);

            var viewport:Dynamic = camera.viewport;

            if (viewport != null) {
                renderer.state.viewport(viewport);
            }

            visible = true;
        }

        onBeforeRender = function(renderer:Dynamic, scene:Dynamic, camera:PerspectiveCamera):Void {
            if (camera.userData.refractor === true) return;

            if (!visible(camera)) return;

            updateRefractorPlane();
            updateTextureMatrix(camera);
            updateVirtualCamera(camera);
            render(renderer, scene, camera);
        };

        public function getRenderTarget():WebGLRenderTarget {
            return renderTarget;
        }

        public function dispose():Void {
            renderTarget.dispose();
            material.dispose();
        }
    }
}

class RefractorShader {
    public var name:String;
    public var uniforms:Dynamic;
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        name = 'RefractorShader';
        uniforms = {
            'color': { value: null },
            'tDiffuse': { value: null },
            'textureMatrix': { value: null }
        };

        vertexShader = "
            uniform mat4 textureMatrix;

            varying vec4 vUv;

            void main() {
                vUv = textureMatrix * vec4( position, 1.0 );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }";

        fragmentShader = "
            uniform vec3 color;
            uniform sampler2D tDiffuse;

            varying vec4 vUv;

            float blendOverlay( float base, float blend ) {
                return( base < 0.5 ? ( 2.0 * base * blend ) : ( 1.0 - 2.0 * ( 1.0 - base ) * ( 1.0 - blend ) ) );
            }

            vec3 blendOverlay( vec3 base, vec3 blend ) {
                return vec3( blendOverlay( base.r, blend.r ), blendOverlay( base.g, blend.g ), blendOverlay( base.b, blend.b ) );
            }

            void main() {
                vec4 base = texture2DProj( tDiffuse, vUv );
                gl_FragColor = vec4( blendOverlay( base.rgb, color ), 1.0 );

                #include <tonemapping_fragment>
                #include <colorspace_fragment>
            }";
    }
}