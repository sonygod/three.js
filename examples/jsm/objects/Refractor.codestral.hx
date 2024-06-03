import three.Color;
import three.Matrix4;
import three.Mesh;
import three.PerspectiveCamera;
import three.Plane;
import three.Quaternion;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.Vector3;
import three.Vector4;
// import three.WebGLRenderTarget;
// import three.HalfFloatType;

class Refractor extends Mesh {
    public var isRefractor:Bool;
    public var type:String;
    public var camera:PerspectiveCamera;

    public function new(geometry:three.Geometry, options:haxe.ds.StringMap<Dynamic> = null) {
        super(geometry);

        this.isRefractor = true;
        this.type = 'Refractor';
        this.camera = new PerspectiveCamera();

        var scope = this;

        var color = (options != null && options.exists('color')) ? new Color(options.get('color')) : new Color(0x7F7F7F);
        var textureWidth = (options != null && options.exists('textureWidth')) ? options.get('textureWidth') : 512;
        var textureHeight = (options != null && options.exists('textureHeight')) ? options.get('textureHeight') : 512;
        var clipBias = (options != null && options.exists('clipBias')) ? options.get('clipBias') : 0;
        var shader = (options != null && options.exists('shader')) ? options.get('shader') : Refractor.RefractorShader;
        var multisample = (options != null && options.exists('multisample')) ? options.get('multisample') : 4;

        var virtualCamera = this.camera;
        virtualCamera.matrixAutoUpdate = false;
        virtualCamera.userData['refractor'] = true;

        var refractorPlane = new Plane();
        var textureMatrix = new Matrix4();

        // render target
        // var renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

        // material
        this.material = new ShaderMaterial({
            name: (shader.name != null) ? shader.name : 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true
        });

        this.material.uniforms['color'].value = color;
        // this.material.uniforms['tDiffuse'].value = renderTarget.texture;
        this.material.uniforms['textureMatrix'].value = textureMatrix;

        // functions
        var visible = function(camera) {
            var refractorWorldPosition = new Vector3();
            var cameraWorldPosition = new Vector3();
            var rotationMatrix = new Matrix4();

            var view = new Vector3();
            var normal = new Vector3();

            refractorWorldPosition.setFromMatrixPosition(scope.matrixWorld);
            cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

            view.subVectors(refractorWorldPosition, cameraWorldPosition);

            rotationMatrix.extractRotation(scope.matrixWorld);

            normal.set(0, 0, 1);
            normal.applyMatrix4(rotationMatrix);

            return view.dot(normal) < 0;
        };

        var updateRefractorPlane = function() {
            var normal = new Vector3();
            var position = new Vector3();
            var quaternion = new Quaternion();
            var scale = new Vector3();

            scope.matrixWorld.decompose(position, quaternion, scale);
            normal.set(0, 0, 1).applyQuaternion(quaternion).normalize();

            normal.negate();

            refractorPlane.setFromNormalAndCoplanarPoint(normal, position);
        };

        var updateVirtualCamera = function(camera) {
            var clipPlane = new Plane();
            var clipVector = new Vector4();
            var q = new Vector4();

            virtualCamera.matrixWorld.copy(camera.matrixWorld);
            virtualCamera.matrixWorldInverse.copy(virtualCamera.matrixWorld).invert();
            virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
            virtualCamera.far = camera.far;

            clipPlane.copy(refractorPlane);
            clipPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

            clipVector.set(clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.constant);

            var projectionMatrix = virtualCamera.projectionMatrix;

            q.x = (Math.sign(clipVector.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
            q.y = (Math.sign(clipVector.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
            q.z = -1.0;
            q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

            clipVector.multiplyScalar(2.0 / clipVector.dot(q));

            projectionMatrix.elements[2] = clipVector.x;
            projectionMatrix.elements[6] = clipVector.y;
            projectionMatrix.elements[10] = clipVector.z + 1.0 - clipBias;
            projectionMatrix.elements[14] = clipVector.w;
        };

        var updateTextureMatrix = function(camera) {
            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );

            textureMatrix.multiply(camera.projectionMatrix);
            textureMatrix.multiply(camera.matrixWorldInverse);
            textureMatrix.multiply(scope.matrixWorld);
        };

        var render = function(renderer, scene, camera) {
            scope.visible = false;

            var currentRenderTarget = renderer.getRenderTarget();
            var currentXrEnabled = renderer.xr.enabled;
            var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false;
            renderer.shadowMap.autoUpdate = false;

            // renderer.setRenderTarget(renderTarget);
            // if (renderer.autoClear === false) renderer.clear();
            // renderer.render(scene, virtualCamera);

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
            renderer.setRenderTarget(currentRenderTarget);

            var viewport = camera.viewport;

            if (viewport != null) {
                // renderer.state.viewport(viewport);
            }

            scope.visible = true;
        };

        this.onBeforeRender = function(renderer, scene, camera) {
            if (camera.userData['refractor'] == true) return;

            if (!visible(camera)) return;

            updateRefractorPlane();
            updateTextureMatrix(camera);
            updateVirtualCamera(camera);
            render(renderer, scene, camera);
        };

        this.getRenderTarget = function() {
            // return renderTarget;
            return null;
        };

        this.dispose = function() {
            // renderTarget.dispose();
            scope.material.dispose();
        };
    }
}

class RefractorShader {
    public static var RefractorShader:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap<Dynamic>();

    static {
        RefractorShader.set('name', 'RefractorShader');

        var uniforms = new haxe.ds.StringMap<Dynamic>();
        uniforms.set('color', { value: null });
        uniforms.set('tDiffuse', { value: null });
        uniforms.set('textureMatrix', { value: null });
        RefractorShader.set('uniforms', uniforms);

        RefractorShader.set('vertexShader', `
            uniform mat4 textureMatrix;
            varying vec4 vUv;
            void main() {
                vUv = textureMatrix * vec4(position, 1.0);
                gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
            }`);

        RefractorShader.set('fragmentShader', `
            uniform vec3 color;
            uniform sampler2D tDiffuse;
            varying vec4 vUv;
            float blendOverlay(float base, float blend) {
                return(base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend)));
            }
            vec3 blendOverlay(vec3 base, vec3 blend) {
                return vec3(blendOverlay(base.r, blend.r), blendOverlay(base.g, blend.g), blendOverlay(base.b, blend.b));
            }
            void main() {
                vec4 base = texture2DProj(tDiffuse, vUv);
                gl_FragColor = vec4(blendOverlay(base.rgb, color), 1.0);
                #include <tonemapping_fragment>
                #include <colorspace_fragment>
            }`);
    }
}