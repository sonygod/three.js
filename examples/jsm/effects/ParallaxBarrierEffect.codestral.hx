import three.LinearFilter;
import three.Mesh;
import three.NearestFilter;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.RGBAFormat;
import three.Scene;
import three.ShaderMaterial;
import three.StereoCamera;
import three.WebGLRenderTarget;

class ParallaxBarrierEffect {
    private var _camera: OrthographicCamera;
    private var _scene: Scene;
    private var _stereo: StereoCamera;
    private var _params: Dynamic;
    private var _renderTargetL: WebGLRenderTarget;
    private var _renderTargetR: WebGLRenderTarget;
    private var _material: ShaderMaterial;
    private var mesh: Mesh;

    public function new(renderer: /* placeholder for renderer type */) {
        _camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
        _scene = new Scene();
        _stereo = new StereoCamera();
        _params = { minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat };
        _renderTargetL = new WebGLRenderTarget(512, 512, _params);
        _renderTargetR = new WebGLRenderTarget(512, 512, _params);

        var uniforms = {
            'mapLeft': { value: _renderTargetL.texture },
            'mapRight': { value: _renderTargetR.texture }
        };

        var vertexShader = [
            'varying vec2 vUv;',
            'void main() {',
            '    vUv = vec2(uv.x, uv.y);',
            '    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);',
            '}'
        ].join('\n');

        var fragmentShader = [
            'uniform sampler2D mapLeft;',
            'uniform sampler2D mapRight;',
            'varying vec2 vUv;',
            'void main() {',
            '    vec2 uv = vUv;',
            '    if ((mod(gl_FragCoord.y, 2.0)) > 1.00) {',
            '        gl_FragColor = texture2D(mapLeft, uv);',
            '    } else {',
            '        gl_FragColor = texture2D(mapRight, uv);',
            '    }',
            '    #include <tonemapping_fragment>',
            '    #include <colorspace_fragment>',
            '}'
        ].join('\n');

        _material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });

        mesh = new Mesh(new PlaneGeometry(2, 2), _material);
        _scene.add(mesh);
    }

    public function setSize(width: Int, height: Int): Void {
        renderer.setSize(width, height);

        var pixelRatio = renderer.getPixelRatio();

        _renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
        _renderTargetR.setSize(width * pixelRatio, height * pixelRatio);
    }

    public function render(scene: Scene, camera: /* placeholder for camera type */): Void {
        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();

        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

        _stereo.update(camera);

        renderer.setRenderTarget(_renderTargetL);
        renderer.clear();
        renderer.render(scene, _stereo.cameraL);

        renderer.setRenderTarget(_renderTargetR);
        renderer.clear();
        renderer.render(scene, _stereo.cameraR);

        renderer.setRenderTarget(null);
        renderer.render(_scene, _camera);
    }
}