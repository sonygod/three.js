import js.QUnit.*;
import js.WebGLContextMock;
import js.WebGLExtensions;

class WebglContextMockImpl extends js.WebGLContextMock {
    public function new(supportedExtensions:Array<String>) {
        super();
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

module renderers.webgl.WebGLExtensionsTest {
    QUnit.module('Renderers');
    QUnit.module('WebGL');
    QUnit.module('WebGLExtensions');

    // INSTANCING
    QUnit.test('Instancing', function() {
        var gl = new WebglContextMockImpl([]);
        var extensions = new WebGLExtensions(gl);
        QUnit.ok(Std.is(extensions, Dynamic));
    });

    QUnit.test('has', function() {
        var gl = new WebglContextMockImpl(['Extension1', 'Extension2']);
        var extensions = new WebGLExtensions(gl);
        QUnit.ok(extensions.has('Extension1'));
        QUnit.ok(extensions.has('Extension2'));
        QUnit.ok(extensions.has('Extension1'));
        QUnit.notOk(extensions.has('NonExistingExtension'));
    });

    QUnit.test('has (with aliasses)', function() {
        var gl = new WebglContextMockImpl(['WEBKIT_WEBGL_depth_texture']);
        var extensions = new WebGLExtensions(gl);
        QUnit.ok(extensions.has('WEBGL_depth_texture'));
        QUnit.ok(extensions.has('WEBKIT_WEBGL_depth_texture'));
        QUnit.notOk(extensions.has('EXT_texture_filter_anisotropic'));
        QUnit.notOk(extensions.has('NonExistingExtension'));
    });

    QUnit.test('get', function() {
        var gl = new WebglContextMockImpl(['Extension1', 'Extension2']);
        var extensions = new WebGLExtensions(gl);
        QUnit.ok(extensions.get('Extension1'));
        QUnit.ok(extensions.get('Extension2'));
        QUnit.ok(extensions.get('Extension1'));

        // surpress the following console message when testing
        // THREE.WebGLRenderer: NonExistingExtension extension not supported.
        js.console.level = js.CONSOLE_LEVEL.OFF;
        QUnit.notOk(extensions.get('NonExistingExtension'));
        js.console.level = js.CONSOLE_LEVEL.DEFAULT;
    });

    QUnit.test('get (with aliasses)', function() {
        var gl = new WebglContextMockImpl(['WEBKIT_WEBGL_depth_texture']);
        var extensions = new WebGLExtensions(gl);
        QUnit.ok(extensions.get('WEBGL_depth_texture'));
        QUnit.ok(extensions.get('WEBKIT_WEBGL_depth_texture'));

        // surpress the following console message when testing
        // THREE.WebGLRenderer: EXT_texture_filter_anisotropic extension not supported.
        // THREE.WebGLRenderer: NonExistingExtension extension not supported.
        js.console.level = js.CONSOLE_LEVEL.OFF;
        QUnit.notOk(extensions.get('EXT_texture_filter_anisotropic'));
        QUnit.notOk(extensions.get('NonExistingExtension'));
        js.console.level = js.CONSOLE_LEVEL.DEFAULT;
    });
}