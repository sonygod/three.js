package three.js.test.unit.src.renderers.webgl;

import three.js.src.renderers.webgl.WebGLExtensions;
import three.js.test.unit.src.utils.console_wrapper.CONSOLE_LEVEL;

class WebglContextMock {

    var supportedExtensions:Array<String>;

    public function new(supportedExtensions:Array<String>) {
        this.supportedExtensions = supportedExtensions;
    }

    public function getExtension(name:String):Dynamic {
        if (this.supportedExtensions.indexOf(name) > -1) {
            return { 'name': name };
        } else {
            return null;
        }
    }
}

class WebGLExtensionsTest {

    static function main() {
        // INSTANCING
        var gl = new WebglContextMock();
        var extensions = new WebGLExtensions(gl);
        unittest.assert(typeof extensions == 'object');

        // has
        var gl2 = new WebglContextMock(['Extension1', 'Extension2']);
        var extensions2 = new WebGLExtensions(gl2);
        unittest.assert(extensions2.has('Extension1'));
        unittest.assert(extensions2.has('Extension2'));
        unittest.assert(extensions2.has('Extension1'));
        unittest.assert(!extensions2.has('NonExistingExtension'));

        // has (with aliasses)
        var gl3 = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
        var extensions3 = new WebGLExtensions(gl3);
        unittest.assert(extensions3.has('WEBGL_depth_texture'));
        unittest.assert(extensions3.has('WEBKIT_WEBGL_depth_texture'));
        unittest.assert(!extensions3.has('EXT_texture_filter_anisotropic'));
        unittest.assert(!extensions3.has('NonExistingExtension'));

        // get
        var gl4 = new WebglContextMock(['Extension1', 'Extension2']);
        var extensions4 = new WebGLExtensions(gl4);
        unittest.assert(extensions4.get('Extension1'));
        unittest.assert(extensions4.get('Extension2'));
        unittest.assert(extensions4.get('Extension1'));

        // surpress the following console message when testing
        // THREE.WebGLRenderer: NonExistingExtension extension not supported.
        console.level = CONSOLE_LEVEL.OFF;
        unittest.assert(!extensions4.get('NonExistingExtension'));
        console.level = CONSOLE_LEVEL.DEFAULT;

        // get (with aliasses)
        var gl5 = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
        var extensions5 = new WebGLExtensions(gl5);
        unittest.assert(extensions5.get('WEBGL_depth_texture'));
        unittest.assert(extensions5.get('WEBKIT_WEBGL_depth_texture'));

        // surpress the following console message when testing
        // THREE.WebGLRenderer: EXT_texture_filter_anisotropic extension not supported.
        // THREE.WebGLRenderer: NonExistingExtension extension not supported.
        console.level = CONSOLE_LEVEL.OFF;
        unittest.assert(!extensions5.get('EXT_texture_filter_anisotropic'));
        unittest.assert(!extensions5.get('NonExistingExtension'));
        console.level = CONSOLE_LEVEL.DEFAULT;
    }
}