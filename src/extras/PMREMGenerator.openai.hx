package three.pmrem;

import three.math.Vector3;
import three.math.Color;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderTarget;
import three.scenes.Scene;
import three.cameras.OrthographicCamera;
import three.cameras.PerspectiveCamera;
import three.geometries.BoxGeometry;
import three.textures.CubeTexture;

class PMREMGenerator {
    public var renderer:three.renderers.WebGLRenderer;
    public var pingPongRenderTarget:WebGLRenderTarget;
    public var lodMax:Int;
    public var cubeSize:Int;
    public var lodPlanes:Array<BufferGeometry>;
    public var sizeLods:Array<Int>;
    public var sigmas:Array<Float>;
    public var blurMaterial:ShaderMaterial;
    public var cubemapMaterial:ShaderMaterial;
    public var equirectMaterial:ShaderMaterial;

    public function new(renderer:three.renderers.WebGLRenderer) {
        this.renderer = renderer;
    }

    public function fromScene(scene:three.scenes.Scene, sigma:Float = 0, near:Float = 0.1, far:Float = 100):WebGLRenderTarget {
        // ...
    }

    public function fromEquirectangular(equirectangular:three.textures.CubeTexture, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    public function fromCubemap(cubemap:three.textures.CubeTexture, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    public function compileCubemapShader() {
        // ...
    }

    public function compileEquirectangularShader() {
        // ...
    }

    public function dispose() {
        // ...
    }

    private function setSize(cubeSize:Int) {
        // ...
    }

    private function _dispose() {
        // ...
    }

    private function _cleanup(outputTarget:WebGLRenderTarget) {
        // ...
    }

    private function _fromTexture(texture:three.textures.CubeTexture, renderTarget:WebGLRenderTarget = null):WebGLRenderTarget {
        // ...
    }

    private function _allocateTargets():WebGLRenderTarget {
        // ...
    }

    private function _sceneToCubeUV(scene:three.scenes.Scene, near:Float, far:Float, cubeUVRenderTarget:WebGLRenderTarget) {
        // ...
    }

    private function _textureToCubeUV(texture:three.textures.CubeTexture, cubeUVRenderTarget:WebGLRenderTarget) {
        // ...
    }

    private function _applyPMREM(cubeUVRenderTarget:WebGLRenderTarget) {
        // ...
    }

    private function _blur(cubeUVRenderTarget:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:Vector3) {
        // ...
    }

    private function _halfBlur(targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigma:Float, direction:String, poleAxis:Vector3) {
        // ...
    }
}