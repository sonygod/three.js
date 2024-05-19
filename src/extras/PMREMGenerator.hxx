package three.js.extras;

import three.js.constants.*;
import three.js.core.BufferAttribute;
import three.js.core.BufferGeometry;
import three.js.objects.Mesh;
import three.js.cameras.OrthographicCamera;
import three.js.cameras.PerspectiveCamera;
import three.js.materials.ShaderMaterial;
import three.js.math.Vector3;
import three.js.math.Color;
import three.js.renderers.WebGLRenderTarget;
import three.js.materials.MeshBasicMaterial;
import three.js.geometries.BoxGeometry;

class PMREMGenerator {

    var _renderer:Dynamic;
    var _pingPongRenderTarget:Dynamic;
    var _lodMax:Int;
    var _cubeSize:Int;
    var _lodPlanes:Array<Dynamic>;
    var _sizeLods:Array<Int>;
    var _sigmas:Array<Float>;
    var _blurMaterial:Dynamic;
    var _cubemapMaterial:Dynamic;
    var _equirectMaterial:Dynamic;

    public function new(renderer:Dynamic) {
        _renderer = renderer;
        _pingPongRenderTarget = null;
        _lodMax = 0;
        _cubeSize = 0;
        _lodPlanes = [];
        _sizeLods = [];
        _sigmas = [];
        _blurMaterial = null;
        _cubemapMaterial = null;
        _equirectMaterial = null;
    }

    public function fromScene(scene:Dynamic, sigma:Float = 0, near:Float = 0.1, far:Float = 100):Dynamic {
        var oldTarget = _renderer.getRenderTarget();
        var oldActiveCubeFace = _renderer.getActiveCubeFace();
        var oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
        var oldXrEnabled = _renderer.xr.enabled;

        _renderer.xr.enabled = false;

        _setSize(256);

        var cubeUVRenderTarget = _allocateTargets();
        cubeUVRenderTarget.depthBuffer = true;

        _sceneToCubeUV(scene, near, far, cubeUVRenderTarget);

        if (sigma > 0) {
            _blur(cubeUVRenderTarget, 0, 0, sigma);
        }

        _applyPMREM(cubeUVRenderTarget);
        _cleanup(cubeUVRenderTarget);

        return cubeUVRenderTarget;
    }

    public function fromEquirectangular(equirectangular:Dynamic, renderTarget:Dynamic = null):Dynamic {
        return _fromTexture(equirectangular, renderTarget);
    }

    public function fromCubemap(cubemap:Dynamic, renderTarget:Dynamic = null):Dynamic {
        return _fromTexture(cubemap, renderTarget);
    }

    public function compileCubemapShader():Void {
        if (_cubemapMaterial == null) {
            _cubemapMaterial = _getCubemapMaterial();
            _compileMaterial(_cubemapMaterial);
        }
    }

    public function compileEquirectangularShader():Void {
        if (_equirectMaterial == null) {
            _equirectMaterial = _getEquirectMaterial();
            _compileMaterial(_equirectMaterial);
        }
    }

    public function dispose():Void {
        _dispose();
        if (_cubemapMaterial != null) _cubemapMaterial.dispose();
        if (_equirectMaterial != null) _equirectMaterial.dispose();
    }

    private function _setSize(cubeSize:Int):Void {
        _lodMax = Math.floor(Math.log2(cubeSize));
        _cubeSize = Math.pow(2, _lodMax);
    }

    private function _dispose():Void {
        if (_blurMaterial != null) _blurMaterial.dispose();
        if (_pingPongRenderTarget != null) _pingPongRenderTarget.dispose();
        for (i in 0..._lodPlanes.length) {
            _lodPlanes[i].dispose();
        }
    }

    private function _cleanup(outputTarget:Dynamic):Void {
        _renderer.setRenderTarget(oldTarget, oldActiveCubeFace, oldActiveMipmapLevel);
        _renderer.xr.enabled = oldXrEnabled;
        outputTarget.scissorTest = false;
        _setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
    }

