package three.test.unit.src.objects;

import three.core.Object3D;
import three.core.Raycaster;
import three.objects.LOD;

class LODTests {
  public function new() {}

  public function testExtending() {
    var lod = new LOD();
    Assert.isTrue(lod instanceof Object3D, 'LOD extends from Object3D');
  }

  public function testType() {
    var object = new LOD();
    Assert.equals(object.type, 'LOD', 'LOD.type should be LOD');
  }

  public function testLevels() {
    var lod = new LOD();
    var levels = lod.levels;
    Assert.isTrue(levels.length == 0, 'LOD.levels is empty by default.');
    Assert.isTrue(Std.isOfType(levels, Array), 'LOD.levels is of type array.');
  }

  public function testAutoUpdate() {
    var lod = new LOD();
    Assert.isTrue(lod.autoUpdate, 'LOD.autoUpdate is of type boolean and true by default.');
  }

  public function testIsLOD() {
    var lod = new LOD();
    Assert.isTrue(lod.isLOD, '.isLOD property is defined.');
  }

  public function testCopy() {
    var lod1 = new LOD();
    var lod2 = new LOD();
    var high = new Object3D();
    var mid = new Object3D();
    var low = new Object3D();

    lod1.addLevel(high, 5);
    lod1.addLevel(mid, 25);
    lod1.addLevel(low, 50);
    lod1.autoUpdate = false;

    lod2.copy(lod1);
    Assert.isTrue(lod2.autoUpdate == false, 'LOD.autoUpdate is correctly copied.');
    Assert.isTrue(lod2.levels.length == 3, 'LOD.levels has the correct length after the copy.');
  }

  public function testAddLevel() {
    var lod = new LOD();
    var high = new Object3D();
    var mid = new Object3D();
    var low = new Object3D();

    lod.addLevel(high, 5, 0.0);
    lod.addLevel(mid, 25, 0.05);
    lod.addLevel(low, 50, 0.10);

    Assert.isTrue(lod.levels.length == 3, 'LOD.levels has the correct length.');
    Assert.deepEqual(lod.levels[0], { distance: 5, object: high, hysteresis: 0.0 }, 'First entry correct.');
    Assert.deepEqual(lod.levels[1], { distance: 25, object: mid, hysteresis: 0.05 }, 'Second entry correct.');
    Assert.deepEqual(lod.levels[2], { distance: 50, object: low, hysteresis: 0.10 }, 'Third entry correct.');
  }

  public function testGetCurrentLevel() {
    Assert.fail('not implemented');
  }

  public function testGetObjectForDistance() {
    var lod = new LOD();
    var high = new Object3D();
    var mid = new Object3D();
    var low = new Object3D();

    Assert.isNull(lod.getObjectForDistance(5), 'Returns null if no LOD levels are defined.');

    lod.addLevel(high, 5);

    Assert.isTrue(lod.getObjectForDistance(0) == high, 'Returns always the same object if only one LOD level is defined.');
    Assert.isTrue(lod.getObjectForDistance(10) == high, 'Returns always the same object if only one LOD level is defined.');

    lod.addLevel(mid, 25);
    lod.addLevel(low, 50);

    Assert.isTrue(lod.getObjectForDistance(0) == high, 'Returns the high resolution object.');
    Assert.isTrue(lod.getObjectForDistance(10) == high, 'Returns the high resolution object.');
    Assert.isTrue(lod.getObjectForDistance(25) == mid, 'Returns the mid resolution object.');
    Assert.isTrue(lod.getObjectForDistance(50) == low, 'Returns the low resolution object.');
    Assert.isTrue(lod.getObjectForDistance(60) == low, 'Returns the low resolution object.');
  }

  public function testRaycast() {
    var lod = new LOD();
    var raycaster = new Raycaster();
    var intersections = [];

    lod.raycast(raycaster, intersections);

    Assert.isTrue(intersections.length == 0, 'Does not fail if raycasting is used with a LOD object without levels.');
  }

  public function testUpdate() {
    Assert.fail('not implemented');
  }

  public function testToJSON() {
    Assert.fail('not implemented');
  }
}