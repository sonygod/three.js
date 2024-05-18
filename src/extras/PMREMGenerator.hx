package three.extras;

import three.constants.CubeReflectionMapping;
import three.constants.CubeRefractionMapping;
import three.constants.CubeUVReflectionMapping;
import three.constants.LinearFilter;
import three.constants.NoBlending;
import three.constants.RGBAFormat;
import three.constants.HalfFloatType;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.materials.ShaderMaterial;
import three.math.Vector3;
import three.math.Color;
import three.renderers.WebGLRenderTarget;
import three.geometries.BoxGeometry;
import three.materials.MeshBasicMaterial;

class PMREMGenerator {
    private var _renderer:WebGLRenderer;
    private var _pingPongRenderTarget:WebGLRenderTarget;
    private var _cubeSize:Int;
    private var _lodMax:Int;
    private var _lodPlanes:Array<BufferGeometry>;
    private var _sizeLods:Array<Int>;
    private var _sigmas:Array<Float>;
    private var _blurMaterial:ShaderMaterial;
    private var _cubemapMaterial:ShaderMaterial;
    private var _equirectMaterial:ShaderMaterial;

    public function new(renderer:WebGLRenderer) {
        _renderer = renderer;
        _pingPongRenderTarget = null;
        _cubeSize = 0;
        _lodMax = 0;
        _lodPlanes = [];
        _sizeLods = [];
        _sigmas = [];
        _blurMaterial = null;
        _cubemapMaterial = null;
        _equirectMaterial = null;
    }

    public function fromScene(scene:Object, sigma:Float = 0, near:Float = 0.1, far:Float = 100):WebGLRenderTarget {
        // implementation
    }

    public function fromEquirectangular(equirectangular:Object, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // implementation
    }

    public function fromCubemap(cubemap:Object, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // implementation
    }

    public function compileCubemapShader():Void {
        // implementation
    }

    public function compileEquirectangularShader():Void {
        // implementation
    }

    public function dispose():Void {
        // implementation
    }

    private function _setSize(cubeSize:Int):Void {
        // implementation
    }

    private function _dispose():Void {
        // implementation
    }

    private function _cleanup(outputTarget:WebGLRenderTarget):Void {
        // implementation
    }

    private function _fromTexture(texture:Object, renderTarget:WebGLRenderTarget):WebGLRenderTarget {
        // implementation
    }

    private function _allocateTargets():WebGLRenderTarget {
        // implementation
    }

    private function _sceneToCubeUV(scene:Object, near:Float, far:Float, cubeUVRenderTarget:WebGLRenderTarget):Void {
        // implementation
    }

    private function _textureToCubeUV(texture:Object, cubeUVRenderTarget:WebGLRenderTarget):Void {
        // implementation
    }

    private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget):Void {
        // implementation
    }

    private function _blur(cubeUVRenderTarget:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3):Void {
        // implementation
    }

    private function _halfBlur(targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, direction:String, poleAxis:Vector3):Void {
        // implementation
    }

    private function _createPlanes(lodMax:Int):{lodPlanes:Array<BufferGeometry>, sizeLods:Array<Int>, sigmas:Array<Float>} {
        // implementation
    }

    private function _createRenderTarget(width:Int, height:Int, params:Object):WebGLRenderTarget {
        // implementation
    }

    private function _setViewport(target:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int):Void {
        // implementation
    }

    private function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
        // implementation
    }

    private function _getEquirectMaterial():ShaderMaterial {
        // implementation
    }

    private function _getCubemapMaterial():ShaderMaterial {
        // implementation
    }

    private function _getCommonVertexShader():String {
        // implementation
    }
}