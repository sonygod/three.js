package three.js.examples.jsm.effects;

import haxe.ds.Vector;
import three.Mesh;
import three.Matrix3;
import three.OrthographicCamera;
import three.PlaneGeometry;
import three.RGBAFormat;
import three.Scene;
import three.ShaderMaterial;
import three.StereoCamera;
import three.WebGLRenderTarget;

class AnaglyphEffect {
    private var colorMatrixLeft:Matrix3;
    private var colorMatrixRight:Matrix3;
    private var camera:OrthographicCamera;
    private var scene:Scene;
    private var stereo:StereoCamera;
    private var renderTargetL:WebGLRenderTarget;
    private var renderTargetR:WebGLRenderTarget;
    private var material:ShaderMaterial;
    private var mesh:Mesh;

    public function new(renderer:Dynamic, width:Int = 512, height:Int = 512) {
        colorMatrixLeft = new Matrix3();
        colorMatrixLeft.fromArray([
            0.456100, -0.0400822, -0.0152161,
            0.500484, -0.0378246, -0.0205971,
            0.176381, -0.0157589, -0.00546856
        ]);

        colorMatrixRight = new Matrix3();
        colorMatrixRight.fromArray([
            -0.0434706, 0.378476, -0.0721527,
            -0.0879388, 0.73364, -0.112961,
            -0.00155529, -0.0184503, 1.2264
        ]);

        camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
        scene = new Scene();
        stereo = new StereoCamera();

        var params = { minFilter:LinearFilter, magFilter:NearestFilter, format:RGBAFormat };

        renderTargetL = new WebGLRenderTarget(width, height, params);
        renderTargetR = new WebGLRenderTarget(width, height, params);

        material = new ShaderMaterial({
            uniforms: {
                'mapLeft': { value: renderTargetL.texture },
                'mapRight': { value: renderTargetR.texture },
                'colorMatrixLeft': { value: colorMatrixLeft },
                'colorMatrixRight': { value: colorMatrixRight }
            },
            vertexShader: [
                'varying vec2 vUv;',
                'void main() {',
                '    vUv = vec2( uv.x, uv.y );',
                '    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
                '}'
            ].join('\n'),
            fragmentShader: [
                'uniform sampler2D mapLeft;',
                'uniform sampler2D mapRight;',
                'varying vec2 vUv;',
                'uniform mat3 colorMatrixLeft;',
                'uniform mat3 colorMatrixRight;',
                'void main() {',
                '    vec2 uv = vUv;',
                '    vec4 colorL = texture2D( mapLeft, uv );',
                '    vec4 colorR = texture2D( mapRight, uv );',
                '    vec3 color = clamp(colorMatrixLeft * colorL.rgb + colorMatrixRight * colorR.rgb, 0., 1.);',
                '    gl_FragColor = vec4(color.r, color.g, color.b, max(colorL.a, colorR.a));',
                '    #include <tonemapping_fragment>',
                '    #include <colorspace_fragment>',
                '}'
            ].join('\n')
        });

        mesh = new Mesh(new PlaneGeometry(2, 2), material);
        scene.add(mesh);

        setSize = function(width:Int, height:Int) {
            renderer.setSize(width, height);
            var pixelRatio = renderer.getPixelRatio();
            renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
            renderTargetR.setSize(width * pixelRatio, height * pixelRatio);
        };

        render = function(scene:Scene, camera:Camera) {
            var currentRenderTarget = renderer.getRenderTarget();
            if (scene.matrixWorldAutoUpdate === true) scene.updateMatrixWorld();
            if (camera.parent === null && camera.matrixWorldAutoUpdate === true) camera.updateMatrixWorld();
            stereo.update(camera);
            renderer.setRenderTarget(renderTargetL);
            renderer.clear();
            renderer.render(scene, stereo.cameraL);
            renderer.setRenderTarget(renderTargetR);
            renderer.clear();
            renderer.render(scene, stereo.cameraR);
            renderer.setRenderTarget(null);
            renderer.render(scene, camera);
            renderer.setRenderTarget(currentRenderTarget);
        };

        dispose = function() {
            renderTargetL.dispose();
            renderTargetR.dispose();
            mesh.geometry.dispose();
            mesh.material.dispose();
        };
    }
}