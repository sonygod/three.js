import three.js.examples.jsm.effects.AnaglyphEffect;

class AnaglyphEffect {

    var colorMatrixLeft:Matrix3;
    var colorMatrixRight:Matrix3;
    var _camera:OrthographicCamera;
    var _scene:Scene;
    var _stereo:StereoCamera;
    var _params:{ minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat };
    var _renderTargetL:WebGLRenderTarget;
    var _renderTargetR:WebGLRenderTarget;
    var _material:ShaderMaterial;
    var _mesh:Mesh;

    public function new(renderer:Renderer, width:Int = 512, height:Int = 512) {

        colorMatrixLeft = new Matrix3().fromArray([
            0.456100, - 0.0400822, - 0.0152161,
            0.500484, - 0.0378246, - 0.0205971,
            0.176381, - 0.0157589, - 0.00546856
        ]);

        colorMatrixRight = new Matrix3().fromArray([
            - 0.0434706, 0.378476, - 0.0721527,
            - 0.0879388, 0.73364, - 0.112961,
            - 0.00155529, - 0.0184503, 1.2264
        ]);

        _camera = new OrthographicCamera(- 1, 1, 1, - 1, 0, 1);

        _scene = new Scene();

        _stereo = new StereoCamera();

        _params = { minFilter: LinearFilter, magFilter: NearestFilter, format: RGBAFormat };

        _renderTargetL = new WebGLRenderTarget(width, height, _params);
        _renderTargetR = new WebGLRenderTarget(width, height, _params);

        _material = new ShaderMaterial({

            uniforms: {

                'mapLeft': { value: _renderTargetL.texture },
                'mapRight': { value: _renderTargetR.texture },

                'colorMatrixLeft': { value: colorMatrixLeft },
                'colorMatrixRight': { value: colorMatrixRight }

            },

            vertexShader: [

                'varying vec2 vUv;',

                'void main() {',

                '	vUv = vec2( uv.x, uv.y );',
                '	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',

                '}'

            ].join('\n'),

            fragmentShader: [

                'uniform sampler2D mapLeft;',
                'uniform sampler2D mapRight;',
                'varying vec2 vUv;',

                'uniform mat3 colorMatrixLeft;',
                'uniform mat3 colorMatrixRight;',

                'void main() {',

                '	vec2 uv = vUv;',

                '	vec4 colorL = texture2D( mapLeft, uv );',
                '	vec4 colorR = texture2D( mapRight, uv );',

                '	vec3 color = clamp(',
                '			colorMatrixLeft * colorL.rgb +',
                '			colorMatrixRight * colorR.rgb, 0., 1. );',

                '	gl_FragColor = vec4(',
                '			color.r, color.g, color.b,',
                '			max( colorL.a, colorR.a ) );',

                '	#include <tonemapping_fragment>',
                '	#include <colorspace_fragment>',

                '}'

            ].join('\n')

        });

        _mesh = new Mesh(new PlaneGeometry(2, 2), _material);
        _scene.add(_mesh);

        setSize = function (width:Int, height:Int) {

            renderer.setSize(width, height);

            var pixelRatio = renderer.getPixelRatio();

            _renderTargetL.setSize(width * pixelRatio, height * pixelRatio);
            _renderTargetR.setSize(width * pixelRatio, height * pixelRatio);

        };

        render = function (scene:Scene, camera:Camera) {

            var currentRenderTarget = renderer.getRenderTarget();

            if (scene.matrixWorldAutoUpdate === true) scene.updateMatrixWorld();

            if (camera.parent === null && camera.matrixWorldAutoUpdate === true) camera.updateMatrixWorld();

            _stereo.update(camera);

            renderer.setRenderTarget(_renderTargetL);
            renderer.clear();
            renderer.render(scene, _stereo.cameraL);

            renderer.setRenderTarget(_renderTargetR);
            renderer.clear();
            renderer.render(scene, _stereo.cameraR);

            renderer.setRenderTarget(null);
            renderer.render(_scene, _camera);

            renderer.setRenderTarget(currentRenderTarget);

        };

        dispose = function () {

            _renderTargetL.dispose();
            _renderTargetR.dispose();
            _mesh.geometry.dispose();
            _mesh.material.dispose();

        };

    }

}