import three.examples.jsm.renderers.common.extras.PMREMUtils.*;
import three.examples.jsm.nodes.materials.NodeMaterial;
import three.examples.jsm.nodes.pmrem.PMREMUtils.*;
import three.examples.jsm.nodes.utils.EquirectUVNode.*;
import three.examples.jsm.nodes.core.UniformNode.*;
import three.examples.jsm.nodes.accessors.UniformsNode.*;
import three.examples.jsm.nodes.accessors.TextureNode.*;
import three.examples.jsm.nodes.accessors.CubeTextureNode.*;
import three.examples.jsm.nodes.shadernode.ShaderNode.*;
import three.examples.jsm.nodes.accessors.UVNode.*;
import three.examples.jsm.nodes.core.AttributeNode.*;
import three.OrthographicCamera;
import three.Color;
import three.Vector3;
import three.BufferGeometry;
import three.BufferAttribute;
import three.RenderTarget;
import three.Mesh;
import three.CubeReflectionMapping;
import three.CubeRefractionMapping;
import three.CubeUVReflectionMapping;
import three.LinearFilter;
import three.NoBlending;
import three.RGBAFormat;
import three.HalfFloatType;
import three.BackSide;
import three.LinearSRGBColorSpace;
import three.PerspectiveCamera;
import three.MeshBasicMaterial;
import three.BoxGeometry;

class PMREMGenerator {

    var _renderer:Renderer;
    var _pingPongRenderTarget:RenderTarget;
    var _lodMax:Int;
    var _cubeSize:Int;
    var _lodPlanes:Array<BufferGeometry>;
    var _sizeLods:Array<Int>;
    var _sigmas:Array<Float>;
    var _lodMeshes:Array<Mesh>;
    var _blurMaterial:NodeMaterial;
    var _cubemapMaterial:NodeMaterial;
    var _equirectMaterial:NodeMaterial;
    var _backgroundBox:Mesh;

    public function new(renderer:Renderer) {
        _renderer = renderer;
        _pingPongRenderTarget = null;
        _lodMax = 0;
        _cubeSize = 0;
        _lodPlanes = [];
        _sizeLods = [];
        _sigmas = [];
        _lodMeshes = [];
        _blurMaterial = null;
        _cubemapMaterial = null;
        _equirectMaterial = null;
        _backgroundBox = null;
    }

    public function fromScene(scene:Scene, sigma:Float = 0, near:Float = 0.1, far:Float = 100) {
        _oldTarget = _renderer.getRenderTarget();
        _oldActiveCubeFace = _renderer.getActiveCubeFace();
        _oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
        this._setSize(256);
        var cubeUVRenderTarget = this._allocateTargets();
        cubeUVRenderTarget.depthBuffer = true;
        this._sceneToCubeUV(scene, near, far, cubeUVRenderTarget);
        if (sigma > 0) {
            this._blur(cubeUVRenderTarget, 0, 0, sigma);
        }
        this._applyPMREM(cubeUVRenderTarget);
        this._cleanup(cubeUVRenderTarget);
        return cubeUVRenderTarget;
    }

    public function fromEquirectangular(equirectangular:Texture, renderTarget:RenderTarget = null) {
        return this._fromTexture(equirectangular, renderTarget);
    }

    public function fromCubemap(cubemap:Texture, renderTarget:RenderTarget = null) {
        return this._fromTexture(cubemap, renderTarget);
    }

    public function compileCubemapShader() {
        if (_cubemapMaterial == null) {
            _cubemapMaterial = _getCubemapMaterial();
            this._compileMaterial(_cubemapMaterial);
        }
    }

    public function compileEquirectangularShader() {
        if (_equirectMaterial == null) {
            _equirectMaterial = _getEquirectMaterial();
            this._compileMaterial(_equirectMaterial);
        }
    }

    public function dispose() {
        this._dispose();
        if (_cubemapMaterial != null) _cubemapMaterial.dispose();
        if (_equirectMaterial != null) _equirectMaterial.dispose();
        if (_backgroundBox != null) {
            _backgroundBox.geometry.dispose();
            _backgroundBox.material.dispose();
        }
    }

    private function _setSize(cubeSize:Int) {
        _lodMax = Math.floor(Math.log2(cubeSize));
        _cubeSize = Math.pow(2, _lodMax);
    }

