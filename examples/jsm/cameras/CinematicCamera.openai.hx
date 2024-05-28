package three.js.examples.jsm.cameras;

import three.Mesh;
import three.OrthographicCamera;
import three.PerspectiveCamera;
import three.PlaneGeometry;
import three.Scene;
import three.ShaderMaterial;
import three.UniformsUtils;
import three.WebGLRenderTarget;

class CinematicCamera extends PerspectiveCamera {
    public var type: String = 'CinematicCamera';
    public var postprocessing: {
        enabled: Bool,
        scene: Scene,
        camera: OrthographicCamera,
        rtTextureDepth: WebGLRenderTarget,
        rtTextureColor: WebGLRenderTarget,
        bokeh_uniforms: Dynamic,
        materialBokeh: ShaderMaterial,
        quad: Mesh
    };
    public var shaderSettings: {
        rings: Int,
        samples: Int
    };

    public function new(fov: Float, aspect: Float, near: Float, far: Float) {
        super(fov, aspect, near, far);

        postprocessing = {
            enabled: true
        };
        shaderSettings = {
            rings: 3,
            samples: 4
        };

        var depthShader:Dynamic = BokehDepthShader;

        materialDepth = new ShaderMaterial({
            uniforms: depthShader.uniforms,
            vertexShader: depthShader.vertexShader,
            fragmentShader: depthShader.fragmentShader
        });

        materialDepth.uniforms.get('mNear').value = near;
        materialDepth.uniforms.get('mFar').value = far;

        setLens();

        initPostProcessing();
    }

    public function setLens(?focalLength: Float = 35, ?filmGauge: Float = 35, ?fNumber: Float = 8, ?coc: Float = 0.019): Void {
        filmGauge = filmGauge;
        setFocalLength(focalLength);

        this.fNumber = fNumber;
        this.coc = coc;

        aperture = focalLength / this.fNumber;

        hyperFocal = (focalLength * focalLength) / (aperture * this.coc);
    }

    public function linearize(depth: Float): Float {
        var zfar: Float = far;
        var znear: Float = near;
        return -zfar * znear / (depth * (zfar - znear) - zfar);
    }

    public function smoothstep(near: Float, far: Float, depth: Float): Float {
        var x: Float = saturate((depth - near) / (far - near));
        return x * x * (3 - 2 * x);
    }

    public function saturate(x: Float): Float {
        return Math.max(0, Math.min(1, x));
    }

    public function focusAt(?focusDistance: Float = 20): Void {
        var focalLength: Float = getFocalLength();

        focus = focusDistance;

        nearPoint = (hyperFocal * focus) / (hyperFocal + (focus - focalLength));
        farPoint = (hyperFocal * focus) / (hyperFocal - (focus - focalLength));

        depthOfField = farPoint - nearPoint;

        if (depthOfField < 0) depthOfField = 0;

        sdistance = smoothstep(near, far, focus);

        ldistance = linearize(1 - sdistance);

        postprocessing.bokeh_uniforms.get('focalDepth').value = ldistance;
    }

    public function initPostProcessing(): Void {
        if (postprocessing.enabled) {
            postprocessing.scene = new Scene();

            postprocessing.camera = new OrthographicCamera(-window.innerWidth / 2, window.innerWidth / 2, window.innerHeight / 2, window.innerHeight / -2, -10000, 10000);

            postprocessing.scene.add(postprocessing.camera);

            postprocessing.rtTextureDepth = new WebGLRenderTarget(window.innerWidth, window.innerHeight);
            postprocessing.rtTextureColor = new WebGLRenderTarget(window.innerWidth, window.innerHeight);

            var bokeh_shader: Dynamic = BokehShader;

            postprocessing.bokeh_uniforms = UniformsUtils.clone(bokeh_shader.uniforms);

            postprocessing.bokeh_uniforms.get('tColor').value = postprocessing.rtTextureColor.texture;
            postprocessing.bokeh_uniforms.get('tDepth').value = postprocessing.rtTextureDepth.texture;

            postprocessing.bokeh_uniforms.get('manualdof').value = 0;
            postprocessing.bokeh_uniforms.get('shaderFocus').value = 0;

            postprocessing.bokeh_uniforms.get('fstop').value = 2.8;

            postprocessing.bokeh_uniforms.get('showFocus').value = 1;

            postprocessing.bokeh_uniforms.get('focalDepth').value = 0.1;

            postprocessing.bokeh_uniforms.get('znear').value = near;
            postprocessing.bokeh_uniforms.get('zfar').value = far;

            postprocessing.bokeh_uniforms.get('textureWidth').value = window.innerWidth;
            postprocessing.bokeh_uniforms.get('textureHeight').value = window.innerHeight;

            postprocessing.materialBokeh = new ShaderMaterial({
                uniforms: postprocessing.bokeh_uniforms,
                vertexShader: bokeh_shader.vertexShader,
                fragmentShader: bokeh_shader.fragmentShader,
                defines: {
                    RINGS: shaderSettings.rings,
                    SAMPLES: shaderSettings.samples,
                    DEPTH_PACKING: 1
                }
            });

            postprocessing.quad = new Mesh(new PlaneGeometry(window.innerWidth, window.innerHeight), postprocessing.materialBokeh);
            postprocessing.quad.position.z = -500;
            postprocessing.scene.add(postprocessing.quad);
        }
    }

    public function renderCinematic(scene: Scene, renderer: Dynamic): Void {
        if (postprocessing.enabled) {
            var currentRenderTarget: Dynamic = renderer.getRenderTarget();

            renderer.clear();

            scene.overrideMaterial = null;
            renderer.setRenderTarget(postprocessing.rtTextureColor);
            renderer.clear();
            renderer.render(scene, this);

            scene.overrideMaterial = materialDepth;
            renderer.setRenderTarget(postprocessing.rtTextureDepth);
            renderer.clear();
            renderer.render(scene, this);

            renderer.setRenderTarget(null);
            renderer.render(postprocessing.scene, postprocessing.camera);

            renderer.setRenderTarget(currentRenderTarget);
        }
    }
}