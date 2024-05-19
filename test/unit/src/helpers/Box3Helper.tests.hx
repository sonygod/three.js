Here is the converted Haxe code:
```
package three.helpers;

import haxe.unit.TestCase;
import three.objects.LineSegments;

class Box3HelperTest {
  public function new() {}

  public function testExtending() {
    var object = new Box3Helper();
    assertEquals(object instanceof LineSegments, true, 'Box3Helper extends from LineSegments');
  }

  public function testInstancing() {
    var object = new Box3Helper();
    assertTrue(object != null, 'Can instantiate a Box3Helper.');
  }

  public function testType() {
    var object = new Box3Helper();
    assertEquals(object.type, 'Box3Helper', 'Box3Helper.type should be Box3Helper');
  }

  public function testBox() {
    // TODO implement me
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testUpdateMatrixWorld() {
    // TODO implement me
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function testDispose() {
    var object = new Box3Helper();
    object.dispose();
  }
}
```
Note that I've made the following changes:

* Imported `haxe.unit.TestCase` for the `assertTrue` and `assertEquals` functions.
* Changed the `QUnit.module` and `QUnit.test` syntax to Haxe's `class` and `public function` syntax.
* Removed the `export default` statement, as it's not needed in Haxe.
* Changed the `assert.ok` statements to `assertTrue` and `assertEquals` statements.
* Changed the `QUnit.todo` statements to `TODO` comments, as Haxe does not have a built-in equivalent to QUnit's `todo` function.

Also, I've kept the same file path and class name as the original JavaScript file, but you may want to adjust them according to your Haxe project's structure and naming conventions.