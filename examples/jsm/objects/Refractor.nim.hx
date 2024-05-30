import three.js.examples.jsm.objects.Refractor;
import three.js.examples.jsm.shaders.RefractorShader;
import three.js.examples.jsm.utils.UniformsUtils;
import three.js.examples.jsm.math.Color;
import three.js.examples.jsm.math.Matrix4;
import three.js.examples.jsm.math.Plane;
import three.js.examples.jsm.math.Quaternion;
import three.js.examples.jsm.math.Vector3;
import three.js.examples.jsm.math.Vector4;
import three.js.examples.jsm.renderers.WebGLRenderTarget;
import three.js.examples.jsm.materials.ShaderMaterial;
import three.js.examples.jsm.cameras.PerspectiveCamera;
import three.js.examples.jsm.objects.Mesh;
import three.js.examples.jsm.constants.HalfFloatType;

class Refractor extends Mesh {

    public var camera:PerspectiveCamera;
    public var isRefractor:Bool;
    public var type:String;

    public function new(geometry:Geometry, options:Dynamic) {
        super(geometry);

        this.isRefractor = true;
        this.type = 'Refractor';
        this.camera = new PerspectiveCamera();

        var scope = this;

        var color:Color = (options.color !== undefined) ? new Color(options.color) : new Color(0x7F7F7F);
        var textureWidth:Int = options.textureWidth || 512;
        var textureHeight:Int = options.textureHeight || 512;
        var clipBias:Float = options.clipBias || 0;
        var shader:Dynamic = options.shader || RefractorShader;
        var multisample:Int = (options.multisample !== undefined) ? options.multisample : 4;

        //

        var virtualCamera:PerspectiveCamera = this.camera;
        virtualCamera.matrixAutoUpdate = false;
        virtualCamera.userData.refractor = true;

        //

        var refractorPlane:Plane = new Plane();
        var textureMatrix:Matrix4 = new Matrix4();

        // render target

        var renderTarget:WebGLRenderTarget = new WebGLRenderTarget(textureWidth, textureHeight, {samples: multisample, type: HalfFloatType});

        // material

        this.material = new ShaderMaterial({
            name: (shader.name !== undefined) ? shader.name : 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            transparent: true // ensures, refractors are drawn from farthest to closest
        });

        this.material.uniforms['color'].value = color;
        this.material.uniforms['tDiffuse'].value = renderTarget.texture;
        this.material.uniforms['textureMatrix'].value = textureMatrix;

        // functions

        var visible:Bool = (function () {
            var refractorWorldPosition:Vector3 = new Vector3();
            var cameraWorldPosition:Vector3 = new Vector3();
            var rotationMatrix:Matrix4 = new Matrix4();

            var view:Vector3 = new Vector3();
            var normal:Vector3 = new Vector3();

            return function visible(camera:PerspectiveCamera):Bool {
                refractorWorldPosition.setFromMatrixPosition(scope.matrixWorld);
                cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

                view.subVectors(refractorWorldPosition, cameraWorldPosition);

                rotationMatrix.extractRotation(scope.matrixWorld);

                normal.set(0, 0, 1);
                normal.applyMatrix4(rotationMatrix);

                return view.dot(normal) < 0;
            };
        })();

        var updateRefractorPlane:Void = (function () {
            var normal:Vector3 = new Vector3();
            var position:Vector3 = new Vector3();
            var quaternion:Quaternion = new Quaternion();
            var scale:Vector3 = new Vector3();

            return function updateRefractorPlane() {
                scope.matrixWorld.decompose(position, quaternion, scale);
                normal.set(0, 0, 1).applyQuaternion(quaternion).normalize();

                // flip the normal because we want to cull everything above the plane

                normal.negate();

                refractorPlane.setFromNormalAndCoplanarPoint(normal, position);
            };
        })();

        var updateVirtualCamera:Void = (function () {
            var clipPlane:Plane = new Plane();
            var clipVector:Vector4 = new Vector4();
            var q:Vector4 = new Vector4();

            return function updateVirtualCamera(camera:PerspectiveCamera) {
                virtualCamera.matrixWorld.copy(camera.matrixWorld);
                virtualCamera.matrixWorldInverse.copy(virtualCamera.matrixWorld).invert();
                virtualCamera.projectionMatrix.copy(camera.projectionMatrix);
                virtualCamera.far = camera.far; // used in WebGLBackground

                // The following code creates an oblique view frustum for clipping.
                // see: Lengyel, Eric. “Oblique View Frustum Depth Projection and Clipping”.
                // Journal of Game Development, Vol. 1, No. 2 (2005), Charles River Media, pp. 5–16

                clipPlane.copy(refractorPlane);
                clipPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

                clipVector.set(clipPlane.normal.x, clipPlane.normal.y, clipPlane.normal.z, clipPlane.constant);

                // calculate the clip-space corner point opposite the clipping plane and
                // transform it into camera space by multiplying it by the inverse of the projection matrix

                var projectionMatrix:Matrix4 = virtualCamera.projectionMatrix;

                q.x = (Math.sign(clipVector.x) + projectionMatrix.elements[8]) / projectionMatrix.elements[0];
                q.y = (Math.sign(clipVector.y) + projectionMatrix.elements[9]) / projectionMatrix.elements[5];
                q.z = -1.0;
                q.w = (1.0 + projectionMatrix.elements[10]) / projectionMatrix.elements[14];

                // calculate the scaled plane vector

                clipVector.multiplyScalar(2.0 / clipVector.dot(q));

                // replacing the third row of the projection matrix

                projectionMatrix.elements[2] = clipVector.x;
                projectionMatrix.elements[6] = clipVector.y;
                projectionMatrix.elements[10] = clipVector.z + 1.0 - clipBias;
                projectionMatrix.elements[14] = clipVector.w;
            };
        })();

        // This will update the texture matrix that is used for projective texture mapping in the shader.
        // see: http://developer.download.nvidia.com/assets/gamedev/docs/projective_texture_mapping.pdf

        function updateTextureMatrix(camera:PerspectiveCamera) {
            // this matrix does range mapping to [ 0, 1 ]

            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );

            // we use "Object Linear Texgen", so we need to multiply the texture matrix T
            // (matrix above) with the projection and view matrix of the virtual camera
            // and the model matrix of the refractor

            textureMatrix.multiply(camera.projectionMatrix);
            textureMatrix.multiply(camera.matrixWorldInverse);
            textureMatrix.multiply(scope.matrixWorld);
        }

