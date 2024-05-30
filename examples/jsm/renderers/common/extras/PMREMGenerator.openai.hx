import three.js.Lib;

class PMREMGenerator {
    private var _renderer:three.js.Renderer;
    private var _pingPongRenderTarget:three.js.RenderTarget;
    private var _lodMax:Int;
    private var _cubeSize:Int;
    private var _lodPlanes:Array<three.js.BufferGeometry>;
    private var _sizeLods:Array<Int>;
    private var _sigmas:Array<Float>;
    private var _lodMeshes:Array<three.js.Mesh>;
    private var _blurMaterial:three.js.ShaderMaterial;
    private var _cubemapMaterial:three.js.ShaderMaterial;
    private var _equirectMaterial:three.js.ShaderMaterial;
    private var _backgroundBox:three.js.Mesh;

    public function new(renderer:three.js.Renderer) {
        this._renderer = renderer;
        this._pingPongRenderTarget = null;
    }

    public function fromScene(scene:three.js.Scene, sigma:Float = 0, near:Float = 0.1, far:Float = 100):three.js.RenderTarget {
        // ...
    }

    public function fromEquirectangular(equirectangular:three.js.Texture, renderTarget:three.js.RenderTarget = null):three.js.RenderTarget {
        // ...
    }

    public function fromCubemap(cubemap:three.js.Texture, renderTarget:three.js.RenderTarget = null):three.js.RenderTarget {
        // ...
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

    private function _cleanup(outputTarget:three.js.RenderTarget):Void {
        this._renderer.setRenderTarget(_oldTarget, _oldActiveCubeFace, _oldActiveMipmapLevel);
        outputTarget.scissorTest = false;
        _setViewport(outputTarget, 0, 0, outputTarget.width, outputTarget.height);
    }

    private function _fromTexture(texture:three.js.Texture, renderTarget:three.js.RenderTarget):three.js.RenderTarget {
        // ...
    }

    private function _allocateTargets():three.js.RenderTarget {
        // ...
    }

    private function _compileMaterial(material:three.js.ShaderMaterial):Void {
        // ...
    }

    private function _sceneToCubeUV(scene:three.js.Scene, near:Float, far:Float, cubeUVRenderTarget:three.js.RenderTarget):Void {
        // ...
    }

    private function _textureToCubeUV(texture:three.js.Texture, cubeUVRenderTarget:three.js.RenderTarget):Void {
        // ...
    }

    private function _applyPMREM(cubeUVRenderTarget:three.js.RenderTarget):Void {
        // ...
    }

    private function _blur(cubeUVRenderTarget:three.js.RenderTarget, lodIn:Int, lodOut:Int, sigma:Float, poleAxis:three.js.Vector3):Void {
        // ...
    }

    private function _halfBlur(targetIn:three.js.RenderTarget, targetOut:three.js.RenderTarget, lodIn:Int, lodOut:Int, sigma:Float, direction:String, poleAxis:three.js.Vector3):Void {
        // ...
    }

    private static function _createPlanes(lodMax:Int):{lodPlanes:Array<three.js.BufferGeometry>, sizeLods:Array<Int>, sigmas:Array<Float>, lodMeshes:Array<three.js.Mesh>} {
        // ...
    }

    private static function _createRenderTarget(width:Int, height:Int, params:{magFilter:three.js.TextureFilter, minFilter:three.js.TextureFilter, generateMipmaps:Bool, type:three.js.TextureDataType, format:three.js.PixelFormat, colorSpace:three.js.ColorSpace}):three.js.RenderTarget {
        // ...
    }

    private static function _setViewport(target:three.js.RenderTarget, x:Int, y:Int, width:Int, height:Int):Void {
        // ...
    }

    private static function _getMaterial():three.js.ShaderMaterial {
        // ...
    }

    private static function _getBlurShader(lodMax:Int, width:Int, height:Int):three.js.ShaderMaterial {
        // ...
    }

    private static function _getCubemapMaterial(envTexture:three.js.Texture):three.js.ShaderMaterial {
        // ...
    }

    private static function _getEquirectMaterial(envTexture:three.js.Texture):three.js.ShaderMaterial {
        // ...
    }
}