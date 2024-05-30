import js.three.Color;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.PerspectiveCamera;
import js.three.Plane;
import js.three.Quaternion;
import js.three.ShaderMaterial;
import js.three.UniformsUtils;
import js.three.Vector3;
import js.three.Vector4;
import js.three.WebGLRenderTarget;
import js.three.HalfFloatType;

class Refractor extends Mesh {
    public var isRefractor:Bool;
    public var type:String;
    public var camera:PerspectiveCamera;

    public function new(geometry:Dynamic, ?options:Dynamic) {
        super(geometry);

        isRefractor = true;
        type = 'Refractor';
        camera = PerspectiveCamera_construct();

        var scope = this;

        var color = if (options != null && options.color != null) Color_construct(options.color) else Color_construct(0x7F7F7F);
        var textureWidth = if (options != null) options.textureWidth else 512;
        var textureHeight = if (options != null) options.textureHeight else 512;
        var clipBias = if (options != null) options.clipBias else 0;
        var shader = if (options != null && options.shader != null) options.shader else Refractor.RefractorShader;
        var multisample = if (options != null) options.multisample else 4;

        var virtualCamera = camera;
        virtualCamera.matrixAutoUpdate = false;
        virtualCamera.userData.refractor = true;

        var refractorPlane = Plane_construct();
        var textureMatrix = Matrix4_construct();

        var renderTarget = WebGLRenderTarget_construct(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

        var material = ShaderMaterial_construct({
            name: if (shader.name != null) shader.name else 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true
        });

        material.uniforms.color.value = color;
        material.uniforms.tDiffuse.value = renderTarget.texture;
        material.uniforms.textureMatrix.value = textureMatrix;

        function visible(camera:PerspectiveCamera):Bool {
            var refractorWorldPosition = Vector3_construct();
            var cameraWorldPosition = Vector3_construct();
            var rotationMatrix = Matrix4_construct();
            var view = Vector3_construct();
            var normal = Vector3_construct();

            refractorWorldPosition.setFromMatrixPosition(scope.matrixWorld);
            cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

            view.subVectors(refractorWorldPosition, cameraWorldPosition);

            rotationMatrix.extractRotation(scope.matrixWorld);

            normal.set(0, 0, 1);
            normal.applyMatrix4(rotationMatrix);

            return view.dot(normal) < 0;
        }

        function updateRefractorPlane() {
            var normal = Vector3_construct();
            var position = Vector3_construct();
            var quaternion = Quaternion_construct();
            var scale = Vector3_construct();

            scope.matrixWorld.decompose(position, quaternion, scale);
            normal.set(0, 0, 1).applyQuaternion(quaternion).normalize();

            normal.negate();

            refractorPlane.setFromNormalAndCoplanarPoint(normal, position);
        }

        function updateVirtualCamera(camera:PerspectiveCamera) {
            virtualCamera.matrixWorld.copy(camera.matrixWorld);
            virtualCamera.matrixWorldInverse.copy(virtualCamera.matrixWorld).invert();
            virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
            virtualCamera.far = camera.far;

            var clipPlane = Plane_construct();
            var clipVector = Vector4_construct();
            var q = Vector4_construct();

            clipPlane.copy(refractorPlane);
            clipPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

            clipVector.set(clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.constant);

            var projectionMatrix = virtualCamera.projectionMatrix;

            q.x = (Std.parseFloat(clipVector.x) / projectionMatrix.elements[0]).sign + projectionMatrix.elements[8];
            q.y = (Std.parseFloat(clipVector.y) / projectionMatrix.elements[5]).sign + projectionMatrix.elements[9];
            q.z = -1.0;
            q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

            clipVector.multiplyScalar(2.0 / clipVector.dot(q));

            projectionMatrix.elements[2] = clipVector.x;
            projectionMatrix.elements[6] = clipVector.y;
            projectionMatrix.elements[10] = clipVector.z + 1.0 - clipBias;
            projectionMatrix.elements[14] = clipVector.w;
        }

        function updateTextureMatrix(camera:PerspectiveCamera) {
            textureMatrix.set(0.5, 0.0, 0.0, 0.5, 0.0, 0.5, 0.0, 0.5, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 0.0, 1.0);
            textureMatrix.multiply(camera.projectionMatrix);
            textureMatrix.multiply(camera.matrixWorldInverse);
            textureMatrix.multiply(scope.matrixWorld);
        }

        function render(renderer:Dynamic, scene:Dynamic, camera:PerspectiveCamera) {
            scope.visible = false;

            var currentRenderTarget = renderer.getRenderTarget();
            var currentXrEnabled = renderer.xr.enabled;
            var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false;
            renderer.shadowMap.autoUpdate = false;

            renderer.setRenderTarget(renderTarget);
            if (renderer.autoClear == false) renderer.clear();
            renderer.render(scene, virtualCamera);

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
            renderer.setRenderTarget(currentRenderTarget);

            var viewport = camera.viewport;
            if (viewport != null) {
                renderer.state.viewport(viewport);
            }

            scope.visible = true;
        }

        onBeforeRender = function(renderer:Dynamic, scene:Dynamic, camera:PerspectiveCamera) {
            if (camera.userData.refractor == true) return;
            if (!visible(camera)) return;

            updateRefractorPlane();
            updateTextureMatrix(camera);
            updateVirtualCamera(camera);
            render(renderer, scene, camera);
        }

        function getRenderTarget():WebGLRenderTarget {
            return renderTarget;
        }

        function dispose() {
            renderTarget.dispose();
            scope.material.dispose();
        }
    }

    static var RefractorShader:Dynamic = {
        name: 'RefractorShader',
        uniforms: {
            'color': { value: null },
            'tDiffuse': { value: null },
            'textureMatrix': { value: null }
        },
        vertexShader: """
            uniform mat4 textureMatrix;
            varying vec4 vUv;
            void main() {
                vUv = textureMatrix * vec4( position, 1.0 );
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        """,
        fragmentShader: """
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
            }
        """
    }
}