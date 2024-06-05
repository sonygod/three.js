import qunit.QUnit;
import webgl.WebGLExtensions;
import utils.ConsoleWrapper;

class WebglContextMock {

	public var supportedExtensions:Array<String>;

	public function new(supportedExtensions:Array<String> = []) {
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

class WebGLExtensionsTest extends qunit.Test {

	public function new() {
		super();
	}

	@qunit.test("Instancing")
	public function instancing(assert:qunit.Assert):Void {
		var gl = new WebglContextMock();
		var extensions = new WebGLExtensions(gl);
		assert.ok(typeof extensions == 'object');
	}

	@qunit.test("has")
	public function has(assert:qunit.Assert):Void {
		var gl = new WebglContextMock(['Extension1', 'Extension2']);
		var extensions = new WebGLExtensions(gl);
		assert.ok(extensions.has('Extension1'));
		assert.ok(extensions.has('Extension2'));
		assert.ok(extensions.has('Extension1'));
		assert.notOk(extensions.has('NonExistingExtension'));
	}

	@qunit.test("has (with aliasses)")
	public function hasAliasses(assert:qunit.Assert):Void {
		var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
		var extensions = new WebGLExtensions(gl);
		assert.ok(extensions.has('WEBGL_depth_texture'));
		assert.ok(extensions.has('WEBKIT_WEBGL_depth_texture'));
		assert.notOk(extensions.has('EXT_texture_filter_anisotropic'));
		assert.notOk(extensions.has('NonExistingExtension'));
	}

	@qunit.test("get")
	public function get(assert:qunit.Assert):Void {
		var gl = new WebglContextMock(['Extension1', 'Extension2']);
		var extensions = new WebGLExtensions(gl);
		assert.ok(extensions.get('Extension1'));
		assert.ok(extensions.get('Extension2'));
		assert.ok(extensions.get('Extension1'));

		// surpress the following console message when testing
		// THREE.WebGLRenderer: NonExistingExtension extension not supported.
		ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
		assert.notOk(extensions.get('NonExistingExtension'));
		ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;
	}

	@qunit.test("get (with aliasses)")
	public function getAliasses(assert:qunit.Assert):Void {
		var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
		var extensions = new WebGLExtensions(gl);
		assert.ok(extensions.get('WEBGL_depth_texture'));
		assert.ok(extensions.get('WEBKIT_WEBGL_depth_texture'));

		// surpress the following console message when testing
		// THREE.WebGLRenderer: EXT_texture_filter_anisotropic extension not supported.
		// THREE.WebGLRenderer: NonExistingExtension extension not supported.
		ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.OFF;
		assert.notOk(extensions.get('EXT_texture_filter_anisotropic'));
		assert.notOk(extensions.get('NonExistingExtension'));
		ConsoleWrapper.level = ConsoleWrapper.CONSOLE_LEVEL.DEFAULT;
	}

}

class WebGLExtensionsModule extends qunit.Module {

	public function new() {
		super('Renderers');
	}

	@qunit.module("WebGL")
	public function webgl():Void {

		@qunit.module("WebGLExtensions")
		public function webglExtensions():Void {

			new WebGLExtensionsTest();

		}

	}

}

var module = new WebGLExtensionsModule();