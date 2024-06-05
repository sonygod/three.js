import qunit.QUnit;
import three.renderers.WebGLRenderTarget;
import three.core.EventDispatcher;

class WebGLRenderTargetTest extends QUnit.Module {

  public function new() {
    super("Renderers.WebGLRenderTarget");
  }

  override function test(assert:QUnit.Assert) {
    // INHERITANCE
    this.testExtending(assert);
    // INSTANCING
    this.testInstancing(assert);
  }

  public function testExtending(assert:QUnit.Assert):Void {
    var object:WebGLRenderTarget = new WebGLRenderTarget();
    assert.isTrue(object.is(EventDispatcher), "WebGLRenderTarget extends from EventDispatcher");
  }

  public function testInstancing(assert:QUnit.Assert):Void {
    var object:WebGLRenderTarget = new WebGLRenderTarget();
    assert.ok(object, "Can instantiate a WebGLRenderTarget.");
  }

  // PROPERTIES
  public function testWidth(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testHeight(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testDepth(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testScissor(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testScissorTest(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testViewport(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testTexture(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testDepthBuffer(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testStencilBuffer(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testDepthTexture(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testSamples(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testTextures(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  // PUBLIC
  public function testIsWebGLRenderTarget(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testSetSize(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testClone(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testCopy(assert:QUnit.Assert):Void {
    assert.ok(false, "everything's gonna be alright");
  }

  public function testDispose(assert:QUnit.Assert):Void {
    assert.expect(0);
    var object:WebGLRenderTarget = new WebGLRenderTarget();
    object.dispose();
  }
}

class WebGLRenderTargetSuite extends QUnit.Module {
  public function new() {
    super("Renderers");
  }

  override function test(assert:QUnit.Assert) {
    new WebGLRenderTargetTest().test(assert);
  }
}

new WebGLRenderTargetSuite();