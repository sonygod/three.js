class PMREMGenerator {

    private var _renderer:Renderer;
    private var _blurMaterial:ShaderMaterial;
    private var _lodMax:Int;
    private var _cubeSize:Int;
    private var _lodPlanes:Array<Mesh>;
    private var _sizeLods:Array<Int>;
    private var _flatCamera:Camera;

    private function _halfBlur(targetIn:WebGLRenderTarget, targetOut:WebGLRenderTarget, lodIn:Int, lodOut:Int, sigmaRadians:Float, direction:String, poleAxis:Vector3) {

        var blurMesh = new Mesh(_lodPlanes[lodOut], _blurMaterial);
        var blurUniforms = _blurMaterial.uniforms;

        var pixels = _sizeLods[lodIn] - 1;
        var radiansPerPixel = if (isFinite(sigmaRadians)) Math.PI / (2 * pixels) else 2 * Math.PI / (2 * MAX_SAMPLES - 1);
        var sigmaPixels = sigmaRadians / radiansPerPixel;
        var samples = if (isFinite(sigmaRadians)) 1 + Math.floor(STANDARD_DEVIATIONS * sigmaPixels) else MAX_SAMPLES;

        if (samples > MAX_SAMPLES) {
            trace(`sigmaRadians, ${sigmaRadians}, is too large and will clip, as it requested ${samples} samples when the maximum is set to ${MAX_SAMPLES}`);
        }

        var weights = [];
        var sum = 0;

        for (i in 0...MAX_SAMPLES) {
            var x = i / sigmaPixels;
            var weight = Math.exp(- x * x / 2);
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

        if (poleAxis != null) {
            blurUniforms['poleAxis'].value = poleAxis;
        }

        blurUniforms['dTheta'].value = radiansPerPixel;
        blurUniforms['mipInt'].value = _lodMax - lodIn;

        var outputSize = _sizeLods[lodOut];
        var x = 3 * outputSize * (lodOut > _lodMax - LOD_MIN ? lodOut - _lodMax + LOD_MIN : 0);
        var y = 4 * (_cubeSize - outputSize);

        _setViewport(targetOut, x, y, 3 * outputSize, 2 * outputSize);
        _renderer.setRenderTarget(targetOut);
        _renderer.render(blurMesh, _flatCamera);
    }

    private static function _createPlanes(lodMax:Int):{lodPlanes:Array<Mesh>, sizeLods:Array<Int>, sigmas:Array<Float>} {
        // ...
    }

    private static function _createRenderTarget(width:Int, height:Int, params:Object):WebGLRenderTarget {
        // ...
    }

    private static function _setViewport(target:WebGLRenderTarget, x:Int, y:Int, width:Int, height:Int) {
        // ...
    }

    private static function _getBlurShader(lodMax:Int, width:Int, height:Int):ShaderMaterial {
        // ...
    }

    private static function _getEquirectMaterial():ShaderMaterial {
        // ...
    }

    private static function _getCubemapMaterial():ShaderMaterial {
        // ...
    }

    private static function _getCommonVertexShader():String {
        // ...
    }
}