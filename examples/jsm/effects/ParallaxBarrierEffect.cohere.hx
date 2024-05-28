import js.three.WebGLRenderTarget;
import js.three.OrthographicCamera;
import js.three.ShaderMaterial;
import js.three.Scene;
import js.three.Mesh;
import js.three.PlaneGeometry;
import js.three.LinearFilter;
import js.three.NearestFilter;
import js.three.RGBAFormat;
import js.three.StereoCamera;

class ParallaxBarrierEffect {
    public function new(renderer:Dynamic) {
        var _camera = js.three.OrthographicCamera(-1, 1, 1, -1, 0, 1);
        var _scene = js.three.Scene();
        var _stereo = js.three.StereoCamera();
        var _params = { minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat };
        var _renderTargetL = WebGLRenderTarget(512, 512, _params);
        var _renderTargetR = WebGLRenderTarget(512, 512, _params);
        var _material = ShaderMaterial({
            uniforms: {
                mapLeft: { value: _renderTargetL.texture },
                mapRight: { value: _renderTargetR.texture }
            },
            vertexShader: [
                "varying vec2 vUv;",
                "void main() {",
                "vUv = vec2(uv.x, uv.y);",
                "gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);",
                "}"
            ].join("\n"),
            fragmentShader: [
                "uniform sampler2D mapLeft;",
                "uniform sampler2D mapRight;",
                "varying vec2 vUv;",
                "void main() {",
                "vec2 uv = vUv;",
                "if (mod(gl_FragCoord.y, 2.0) > 1.0) {",
                "gl_FragColor = texture2D(mapLeft, uv);",
                "} else {",
                "gl_FragColor = texture2D(mapRight, uv);",
                "}",
                "#include <tonemapping_fragment>",
                "#include <colorspace_fragment>",
                "}"
            ].join("\n")
        });
        var mesh = Mesh(PlaneGeometry(2, 2), _material);
        _scene.add(mesh);
        public function setSize(width:Int, height:Int) {
            renderer.setSize(width, height);
            var pixelRatio = renderer.getPixelRatio();
            _renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
            _renderTargetR.setSize(width * pixelRatio, height * pixelRatio);
        }
        public function render(scene:Dynamic, camera:Dynamic) {
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
}