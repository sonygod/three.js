package three.js.effects;

import three.core.*;
import three.renderers.WebGLRenderer;
import three.cameras.OrthographicCamera;
import three.scenes.Scene;
import three.objects.Mesh;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.renderers.WebGLRenderTarget;
import three.cameras.StereoCamera;
import three.math.Matrix3;
import three.constants.TextureFilter;
import three.constants.TextureFormat;

class AnaglyphEffect {

    var colorMatrixLeft:Matrix3;
    var colorMatrixRight:Matrix3;
    var _camera:OrthographicCamera;
    var _scene:Scene;
    var _stereo:StereoCamera;
    var _renderTargetL:WebGLRenderTarget;
    var _renderTargetR:WebGLRenderTarget;
    var _material:ShaderMaterial;
    var _mesh:Mesh;
    var renderer:WebGLRenderer;

    public function new(renderer:WebGLRenderer, width:Int = 512, height:Int = 512) {
        this.renderer = renderer;
        this.colorMatrixLeft = new Matrix3().fromArray([
			0.456100, - 0.0400822, - 0.0152161,
			0.500484, - 0.0378246, - 0.0205971,
			0.176381, - 0.0157589, - 0.00546856
		]);
        this.colorMatrixRight = new Matrix3().fromArray([
			- 0.0434706, 0.378476, - 0.0721527,
			- 0.0879388, 0.73364, - 0.112961,
			- 0.00155529, - 0.0184503, 1.2264
		]);

        // Initialize other variables and methods here...
    }

    public function setSize(width:Int, height:Int) {
        // Implementation here...
    }

    public function render(scene:Scene, camera:OrthographicCamera) {
        // Implementation here...
    }

    public function dispose() {
        // Implementation here...
    }
}