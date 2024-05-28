package three.js.src.extras;

import three.js.constants.CubeReflectionMapping;
import three.js.constants.CubeRefractionMapping;
import three.js.constants.CubeUVReflectionMapping;
import three.js.constants.LinearFilter;
import three.js.constants.NoToneMapping;
import three.js.constants.NoBlending;
import three.js.constants.RGBAFormat;
import three.js.constants.HalfFloatType;
import three.js.constants.BackSide;
import three.js.constants.LinearSRGBColorSpace;

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
    private var _renderer:Dynamic;
    private var _pingPongRenderTarget:WebGLRenderTarget;
    private var _lodMax:Int;
    private var _cubeSize:Int;
    private var _lodPlanes:Array<BufferGeometry>;
    private var _sizeLods:Array<Int>;
    private var _sigmas:Array<Float>;
    private var _blurMaterial:ShaderMaterial;
    private var _cubemapMaterial:ShaderMaterial;
    private var _equirectMaterial:ShaderMaterial;

    public function new(renderer:Dynamic) {
        _renderer = renderer;
        _lodMax = 0;
        _cubeSize = 0;
        _lodPlanes = [];
        _sizeLods = [];
        _sigmas = [];
        _blurMaterial = null;
        _cubemapMaterial = null;
        _equirectMaterial = null;

        _compileMaterial(_blurMaterial);
    }

    public function fromScene(scene:Dynamic, sigma:Float = 0, near:Float = 0.1, far:Float = 100):WebGLRenderTarget {
        // ...
    }

    public function fromEquirectangular(equirectangular:Dynamic, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    public function fromCubemap(cubemap:Dynamic, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    public function compileCubemapShader():Void {
        // ...
    }

    public function compileEquirectangularShader():Void {
        // ...
    }

    public function dispose():Void {
        // ...
    }

    private function _setSize(cubeSize:Int):Void {
        // ...
    }

    private function _dispose():Void {
        // ...
    }

    private function _cleanup(outputTarget:WebGLRenderTarget):Void {
        // ...
    }

    private function _fromTexture(texture:Dynamic, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    private function _allocateTargets():WebGLRenderTarget {
        // ...
    }

    private function _sceneToCubeUV(scene:Dynamic, near:Float, far:Float, cubeUVRenderTarget:WebGLRenderTarget):Void {
        // ...
    }

    private function _textureToCubeUV(texture:Dynamic, cubeUVRenderTarget:WebGLRenderTarget):Void {
        // ...
    }

    private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget):Void {
        // ...
    }

    private function _blur(cubeUVRenderTarget:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3):Void {
        // ...
    }

    private function _halfBlur(targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, direction:String, poleAxis:Vector3):Void {
        // ...
    }

    private function _createPlanes(lodMax:Int):{ sizeLods:Array<Int>, sigmas:Array<Float>, lodPlanes:Array<BufferGeometry> } {
        // ...
    }

    private function _createRenderTarget(width:Int, height:Int, params:Dynamic):WebGLRenderTarget {
        // ...
    }

    private function _setViewport(target:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int):Void {
        // ...
    }

    private function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
        // ...
    }

    private function _getEquirectMaterial():ShaderMaterial {
        // ...
    }

    private function _getCubemapMaterial():ShaderMaterial {
        // ...
    }

    private function _getCommonVertexShader():String {
        // ...
    }
}