    private function _fromTexture(texture:Dynamic, renderTarget:Dynamic):Dynamic {
        var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);
        _setSize(isCubeTexture ? (texture.image.length == 0 ? 16 : (texture.image[0].width || texture.image[0].image.width)) : texture.image.width / 4);
        var oldTarget = _renderer.getRenderTarget();
        var oldActiveCubeFace = _renderer.getActiveCubeFace();
        var oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
        var oldXrEnabled = _renderer.xr.enabled;

        _renderer.xr.enabled = false;

        var cubeUVRenderTarget = renderTarget || _allocateTargets();
        _textureToCubeUV(texture, cubeUVRenderTarget);
        _applyPMREM(cubeUVRenderTarget);
        _cleanup(cubeUVRenderTarget);

        return cubeUVRenderTarget;
    }

    private function _allocateTargets():Dynamic {
        var width = 3 * Math.max(_cubeSize, 16 * 7);
        var height = 4 * _cubeSize;
        var params = {
            magFilter: LinearFilter,
            minFilter: LinearFilter,
            generateMipmaps: false,
            type: HalfFloatType,
            format: RGBAFormat,
            colorSpace: LinearSRGBColorSpace,
            depthBuffer: false
        };
        var cubeUVRenderTarget = _createRenderTarget(width, height, params);
        if (_pingPongRenderTarget == null || _pingPongRenderTarget.width != width || _pingPongRenderTarget.height != height) {
            if (_pingPongRenderTarget != null) {
                _dispose();
            }
            _pingPongRenderTarget = _createRenderTarget(width, height, params);
            var {sizeLods, lodPlanes, sigmas} = _createPlanes(_lodMax);
            _blurMaterial = _getBlurShader(_lodMax, width, height);
        }
        return cubeUVRenderTarget;
    }

    private function _compileMaterial(material:Dynamic):Void {
        var tmpMesh = new Mesh(_lodPlanes[0], material);
        _renderer.compile(tmpMesh, _flatCamera);
    }

    private function _sceneToCubeUV(scene:Dynamic, near:Float, far:Float, cubeUVRenderTarget:Dynamic):Void {
        var fov = 90;
        var aspect = 1;
        var cubeCamera = new PerspectiveCamera(fov, aspect, near, far);
        var upSign = [1, -1, 1, 1, 1, 1];
        var forwardSign = [1, 1, 1, -1, -1, -1];
        var renderer = _renderer;
        var originalAutoClear = renderer.autoClear;
        var toneMapping = renderer.toneMapping;
        var clearColor = new Color();
        renderer.getClearColor(clearColor);

        renderer.toneMapping = NoToneMapping;
        renderer.autoClear = false;

        var backgroundMaterial = new MeshBasicMaterial({
            name: 'PMREM.Background',
            side: BackSide,
            depthWrite: false,
            depthTest: false,
        });

        var backgroundBox = new Mesh(new BoxGeometry(), backgroundMaterial);

        var useSolidColor = false;
        var background = scene.background;

        if (background) {
            if (background.isColor) {
                backgroundMaterial.color.copy(background);
                scene.background = null;
                useSolidColor = true;
            }
        } else {
            backgroundMaterial.color.copy(clearColor);
            useSolidColor = true;
        }

        for (i in 0...6) {
            var col = i % 3;
            if (col == 0) {
                cubeCamera.up.set(0, upSign[i], 0);
                cubeCamera.lookAt(forwardSign[i], 0, 0);
            } else if (col == 1) {
                cubeCamera.up.set(0, 0, upSign[i]);
                cubeCamera.lookAt(0, forwardSign[i], 0);
            } else {
                cubeCamera.up.set(0, upSign[i], 0);
                cubeCamera.lookAt(0, 0, forwardSign[i]);
            }
            var size = _cubeSize;
            _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
            renderer.setRenderTarget(cubeUVRenderTarget);
            if (useSolidColor) {
                renderer.render(backgroundBox, cubeCamera);
            }
            renderer.render(scene, cubeCamera);
        }

        backgroundBox.geometry.dispose();
        backgroundBox.material.dispose();

        renderer.toneMapping = toneMapping;
        renderer.autoClear = originalAutoClear;
        scene.background = background;
    }

    private function _textureToCubeUV(texture:Dynamic, cubeUVRenderTarget:Dynamic):Void {
        var renderer = _renderer;
        var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);
        var material = isCubeTexture ? _cubemapMaterial : _equirectMaterial;
        var mesh = new Mesh(_lodPlanes[0], material);
        var uniforms = material.uniforms;
        uniforms['envMap'].value = texture;
        var size = _cubeSize;
        _setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);
        renderer.setRenderTarget(cubeUVRenderTarget);
        renderer.render(mesh, _flatCamera);
    }

    private function _applyPMREM(cubeUVRenderTarget:Dynamic):Void {
        var renderer = _renderer;
        var autoClear = renderer.autoClear;
        renderer.autoClear = false;
        var n = _lodPlanes.length;
        for (i in 1...n) {
            var sigma = Math.sqrt(_sigmas[i] * _sigmas[i] - _sigmas[i - 1] * _sigmas[i - 1]);
            var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];
            _blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
        }
        renderer.autoClear = autoClear;
    }

    private function _blur(targetIn:Dynamic, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3):Void {
        _halfBlur(targetIn, _pingPongRenderTarget, lodIn, lodOut, sigma, 'latitudinal', poleAxis);
        _halfBlur(_pingPongRenderTarget, targetIn, lodOut, lodOut, sigma, 'longitudinal', poleAxis);
    }

    private function _halfBlur(targetIn:Dynamic, targetOut:Dynamic, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, poleAxis:Vector3):Void {
        var renderer = _renderer;
        var blurMaterial = _blurMaterial;
        var blurMesh = new Mesh(_lodPlanes[lodOut], blurMaterial);
        var blurUniforms = blurMaterial.uniforms;
        var pixels = _sizeLods[lodIn] - 1;
        var radiansPerPixel = isFinite(sigmaRadians) ? Math.PI / (2 * pixels) : 2 * Math.PI / (2 * MAX_SAMPLES - 1);
        var sigmaPixels = sigmaRadians / radiansPerPixel;
        var samples = isFinite(sigmaRadians) ? 1 + Math.floor(STANDARD_DEVIATIONS * sigmaPixels) : MAX_SAMPLES;
        if (samples > MAX_SAMPLES) {
            trace(`sigmaRadians, ${sigmaRadians}, is too large and will clip, as it requested ${samples} samples when the maximum is set to ${MAX_SAMPLES}`);
        }
        var weights = [];
        var sum = 0;
        for (i in 0...MAX_SAMPLES) {
            var x = i / sigmaPixels;
            var weight = Math.exp(-x * x / 2);
            weights.push(weight);
            if (i == 0) {
                sum += weight;
            } else if (i < samples) {
                sum += 2 * weight;
            }
        }
        for (i in 0...weights.length) {
            weights[i] = weights[i] / sum;
        }
        blurUniforms['envMap'].value = targetIn.texture;
        blurUniforms['samples'].value = samples;
        blurUniforms['weights'].value = weights;
        blurUniforms['latitudinal'].value = direction == 'latitudinal';
        if (poleAxis) {
            blurUniforms['poleAxis'].value = poleAxis;
        }
        var {_lodMax} = this;
        blurUniforms['dTheta'].value = radiansPerPixel;
        blurUniforms['mipInt'].value = _lodMax - lodIn;
        var outputSize = _sizeLods[lodOut];
        var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
        var y = 4 * (_cubeSize - outputSize);
        _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
        renderer.setRenderTarget(targetOut);
        renderer.render(blurMesh, _flatCamera);
    }

}