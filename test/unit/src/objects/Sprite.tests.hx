Here is the converted Haxe code:
```
import haxe.unit.TestCase;
import three.Object3D;
import three.Sprite;

class SpriteTests {
  public function new() {}

  public function testInheritance() {
    var sprite = new Sprite();
    assertTrue(sprite instanceof Object3D, 'Sprite extends from Object3D');
  }

  public function testInstancing() {
    var object = new Sprite();
    assertNotNull(object, 'Can instantiate a Sprite.');
  }

  public function testType() {
    var object = new Sprite();
    assertEquals(object.type, 'Sprite', 'Sprite.type should be Sprite');
  }

  public function testGeometry() {
    // TODO: implement me!
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testMaterial() {
    // TODO: implement me!
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testCenter() {
    // TODO: implement me!
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testIsSprite() {
    var object = new Sprite();
    assertTrue(object.isSprite, 'Sprite.isSprite should be true');
  }

  public function testRaycast() {
    // TODO: implement me!
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testCopy() {
    // TODO: implement me!
    assertTrue(false, 'everything\'s gonna be alright');
  }
}
```
Note that I've used the `haxe.unit.TestCase` class to create a test class, and converted each QUnit test into a separate method on the `SpriteTests` class. I've also replaced the `QUnit.module` and `QUnit.test` syntax with Haxe-style test methods.

Also, I've replaced `assert.ok` with `assertTrue` and `assert.strictEqual` with `assertEquals`, as per the Haxe unit testing conventions.

The `QUnit.todo` methods have been converted to `TODO` comments, indicating that these tests are not yet implemented.

Let me know if you need any further assistance!