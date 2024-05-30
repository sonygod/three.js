import haxe.unit.TestRunner;
import three.animation.tracks.QuaternionKeyframeTrack;
import three.animation.KeyframeTrack;

class QuaternionKeyframeTrackTests {

  public function new() {}

  public function testQuaternionKeyframeTrack() {
    var parameters = {
      name: '.rotation',
      times: [0],
      values: [0.5, 0.5, 0.5, 1],
      interpolation: QuaternionKeyframeTrack.DEFAULT_INTERPOLATION
    };

    // INHERITANCE
    TestRunner.currentTest.add(new testExtending(parameters));

    // INSTANCING
    TestRunner.currentTest.add(new testInstancing(parameters));
  }
}

class testExtending extends haxe.unit.TestCase {
  var parameters:Dynamic;

  public function new(parameters:Dynamic) {
    this.parameters = parameters;
  }

  override public function test():Void {
    var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
    assertTrue(object instanceof KeyframeTrack, 'QuaternionKeyframeTrack extends from KeyframeTrack');
  }
}

class testInstancing extends haxe.unit.TestCase {
  var parameters:Dynamic;

  public function new(parameters:Dynamic) {
    this.parameters = parameters;
  }

  override public function test():Void {
    // name, times, values
    var object = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values);
    assertNotNull(object, 'Can instantiate a QuaternionKeyframeTrack.');

    // name, times, values, interpolation
    var object_all = new QuaternionKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
    assertNotNull(object_all, 'Can instantiate a QuaternionKeyframeTrack with name, times, values, interpolation.');
  }
}

class QuaternionKeyframeTrackTestSuite {
  static function main() {
    var runner = new TestRunner();
    runner.add(new QuaternionKeyframeTrackTests());
    runner.run();
  }
}