    private function _dispose() {
        if (_blurMaterial != null) _blurMaterial.dispose();
        if (_pingPongRenderTarget != null) _pingPongRenderTarget.dispose();
        for (i in 0..._lodPlanes.length) {
            _lodPlanes[i].dispose();
        }
    }

    private function _cleanup(outputTarget:RenderTarget) {
        _renderer.setRenderTarget(_oldTarget, _oldActiveCubeFace, _oldActiveMipmapLevel);
        outputTarget.scissorTest = false;
        _setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
    }

    private function _fromTexture(texture:Texture, renderTarget:RenderTarget) {
        if (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping) {
            this._setSize(texture.image.length == 0 ? 16 : (texture.image[0].width || texture.image[0].image.width));
        } else { // Equirectangular
            this._setSize(texture.image.width / 4);
        }
        _oldTarget = _renderer.getRenderTarget();
        _oldActiveCubeFace = _renderer.getActiveCubeFace();
        _oldActiveMipmapLevel = _renderer.getActiveMipmapLevel();
        var cubeUVRenderTarget = renderTarget || this._allocateTargets();
        this._textureToCubeUV(texture, cubeUVRenderTarget);
        this._applyPMREM(cubeUVRenderTarget);
        this._cleanup(cubeUVRenderTarget);
        return cubeUVRenderTarget;
    }

    private function _allocateTargets() {
        var width = 3 * Math.max(_cubeSize, 16 * 7);
        var height = 4 * _cubeSize;
        var params = {
            magFilter: LinearFilter,
            minFilter: LinearFilter,
            generateMipmaps: false,
            type: HalfFloatType,
            format: RGBAFormat,
            colorSpace: LinearSRGBColorSpace,
            //depthBuffer: false
        };
        var cubeUVRenderTarget = _createRenderTarget(width, height, params);
        if (_pingPongRenderTarget == null || _pingPongRenderTarget.width != width || _pingPongRenderTarget.height != height) {
            if (_pingPongRenderTarget != null) {
                this._dispose();
            }
            _pingPongRenderTarget = _createRenderTarget(width, height, params);
            ({sizeLods: _sizeLods, lodPlanes: _lodPlanes, sigmas: _sigmas, lodMeshes: _lodMeshes} = _createPlanes(_lodMax));
            _blurMaterial = _getBlurShader(_lodMax, width, height);
        }
        return cubeUVRenderTarget;
    }

    private function _compileMaterial(material:NodeMaterial) {
        var tmpMesh = _lodMeshes[0];
        tmpMesh.material = material;
        _renderer.compile(tmpMesh, _flatCamera);
    }

    private function _sceneToCubeUV(scene:Scene, near:Float, far:Float, cubeUVRenderTarget:RenderTarget) {
        _cubeCamera.near = near;
        _cubeCamera.far = far;
        // px, py, pz, nx, ny, nz
        var upSign = [-1, 1, -1, -1, -1, -1];
        var forwardSign = [1, 1, 1, -1, -1, -1];
        var renderer = _renderer;
        var originalAutoClear = renderer.autoClear;
        renderer.getClearColor(_clearColor);
        renderer.autoClear = false;
        var backgroundBox = _backgroundBox;
        if (backgroundBox == null) {
            var backgroundMaterial = new MeshBasicMaterial({
                name: 'PMREM.Background',
                side: BackSide,
                depthWrite: false,
                depthTest: false
            });
            backgroundBox = new Mesh(new BoxGeometry(), backgroundMaterial);
        }
        var useSolidColor = false;
        var background = scene.background;
        if (background) {
            if (background.isColor) {
                backgroundBox.material.color.copy(background);
                scene.background = null;
                useSolidColor = true;
            }
        } else {
            backgroundBox.material.color.copy(_clearColor);
            useSolidColor = true;
        }
        renderer.setRenderTarget(cubeUVRenderTarget);
        renderer.clear();
        if (useSolidColor) {
            renderer.render(backgroundBox, _cubeCamera);
        }
        for (i in 0...6) {
            var col = i % 3;
            if (col == 0) {
                _cubeCamera.up.set(0, upSign[i], 0);
                _cubeCamera.lookAt(forwardSign[i], 0, 0);
            } else if (col == 1) {
                _cubeCamera.up.set(0, 0, upSign[i]);
                _cubeCamera.lookAt(0, forwardSign[i], 0);
            } else {
                _cubeCamera.up.set(0, upSign[i], 0);
                _cubeCamera.lookAt(0, 0, forwardSign[i]);
            }
            var size = _cubeSize;
            _setViewport(cubeUVRenderTarget, col * size, i > 2 ? size : 0, size, size);
            renderer.render(scene, _cubeCamera);
        }
        renderer.autoClear = originalAutoClear;
        scene.background = background;
    }

