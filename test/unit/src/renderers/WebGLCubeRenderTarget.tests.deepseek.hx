package three.js.test.unit.src.renderers;

import three.js.src.renderers.WebGLCubeRenderTarget;
import three.js.src.renderers.WebGLRenderTarget;

class WebGLCubeRenderTargetTests {

    public static function main() {
        // INHERITANCE
        var object = new WebGLCubeRenderTarget();
        unittest.assert(object instanceof WebGLRenderTarget);

        // INSTANCING
        var object = new WebGLCubeRenderTarget();
        unittest.assert(object != null);

        // PROPERTIES
        // doc update needed, this needs to be a CubeTexture unlike parent class
        unittest.todo("texture");

        // PUBLIC
        unittest.todo("isWebGLCubeRenderTarget");

        unittest.todo("fromEquirectangularTexture");

        unittest.todo("clear");
    }
}