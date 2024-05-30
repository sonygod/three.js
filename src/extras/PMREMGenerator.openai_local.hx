import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.LinearFilter;
import three.constants.NoToneMapping;
import three.constants.NoBlending;
import three.constants.RGBAFormat;
import three.constants.HalfFloatType;
import three.constants.BackSide;
import three.constants.LinearSRGBColorSpace;

import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.objects.Mesh;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.materials.ShaderMaterial;
import three.math.Vector3;
import three.math.Color;
import three.renderers.WebGLRenderTarget;
import three.materials.MeshBasicMaterial;
import three.geometries.BoxGeometry;

class PMREMGenerator {

    static final LOD_MIN = 4;
    static final EXTRA_LOD_SIGMA = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];
    static final MAX_SAMPLES = 20;

    static var _flatCamera = new OrthographicCamera();
    static var _clearColor = new Color();
    static var _oldTarget = null;
    static var _oldActiveCubeFace = 0;
    static var _oldActiveMipmapLevel = 0;
    static var _oldXrEnabled = false;

    static final PHI = (1 + Math.sqrt(5)) / 2;
    static final INV_PHI = 1 / PHI;

    static var _axisDirections = [
        new Vector3(-PHI, INV_PHI, 0),
        new Vector3(PHI, INV_PHI, 0),
        new Vector3(-INV_PHI, 0, PHI),
        new Vector3(INV_PHI, 0, PHI),
        new Vector3(0, PHI, -INV_PHI),
        new Vector3(0, PHI, INV_PHI),
        new Vector3(-1, 1, -1),
        new Vector3(1, 1, -1),
        new Vector3(-1, 1, 1),
        new Vector3(1, 1, 1)
    ];

    public var _renderer:Dynamic;
    public var _pingPongRenderTarget:WebGLRenderTarget;
    public var _lodMax:Int;
    public var _cubeSize:Int;
    public var _lodPlanes:Array<BufferGeometry>;
    public var _sizeLods:Array<Int>;
    public var _sigmas:Array<Float>;
    public var _blurMaterial:ShaderMaterial;
    public var _cubemapMaterial:ShaderMaterial;
    public var _equirectMaterial:ShaderMaterial;

    public function new(renderer:Dynamic) {
        this._renderer = renderer;
        this._pingPongRenderTarget = null;
        this._lodMax = 0;
        this._cubeSize = 0;
        this._lodPlanes = [];
        this._sizeLods = [];
        this._sigmas = [];
        this._blurMaterial = null;
        this._cubemapMaterial = null;
        this._equirectMaterial = null;
        this._compileMaterial(this._blurMaterial);
    }

    public function fromScene(scene:Dynamic, sigma:Float = 0, near:Float = 0.1, far:Float = 100):WebGLRenderTarget {
        _oldTarget = this._renderer.getRenderTarget();
        _oldActiveCubeFace = this._renderer.getActiveCubeFace();
        _oldActiveMipmapLevel = this._renderer.getActiveMipmapLevel();
        _oldXrEnabled = this._renderer.xr.enabled;

        this._renderer.xr.enabled = false;

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

    public function fromEquirectangular(equirectangular:Dynamic, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        return this._fromTexture(equirectangular, renderTarget);
    }

    public function fromCubemap(cubemap:Dynamic, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        return this._fromTexture(cubemap, renderTarget);
    }

    public function compileCubemapShader():Void {
        if (this._cubemapMaterial == null) {
            this._cubemapMaterial = _getCubemapMaterial();
            this._compileMaterial(this._cubemapMaterial);
        }
    }

    public function compileEquirectangularShader():Void {
        if (this._equirectMaterial == null) {
            this._equirectMaterial = _getEquirectMaterial();
            this._compileMaterial(this._equirectMaterial);
        }
    }

    public function dispose():Void {
        this._dispose();

        if (this._cubemapMaterial != null) this._cubemapMaterial.dispose();
        if (this._equirectMaterial != null) this._equirectMaterial.dispose();
    }

    private function _setSize(cubeSize:Int):Void {
        this._lodMax = Math.floor(Math.log2(cubeSize));
        this._cubeSize = Math.pow(2, this._lodMax);
    }

    private function _dispose():Void {
        if (this._blurMaterial != null) this._blurMaterial.dispose();

        if (this._pingPongRenderTarget != null) this._pingPongRenderTarget.dispose();

        for (i in 0...this._lodPlanes.length) {
            this._lodPlanes[i].dispose();
        }
    }

    private function _cleanup(outputTarget:WebGLRenderTarget):Void {
        this._renderer.setRenderTarget(_oldTarget, _oldActiveCubeFace, _oldActiveMipmapLevel);
        this._renderer.xr.enabled = _oldXrEnabled;

        outputTarget.scissorTest = false;
        _setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
    }

    private function _fromTexture(texture:Dynamic, renderTarget:WebGLRenderTarget):WebGLRenderTarget {
        if (texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping) {
            this._setSize(texture.image.length == 0 ? 16 : (texture.image[0].width || texture.image[0].image.width));
        } else {
            this._setSize(texture.image.width / 4);
        }

        _oldTarget = this._renderer.getRenderTarget();
        _oldActiveCubeFace = this._renderer.getActiveCubeFace();
        _oldActiveMipmapLevel = this._renderer.getActiveMipmapLevel();
        _oldXrEnabled = this._renderer.xr.enabled;

        this._renderer.xr.enabled = false;

        var cubeUVRenderTarget = renderTarget != null ? renderTarget : this._allocateTargets();
        this._textureToCubeUV(texture, cubeUVRenderTarget);
        this._applyPMREM(cubeUVRenderTarget);
        this._cleanup(cubeUVRenderTarget);

        return cubeUVRenderTarget;
    }

    private function _allocateTargets():WebGLRenderTarget {
        var width = 3 * Math.max(this._cubeSize, 16 * 7);
        var height = 4 * this._cubeSize;

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

        if (this._pingPongRenderTarget == null || this._pingPongRenderTarget.width != width || this._pingPongRenderTarget.height != height) {
            if (this._pingPongRenderTarget != null) {
                this._dispose();
            }

            this._pingPongRenderTarget = _createRenderTarget(width, height, params);

            var _lodMax = this._lodMax;
            var result = _createPlanes(_lodMax);
            this._sizeLods = result.sizeLods;
            this._lodPlanes = result.lodPlanes;
            this._sigmas = result.sigmas;

            this._blurMaterial = _getBlurShader(_lodMax, width, height);
        }

        return cubeUVRenderTarget;
    }

    private function _compileMaterial(material:ShaderMaterial):Void {
        var tmpMesh = new Mesh(this._lodPlanes[0], material);
        this._renderer.compile(tmpMesh, _flatCamera);
    }

    private function _sceneToCubeUV(scene:Dynamic, near:Float, far:Float, cubeUVRenderTarget:WebGLRenderTarget):Void {
        var fov = 90;
        var aspect = 1;
        var cubeCamera = new PerspectiveCamera(fov, aspect, near, far);
        var upSign = [1, -1, 1, 1, 1, 1];
        var forwardSign = [1, 1, 1, -1, -1, -1];
        var renderer = this._renderer;

        var originalAutoClear = renderer.autoClear;
        var toneMapping = renderer.toneMapping;
        renderer.getClearColor(_clearColor);

        renderer.toneMapping = NoToneMapping;
        renderer.autoClear = false;

        var background = scene.background;
        scene.background = null;

        for (var i = 0; i < 6; i++) {
            var col = i % 3;
            var row = Math.floor(i / 3);
            _setViewport(cubeUVRenderTarget, col * this._cubeSize, row * this._cubeSize, this._cubeSize, this._cubeSize);

            cubeCamera.up.set(0, upSign[i], 0);
            cubeCamera.lookAt(new Vector3(forwardSign[i], 0, 0));

            renderer.setRenderTarget(cubeUVRenderTarget, i);
            renderer.clear();
            renderer.render(scene, cubeCamera);
        }

        scene.background = background;

        renderer.toneMapping = toneMapping;
        renderer.autoClear = originalAutoClear;
        renderer.setRenderTarget(null);
    }

    private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget):Void {
        var renderer = this._renderer;
        var blurMaterial = this._blurMaterial;
        var autoClear = renderer.autoClear;

        renderer.autoClear = false;

        for (var i = 1; i < this._lodPlanes.length; i++) {
            var sigma = Math.sqrt(this._sigmas[i] * this._sigmas[i] - this._sigmas[i - 1] * this._sigmas[i - 1]);

            _blur(cubeUVRenderTarget, i - 1, i, sigma);
        }

        renderer.autoClear = autoClear;
    }

    private function _textureToCubeUV(texture:Dynamic, cubeUVRenderTarget:WebGLRenderTarget):Void {
        var material = texture.mapping == CubeReflectionMapping || texture.mapping == CubeRefractionMapping
            ? _getCubemapMaterial()
            : _getEquirectMaterial();

        var mesh = new Mesh(new BoxGeometry(5, 5, 5), material);
        material.uniforms.envMap.value = texture;
        material.uniforms.flipEnvMap.value = texture.isRenderTargetTexture == false ? -1 : 1;
        material.uniforms.inputEncoding.value = texture.colorSpace;
        material.uniforms.outputEncoding.value = LinearSRGBColorSpace;

        if (texture.mapping == CubeUVReflectionMapping) {
            material.uniforms.boxProjection.value = 1;
        }

        _setViewport(cubeUVRenderTarget, 0, 0, cubeUVRenderTarget.width, cubeUVRenderTarget.height);

        _flatCamera.up.set(0, 1, 0);
        _flatCamera.lookAt(new Vector3(0, 0, -1));

        this._renderer.setRenderTarget(cubeUVRenderTarget);
        this._renderer.render(mesh, _flatCamera);
    }

    private function _blur(target:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float):Void {
        var pingPongRenderTarget = this._pingPongRenderTarget;
        var blurMaterial = this._blurMaterial;
        var sizeLods = this._sizeLods;
        var lodPlanes = this._lodPlanes;
        var renderer = this._renderer;

        var oldTarget = renderer.getRenderTarget();
        var oldActiveCubeFace = renderer.getActiveCubeFace();
        var oldActiveMipmapLevel = renderer.getActiveMipmapLevel();

        blurMaterial.uniforms.envMap.value = target.texture;
        blurMaterial.uniforms.tSize.value = sizeLods[lodIn];
        blurMaterial.uniforms.inputEncoding.value = LinearSRGBColorSpace;
        blurMaterial.uniforms.outputEncoding.value = LinearSRGBColorSpace;

        var lodMax = this._lodMax;
        var samples = Math.min(Math.max(Math.floor(sigma * 3.5), 1), MAX_SAMPLES);

        var halfKernel = Array.create(sigma, samples);
        for (var i = 0; i < halfKernel.length; i++) {
            halfKernel[i] = Math.exp(-(i * i) / (2 * sigma * sigma));
        }
        var halfSum = halfKernel.reduce((sum, val) => sum + val, 0);

        for (i = 0; i < halfKernel.length; i++) {
            halfKernel[i] /= halfSum;
        }

        var fullKernel = halfKernel.concat(halfKernel.slice(1).reverse());

        blurMaterial.defines.samples = fullKernel.length;
        blurMaterial.needsUpdate = true;

        blurMaterial.uniforms.kernel.value = fullKernel;

        _applyBlur(0, target, pingPongRenderTarget, blurMaterial, lodIn, lodMax, renderer);
        _applyBlur(1, pingPongRenderTarget, target, blurMaterial, lodIn, lodOut, renderer);

        renderer.setRenderTarget(oldTarget, oldActiveCubeFace, oldActiveMipmapLevel);
    }

    private function _applyBlur(direction:Int, targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, material:ShaderMaterial, lodIn:Int, lodMax:Int, renderer:Dynamic):Void {
        var lodPlanes = this._lodPlanes;
        var sizeLods = this._sizeLods;

        material.uniforms.direction.value = direction;

        for (var i = lodIn; i < lodMax; i++) {
            var halfSize = sizeLods[i] / 2;

            _setViewport(targetOut, 0, 0, halfSize, halfSize);

            material.uniforms.tSize.value = sizeLods[i];
            material.uniforms.envMap.value = targetIn.texture;
            material.uniforms.lodIn.value = i;

            renderer.setRenderTarget(targetOut, i + 1);
            renderer.render(lodPlanes[i], _flatCamera);

            material.uniforms.envMap.value = targetOut.texture;
        }
    }

    private function _setViewport(target:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int):Void {
        target.viewport.set(x, y, width, height);
        target.scissor.set(x, y, width, height);
    }

    private function _getCubemapMaterial():ShaderMaterial {
        return new ShaderMaterial({
            name: 'CubemapMaterial',
            uniforms: {
                envMap: { value: null },
                flipEnvMap: { value: -1 },
                inputEncoding: { value: LinearSRGBColorSpace },
                outputEncoding: { value: LinearSRGBColorSpace },
                boxProjection: { value: 0 }
            },
            vertexShader: "vertexShader",
            fragmentShader: "fragmentShader",
            blending: NoBlending,
            depthTest: false,
            depthWrite: false,
            side: BackSide
        });
    }

    private function _getEquirectMaterial():ShaderMaterial {
        return new ShaderMaterial({
            name: 'EquirectMaterial',
            uniforms: {
                envMap: { value: null },
                flipEnvMap: { value: -1 },
                inputEncoding: { value: LinearSRGBColorSpace },
                outputEncoding: { value: LinearSRGBColorSpace }
            },
            vertexShader: "vertexShader",
            fragmentShader: "fragmentShader",
            blending: NoBlending,
            depthTest: false,
            depthWrite: false,
            side: BackSide
        });
    }

    private function _createRenderTarget(width:Int, height:Int, params:Dynamic):WebGLRenderTarget {
        return new WebGLRenderTarget(width, height, params);
    }

    private function _createPlanes(lodMax:Int):Dynamic {
        var lodPlanes = [];
        var sizeLods = [];
        var sigmas = EXTRA_LOD_SIGMA.slice(0, lodMax);

        for (var i = 0; i <= lodMax; i++) {
            var sizeLod = Math.pow(2, lodMax - i);
            sizeLods.push(sizeLod);

            var lodPlane = new BufferGeometry();
            lodPlane.setAttribute("position", new BufferAttribute(new Float32Array([
                -1, -1, 1, -1, 1, 1,
                -1, -1, 1, 1, -1, 1
            ]), 2));
            lodPlanes.push(lodPlane);
        }

        return {
            lodPlanes: lodPlanes,
            sizeLods: sizeLods,
            sigmas: sigmas
        };
    }

    private function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
        return new ShaderMaterial({
            name: 'BlurShader',
            uniforms: {
                envMap: { value: null },
                direction: { value: 0 },
                lodIn: { value: 0 },
                tSize: { value: new Vector3(width, height, lodMax) },
                inputEncoding: { value: LinearSRGBColorSpace },
                outputEncoding: { value: LinearSRGBColorSpace },
                kernel: { value: [] }
            },
            vertexShader: "vertexShader",
            fragmentShader: "fragmentShader",
            blending: NoBlending,
            depthTest: false,
            depthWrite: false,
            side: BackSide
        });
    }
}