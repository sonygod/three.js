import qunit.QUnit;
import three.renderers.WebGLRenderTarget;
import three.renderers.WebGL3DRenderTarget;

class WebGL3DRenderTargetTest extends QUnit.Module {
  public function new() {
    super("Renderers");
  }

  override function test(name:String, test:() -> Void) {
    super.test(name, test);
  }

  @:test
  function extending(assert:QUnit.Assert) {
    var object = new WebGL3DRenderTarget();
    assert.ok(Std.is(object, WebGLRenderTarget), "WebGL3DRenderTarget extends from WebGLRenderTarget");
  }

  @:test
  function instancing(assert:QUnit.Assert) {
    var object = new WebGL3DRenderTarget();
    assert.ok(object != null, "Can instantiate a WebGL3DRenderTarget.");
  }

  @:test
  function depth(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  function texture(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  function isWebGL3DRenderTarget(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }
}

class Main extends QUnit.Module {
  public function new() {
    super("WebGL3DRenderTarget");
  }

  override function test(name:String, test:() -> Void) {
    super.test(name, test);
  }

  @:test
  function extending(assert:QUnit.Assert) {
    var object = new WebGL3DRenderTarget();
    assert.ok(Std.is(object, WebGLRenderTarget), "WebGL3DRenderTarget extends from WebGLRenderTarget");
  }

  @:test
  function instancing(assert:QUnit.Assert) {
    var object = new WebGL3DRenderTarget();
    assert.ok(object != null, "Can instantiate a WebGL3DRenderTarget.");
  }

  @:test
  function depth(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  function texture(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }

  @:test
  function isWebGL3DRenderTarget(assert:QUnit.Assert) {
    assert.ok(false, "everything's gonna be alright");
  }
}

class Program {
  static function main() {
    new WebGL3DRenderTargetTest();
    new Main();
    QUnit.run();
  }
}