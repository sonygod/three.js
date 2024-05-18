package three.js.objects;

import three.js.Color;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.PerspectiveCamera;
import three.js.Plane;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;
import three.js.Vector3;
import three.js.Vector4;
import three.js.WebGLRenderTarget;
import three.js.HalfFloatType;

class Reflector extends Mesh {
    public var isReflector:Bool = true;
    public var type:String = 'Reflector';
    public var camera:PerspectiveCamera;

    public function new(geometry:Geometry, ?options:Dynamic = {}) {
        super(geometry);

        color = (options.color != null) ? new Color(options.color) : new Color(0x7F7F7F);
        textureWidth = options.textureWidth || 512;
        textureHeight = options.textureHeight || 512;
        clipBias = options.clipBias || 0;
        shader = options.shader || Reflector.ReflectorShader;
        multisample = (options.multisample != null) ? options.multisample : 4;

        reflectorPlane = new Plane();
        normal = new Vector3();
        reflectorWorldPosition = new Vector3();
        cameraWorldPosition = new Vector3();
        rotationMatrix = new Matrix4();
        lookAtPosition = new Vector3(0, 0, -1);
        clipPlane = new Vector4();

        view = new Vector3();
        target = new Vector3();
        q = new Vector4();

        textureMatrix = new Matrix4();
        virtualCamera = camera;

        renderTarget = new WebGLRenderTarget(textureWidth, textureHeight, { samples: multisample, type: HalfFloatType });

        material = new ShaderMaterial({
            name: (shader.name != null) ? shader.name : 'unspecified',
            uniforms: UniformsUtils.clone(shader.uniforms),
            fragmentShader: shader.fragmentShader,
            vertexShader: shader.vertexShader
        });

        material.uniforms.get('tDiffuse').value = renderTarget.texture;
        material.uniforms.get('color').value = color;
        material.uniforms.get('textureMatrix').value = textureMatrix;

        this.material = material;

        onBeforeRender = function(renderer:Renderer, scene:Scene, camera:Camera) {
            reflectorWorldPosition.setFromMatrixPosition(this.matrixWorld);
            cameraWorldPosition.setFromMatrixPosition(camera.matrixWorld);

            rotationMatrix.extractRotation(this.matrixWorld);

            normal.set(0, 0, 1);
            normal.applyMatrix4(rotationMatrix);

            view.subVectors(reflectorWorldPosition, cameraWorldPosition);

            if (view.dot(normal) > 0) return;

            view.reflect(normal).negate();
            view.add(reflectorWorldPosition);

            rotationMatrix.extractRotation(camera.matrixWorld);

            lookAtPosition.set(0, 0, -1);
            lookAtPosition.applyMatrix4(rotationMatrix);
            lookAtPosition.add(cameraWorldPosition);

            target.subVectors(reflectorWorldPosition, lookAtPosition);
            target.reflect(normal).negate();
            target.add(reflectorWorldPosition);

            virtualCamera.position.copy(view);
            virtualCamera.up.set(0, 1, 0);
            virtualCamera.up.applyMatrix4(rotationMatrix);
            virtualCamera.up.reflect(normal);
            virtualCamera.lookAt(target);

            virtualCamera.far = camera.far; // Used in WebGLBackground

            virtualCamera.updateMatrixWorld();
            virtualCamera.projectionMatrix.copy(camera.projectionMatrix);

            textureMatrix.set(
                0.5, 0.0, 0.0, 0.5,
                0.0, 0.5, 0.0, 0.5,
                0.0, 0.0, 0.5, 0.5,
                0.0, 0.0, 0.0, 1.0
            );
            textureMatrix.multiply(virtualCamera.projectionMatrix);
            textureMatrix.multiply(virtualCamera.matrixWorldInverse);
            textureMatrix.multiply(this.matrixWorld);

            reflectorPlane.setFromNormalAndCoplanarPoint(normal, reflectorWorldPosition);
            reflectorPlane.applyMatrix4(virtualCamera.matrixWorldInverse);

            clipPlane.set(reflectorPlane.normal.x, reflectorPlane.normal.y, reflectorPlane.normal.z, reflectorPlane.constant);

            q.x = (Math.sign(clipPlane.x) + virtualCamera.projectionMatrix.elements[8]) / virtualCamera.projectionMatrix.elements[0];
            q.y = (Math.sign(clipPlane.y) + virtualCamera.projectionMatrix.elements[9]) / virtualCamera.projectionMatrix.elements[5];
            q.z = -1.0;
            q.w = (1.0 + virtualCamera.projectionMatrix.elements[10]) / virtualCamera.projectionMatrix.elements[14];

            clipPlane.multiplyScalar(2.0 / clipPlane.dot(q));

            virtualCamera.projectionMatrix.elements[2] = clipPlane.x;
            virtualCamera.projectionMatrix.elements[6] = clipPlane.y;
            virtualCamera.projectionMatrix.elements[10] = clipPlane.z + 1.0 - clipBias;
            virtualCamera.projectionMatrix.elements[14] = clipPlane.w;

            this.visible = false;

            var currentRenderTarget = renderer.getRenderTarget();

            var currentXrEnabled = renderer.xr.enabled;
            var currentShadowAutoUpdate = renderer.shadowMap.autoUpdate;

            renderer.xr.enabled = false; // Avoid camera modification
            renderer.shadowMap.autoUpdate = false; // Avoid re-computing shadows

            renderer.setRenderTarget(renderTarget);

            renderer.state.buffers.depth.setMask(true); // make sure the depth buffer is writable so it can be properly cleared, see #18897

            if (!renderer.autoClear) renderer.clear();
            renderer.render(scene, virtualCamera);

            renderer.xr.enabled = currentXrEnabled;
            renderer.shadowMap.autoUpdate = currentShadowAutoUpdate;

            renderer.setRenderTarget(currentRenderTarget);

            this.visible = true;
        };

        getRenderTarget = function() {
            return renderTarget;
        };

        dispose = function() {
            renderTarget.dispose();
            material.dispose();
        };
    }

    public static var ReflectorShader = {
        name: 'ReflectorShader',
        uniforms: {
            color: {
                value: null
            },
            tDiffuse: {
                value: null
            },
            textureMatrix: {
                value: null
            }
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
            }',
        fragmentShader: '
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
            }'
    };
}