    private function _textureToCubeUV(texture:Texture, cubeUVRenderTarget:RenderTarget) {
        var renderer = _renderer;
        var isCubeTexture = (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping);
        if (isCubeTexture) {
            if (_cubemapMaterial == null) {
                _cubemapMaterial = _getCubemapMaterial(texture);
            }
        } else { // Equirectangular
            if (_equirectMaterial == null) {
                _equirectMaterial = _getEquirectMaterial(texture);
            }
        }
        var material = isCubeTexture ? _cubemapMaterial : _equirectMaterial;
        material.fragmentNode.value = texture;
        var mesh = _lodMeshes[0];
        mesh.material = material;
        var size = _cubeSize;
        _setViewport(cubeUVRenderTarget, 0, 0, 3 * size, 2 * size);
        renderer.setRenderTarget(cubeUVRenderTarget);
        renderer.render(mesh, _flatCamera);
    }

    private function _applyPMREM(cubeUVRenderTarget:RenderTarget) {
        var renderer = _renderer;
        var autoClear = renderer.autoClear;
        renderer.autoClear = false;
        var n = _lodPlanes.length;
        for (i in 1...n) {
            var sigma = Math.sqrt(_sigmas[i] * _sigmas[i] - _sigmas[i - 1] * _sigmas[i - 1]);
            var poleAxis = _axisDirections[(n - i - 1) % _axisDirections.length];
            this._blur(cubeUVRenderTarget, i - 1, i, sigma, poleAxis);
        }
        renderer.autoClear = autoClear;
    }

    private function _blur(cubeUVRenderTarget:RenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3) {
        this._halfBlur(cubeUVRenderTarget, _pingPongRenderTarget, lodIn, lodOut, sigma, 'latitudinal', poleAxis);
        this._halfBlur(_pingPongRenderTarget, cubeUVRenderTarget, lodOut, lodOut, sigma, 'longitudinal', poleAxis);
    }

    private function _halfBlur(targetIn:RenderTarget, targetOut:RenderTarget, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, poleAxis:Vector3) {
        var renderer = _renderer;
        var blurMaterial = _blurMaterial;
        if (direction != 'latitudinal' && direction != 'longitudinal') {
            trace('blur direction must be either latitudinal or longitudinal!');
        }
        var blurMesh = _lodMeshes[lodOut];
        blurMesh.material = blurMaterial;
        var blurUniforms = blurMaterial.uniforms;
        var pixels = _sizeLods[lodIn] - 1;
        var radiansPerPixel = isFinite(sigmaRadians) ? Math.PI / (2 * pixels) : 2 * Math.PI / (2 * MAX_SAMPLES - 1);
        var sigmaPixels = sigmaRadians / radiansPerPixel;
        var samples = isFinite(sigmaRadians) ? 1 + Math.floor(STANDARD_DEVIATIONS * sigmaPixels) : MAX_SAMPLES;
        if (samples > MAX_SAMPLES) {
            trace('sigmaRadians, $sigmaRadians, is too large and will clip, as it requested $samples samples when the maximum is set to $MAX_SAMPLES');
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
        targetIn.texture.frame = (targetIn.texture.frame || 0) + 1;
        blurUniforms.envMap.value = targetIn.texture;
        blurUniforms.samples.value = samples;
        blurUniforms.weights.array = weights;
        blurUniforms.latitudinal.value = direction == 'latitudinal' ? 1 : 0;
        if (poleAxis) {
            blurUniforms.poleAxis.value = poleAxis;
        }
        var outputSize = _sizeLods[lodOut];
        var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
        var y = 4 * (_cubeSize - outputSize);
        _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
        renderer.setRenderTarget(targetOut);
        renderer.render(blurMesh, _flatCamera);
    }

    // ... rest of the code ...

}