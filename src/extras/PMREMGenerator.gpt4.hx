import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.constants.*;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.math.Color;
import three.math.Vector3;
import three.materials.MeshBasicMaterial;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.renderers.WebGLRenderTarget;
import three.geometries.BoxGeometry;

class PMREMGenerator {

    var _renderer:Dynamic;
    var _pingPongRenderTarget:WebGLRenderTarget;
    var _lodMax:Int;
    var _cubeSize:Int;
    var _lodPlanes:Array<BufferGeometry>;
    var _sizeLods:Array<Int>;
    var _sigmas:Array<Float>;
    var _blurMaterial:ShaderMaterial;
    var _cubemapMaterial:ShaderMaterial;
    var _equirectMaterial:ShaderMaterial;

    static var _flatCamera = new OrthographicCamera();
    static var _clearColor = new Color();
    static var _oldTarget:Dynamic = null;
    static var _oldActiveCubeFace:Int = 0;
    static var _oldActiveMipmapLevel:Int = 0;
    static var _oldXrEnabled:Bool = false;

    static var LOD_MIN:Int = 4;
    static var EXTRA_LOD_SIGMA = [0.125, 0.215, 0.35, 0.446, 0.526, 0.582];
    static var MAX_SAMPLES:Int = 20;
    static var PHI:Float = (1 + Math.sqrt(5)) / 2;
    static var INV_PHI:Float = 1 / PHI;

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

            var { _lodMax } = this;
            var temp = _createPlanes(_lodMax);
            this._sizeLods = temp.sizeLods;
            this._lodPlanes = temp.lodPlanes;
            this._sigmas = temp.sigmas;

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

        var backgroundMaterial = new MeshBasicMaterial({
            name: 'PMREM.Background',
            side: BackSide,
            depthWrite: false,
            depthTest: false
        });

        var boxGeometry = new BoxGeometry();
        var boxMesh = new Mesh(boxGeometry, backgroundMaterial);

        var currentBackground = scene.background;
        scene.background = null;

        for (var i in 0...6) {
            var col = i % 3;
            var row = Math.floor(i / 3);
            var color = currentBackground == null ? null : currentBackground.clone();

            if (currentBackground != null && currentBackground.isColor) {
                color.multiplyScalar(forwardSign[i]);
            }

            backgroundMaterial.color.copy(color || _clearColor);

            var viewport = {
                x: col * this._cubeSize,
                y: (3 - row) * this._cubeSize,
                z: this._cubeSize,
                w: this._cubeSize
            };

            _setViewport(cubeUVRenderTarget, viewport.x, viewport.y, viewport.z, viewport.w);
            renderer.setRenderTarget(cubeUVRenderTarget);
            renderer.clear();

            cubeCamera.up.set(0, upSign[i], 0);
            cubeCamera.position.set(0, 0, 0);
            cubeCamera.lookAt(this._axisDirections[i]);

            renderer.render(boxMesh, cubeCamera);
            renderer.render(scene, cubeCamera);
        }

        scene.background = currentBackground;

        backgroundMaterial.dispose();
        boxGeometry.dispose();

        renderer.toneMapping = toneMapping;
        renderer.setClearColor(_clearColor);
        renderer.autoClear = originalAutoClear;
    }

    // Other private methods _blur, _applyPMREM, _getCubemapMaterial, _getEquirectMaterial, _getBlurShader, _createRenderTarget, _createPlanes, _setViewport, _textureToCubeUV etc.
}