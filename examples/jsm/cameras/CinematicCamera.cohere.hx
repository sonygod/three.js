import js.three.Mesh;
import js.three.OrthographicCamera;
import js.three.PerspectiveCamera;
import js.three.PlaneGeometry;
import js.three.Scene;
import js.three.ShaderMaterial;
import js.three.WebGLRenderTarget;

import js.three.shaders.BokehShader;
import js.three.shaders.BokehDepthShader;

class CinematicCamera extends PerspectiveCamera {
    var postprocessing: { enabled: Bool, scene: Scene, camera: OrthographicCamera, rtTextureDepth: WebGLRenderTarget, rtTextureColor: WebGLRenderTarget, bokeh_uniforms: { tColor: Dynamic, tDepth: Dynamic, manualdof: Float, shaderFocus: Float, fstop: Float, showFocus: Float, focalDepth: Float, znear: Float, zfar: Float, textureWidth: Int, textureHeight: Int }, materialBokeh: ShaderMaterial, quad: Mesh };
    var shaderSettings: { rings: Int, samples: Int };

    public function new(fov: Float, aspect: Float, near: Float, far: Float) {
        super(fov, aspect, near, far);

        type = 'CinematicCamera';

        postprocessing = { enabled: true, scene: null, camera: null, rtTextureDepth: null, rtTextureColor: null, bokeh_uniforms: null, materialBokeh: null, quad: null };
        shaderSettings = { rings: 3, samples: 4 };

        var depthShader = BokehDepthShader;

        var materialDepth = new ShaderMaterial({ uniforms: depthShader.uniforms, vertexShader: depthShader.vertexShader, fragmentShader: depthShader.fragmentShader });

        materialDepth.uniforms['mNear'].value = near;
        materialDepth.uniforms['mFar'].value = far;

        setLens();

        initPostProcessing();
    }

    function setLens(focalLength: Float = 35, filmGauge: Float = 35, fNumber: Float = 8, coc: Float = 0.019) {
        filmGauge = filmGauge;

        setFocalLength(focalLength);

        fNumber = fNumber;
        coc = coc;

        aperture = focalLength / fNumber;

        hyperFocal = (focalLength * focalLength) / (aperture * coc);
    }

    function linearize(depth: Float) : Float {
        var zfar = far;
        var znear = near;
        return -zfar * znear / (depth * (zfar - znear) - zfar);
    }

    function smoothstep(near: Float, far: Float, depth: Float) : Float {
        var x = saturate((depth - near) / (far - near));
        return x * x * (3 - 2 * x);
    }

    function saturate(x: Float) : Float {
        return Math.max(0, Math.min(1, x));
    }

    function focusAt(focusDistance: Float = 20) {
        var focalLength = getFocalLength();

        focus = focusDistance;

        nearPoint = (hyperFocal * focus) / (hyperFocal + (focus - focalLength));

        farPoint = (hyperFocal * focus) / (hyperFocal - (focus - focalLength));

        depthOfField = farPoint - nearPoint;

        if (depthOfField < 0) {
            depthOfField = 0;
        }

        sdistance = smoothstep(near, far, focus);

        ldistance = linearize(1 - sdistance);

        postprocessing.bokeh_uniforms['focalDepth'].value = ldistance;
    }

    function initPostProcessing() {
        if (postprocessing.enabled) {
            postprocessing.scene = new Scene();

            postprocessing.camera = new OrthographicCamera(Std.int(Window.width / -2), Std.int(Window.width / 2), Std.int(Window.height / 2), Std.int(Window.height / -2), -10000, 10000);

            postprocessing.scene.add(postprocessing.camera);

            postprocessing.rtTextureDepth = new WebGLRenderTarget(Std.int(Window.width), Std.int(Window.height));
            postprocessing.rtTextureColor = new WebGLRenderTarget(Std.int(Window.width), Std.int(Window.height));

            var bokeh_shader = BokehShader;

            postprocessing.bokeh_uniforms = js.three.UniformsUtils.clone(bokeh_shader.uniforms);

            postprocessing.bokeh_uniforms['tColor'].value = postprocessing.rtTextureColor.texture;
            postprocessing.bokeh_uniforms['tDepth'].value = postprocessing.rtTextureDepth.texture;

            postprocessing.bokeh_uniforms['manualdof'].value = 0;
            postprocessing.bokeh_uniforms['shaderFocus'].value = 0;

            postprocessing.bokeh_uniforms['fstop'].value = 2.8;

            postprocessing.bokeh_uniforms['showFocus'].value = 1;

            postprocessing.bokeh_uniforms['focalDepth'].value = 0.1;

            postprocessing.bokeh_uniforms['znear'].value = near;
            postprocessing.bokeh_uniforms['zfar'].value = near;

            postprocessing.bokeh_uniforms['textureWidth'].value = Std.int(Window.width);

            postprocessing.bokeh_uniforms['textureHeight'].value = Std.int(Window.height);

            postprocessing.materialBokeh = new ShaderMaterial({ uniforms: postprocessing.bokeh_uniforms, vertexShader: bokeh_shader.vertexShader, fragmentShader: bokeh_shader.fragmentShader, defines: { RINGS: shaderSettings.rings, SAMPLES: shaderSettings.samples, DEPTH_PACKING: 1 } });

            postprocessing.quad = new Mesh(new PlaneGeometry(Std.int(Window.width), Std.int(Window.height)), postprocessing.materialBokeh);
            postprocessing.quad.position.z = -500;
            postprocessing.scene.add(postprocessing.quad);
        }
    }

    function renderCinematic(scene: Scene, renderer: js.three.WebGLRenderer) {
        if (postprocessing.enabled) {
            var currentRenderTarget = renderer.getRenderTarget();

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