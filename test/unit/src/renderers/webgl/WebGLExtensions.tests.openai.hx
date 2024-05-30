import haxe.ds.StringMap;

class WebGLExtensionsTests {
  static function main() {
    var suite = new haxe.unit.TestSuite();

    suite.addTestCase(new InstancingTestCase());
    suite.addTestCase(new HasTestCase());
    suite.addTestCase(new HasWithAliasesTestCase());
    suite.addTestCase(new GetTestCase());
    suite.addTestCase(new GetWithAliasesTestCase());

    suite.run();
  }
}

class InstancingTestCase extends haxe.unit.TestCase {
  function testInstancing() {
    var gl = new WebglContextMock();
    var extensions = new WebGLExtensions(gl);
    assertEquals(typeof extensions == Object, true);
  }
}

class HasTestCase extends haxe.unit.TestCase {
  function testHas() {
    var gl = new WebglContextMock(['Extension1', 'Extension2']);
    var extensions = new WebGLExtensions(gl);
    assertTrue(extensions.has('Extension1'));
    assertTrue(extensions.has('Extension2'));
    assertTrue(extensions.has('Extension1'));
    assertFalse(extensions.has('NonExistingExtension'));
  }
}

class HasWithAliasesTestCase extends haxe.unit.TestCase {
  function testHasWithAliases() {
    var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
    var extensions = new WebGLExtensions(gl);
    assertTrue(extensions.has('WEBGL_depth_texture'));
    assertTrue(extensions.has('WEBKIT_WEBGL_depth_texture'));
    assertFalse(extensions.has('EXT_texture_filter_anisotropic'));
    assertFalse(extensions.has('NonExistingExtension'));
  }
}

class GetTestCase extends haxe.unit.TestCase {
  function testGet() {
    var gl = new WebglContextMock(['Extension1', 'Extension2']);
    var extensions = new WebGLExtensions(gl);
    assertNotNull(extensions.get('Extension1'));
    assertNotNull(extensions.get('Extension2'));
    assertNotNull(extensions.get('Extension1'));

    // suppress console message when testing
    Console.setLevel(ConsoleLevel.OFF);
    assertNull(extensions.get('NonExistingExtension'));
    Console.setLevel(ConsoleLevel.DEFAULT);
  }
}

class GetWithAliasesTestCase extends haxe.unit.TestCase {
  function testGetWithAliases() {
    var gl = new WebglContextMock(['WEBKIT_WEBGL_depth_texture']);
    var extensions = new WebGLExtensions(gl);
    assertNotNull(extensions.get('WEBGL_depth_texture'));
    assertNotNull(extensions.get('WEBKIT_WEBGL_depth_texture'));

    // suppress console message when testing
    Console.setLevel(ConsoleLevel.OFF);
    assertNull(extensions.get('EXT_texture_filter_anisotropic'));
    assertNull(extensions.get('NonExistingExtension'));
    Console.setLevel(ConsoleLevel.DEFAULT);
  }
}

class WebglContextMock {
  public var supportedExtensions:Array<String>;

  public function new(supportedExtensions:Array<String> = null) {
    this.supportedExtensions = supportedExtensions != null ? supportedExtensions : [];
  }

  public function getExtension(name:String):Dynamic {
    if (supportedExtensions.indexOf(name) != -1) {
      return { name: name };
    } else {
      return null;
    }
  }
}

class WebGLExtensions {
  private var gl:WebglContextMock;

  public function new(gl:WebglContextMock) {
    this.gl = gl;
  }

  public function has(extension:String):Bool {
    return gl.supportedExtensions.indexOf(extension) != -1;
  }

  public function get(extension:String):Dynamic {
    return gl.getExtension(extension);
  }
}

enum ConsoleLevel {
  OFF;
  DEFAULT;
}

class Console {
  static public var level:ConsoleLevel;

  static public function setLevel(level:ConsoleLevel) {
    this.level = level;
  }
}