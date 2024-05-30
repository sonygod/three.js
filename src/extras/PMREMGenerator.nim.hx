import three.js.src.constants.CubeReflectionMapping;
import three.js.src.constants.CubeRefractionMapping;
import three.js.src.constants.CubeUVReflectionMapping;
import three.js.src.constants.LinearFilter;
import three.js.src.constants.NoToneMapping;
import three.js.src.constants.NoBlending;
import three.js.src.constants.RGBAFormat;
import three.js.src.constants.HalfFloatType;
import three.js.src.constants.BackSide;
import three.js.src.constants.LinearSRGBColorSpace;

import three.js.src.core.BufferAttribute;
import three.js.src.core.BufferGeometry;
import three.js.src.objects.Mesh;
import three.js.src.cameras.OrthographicCamera;
import three.js.src.cameras.PerspectiveCamera;
import three.js.src.materials.ShaderMaterial;
import three.js.src.math.Vector3;
import three.js.src.math.Color;
import three.js.src.renderers.WebGLRenderTarget;
import three.js.src.materials.MeshBasicMaterial;
import three.js.src.geometries.BoxGeometry;

class PMREMGenerator {

    private var _renderer:WebGLRenderer;
    private var _pingPongRenderTarget:WebGLRenderTarget;

    private var _lodMax:Int;
    private var _cubeSize:Int;
    private var _lodPlanes:Array<BufferGeometry>;
    private var _sizeLods:Array<Int>;
    private var _sigmas:Array<Float>;

    private var _blurMaterial:ShaderMaterial;
    private var _cubemapMaterial:ShaderMaterial;
    private var _equirectMaterial:ShaderMaterial;

    public function new(renderer:WebGLRenderer) {
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

    // ... rest of the class methods

}