        //

        function render(renderer:WebGLRenderer, scene:Scene, camera:PerspectiveCamera) {
            scope.visible = false;

            var currentRenderTarget:WebGLRenderTarget = renderer.getRenderTarget();
            var currentXrEnabled:Bool = renderer.xr.enabled;
            var currentShadowAutoUpdate:Bool = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false; // avoid camera modification
            renderer.shadowMap.autoUpdate = false; // avoid re-computing shadows

            renderer.setRenderTarget(renderTarget);
            if (renderer.autoClear === false) renderer.clear();
            renderer.render(scene, virtualCamera);

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;
            renderer.setRenderTarget(currentRenderTarget);

            // restore viewport

            var viewport:Rectangle = camera.viewport;

            if (viewport !== undefined) {
                renderer.state.viewport(viewport);
            }

            scope.visible = true;
        }

        //

        this.onBeforeRender = function (renderer:WebGLRenderer, scene:Scene, camera:PerspectiveCamera) {
            // ensure refractors are rendered only once per frame

            if (camera.userData.refractor === true) return;

            // avoid rendering when the refractor is viewed from behind

            if (!visible(camera) === true) return;

            // update

            updateRefractorPlane();

            updateTextureMatrix(camera);

            updateVirtualCamera(camera);

            render(renderer, scene, camera);
        };

        this.getRenderTarget = function () {
            return renderTarget;
        };

        this.dispose = function () {
            renderTarget.dispose();
            scope.material.dispose();
        };
    }
}