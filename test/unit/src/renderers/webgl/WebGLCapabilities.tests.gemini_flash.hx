import qunit.QUnit;

// import three.renderers.webgl.WebGLCapabilities;

class WebGLCapabilitiesTest extends qunit.TestCase {
  public function new() {
    super();
  }

  @:test
  public function instancing(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function getMaxAnisotropy(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function getMaxPrecision(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function precision(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function logarithmicDepthBuffer(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxTextures(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxVertexTextures(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxTextureSize(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxCubemapSize(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxAttributes(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxVertexUniforms(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxVaryings(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function maxFragmentUniforms(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function vertexTextures(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function floatFragmentTextures(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  public function floatVertexTextures(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }
}

class WebGLTest extends qunit.TestCase {
  public function new() {
    super();
  }

  @:test
  public function test(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }
}

class RenderersTest extends qunit.TestCase {
  public function new() {
    super();
  }

  @:test
  public function test(assert:qunit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }
}

class MainTest extends qunit.TestCase {
  public function new() {
    super();
  }

  @:test
  public function test(assert:qunit.Assert) {
    QUnit.module("Renderers", function() {
      QUnit.module("WebGL", function() {
        QUnit.module("WebGLCapabilities", function() {
          new WebGLCapabilitiesTest();
        });
      });
    });
  }
}

class Main {
  static function main() {
    new MainTest();
  }
}