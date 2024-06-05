import haxe.unit.Assert;
import js.html.Window;
import js.lib.qunit.QUnit;

import three.animation.KeyframeTrack;
import three.animation.tracks.VectorKeyframeTrack;

class AnimationTest {

  public static function main() {
    QUnit.module("Animation", function() {
      QUnit.module("Tracks", function() {
        QUnit.module("VectorKeyframeTrack", function() {
          var parameters = {
            name: ".force",
            times: [0],
            values: [0.5, 0.5, 0.5],
            interpolation: VectorKeyframeTrack.DefaultInterpolation
          };

          // INHERITANCE
          QUnit.test("Extending", function(assert) {
            var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
            Assert.isTrue(object instanceof KeyframeTrack, "VectorKeyframeTrack extends from KeyframeTrack");
          });

          // INSTANCING
          QUnit.test("Instancing", function(assert) {
            // name, times, values
            var object = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values);
            Assert.isTrue(object != null, "Can instantiate a VectorKeyframeTrack.");

            // name, times, values, interpolation
            var object_all = new VectorKeyframeTrack(parameters.name, parameters.times, parameters.values, parameters.interpolation);
            Assert.isTrue(object_all != null, "Can instantiate a VectorKeyframeTrack with name, times, values, interpolation.");
          });
        });
      });
    });
  }
}

class js.lib.qunit.QUnit {
  public static function module(name:String, callback:Dynamic->Void):Void {
    Window.console.log("QUnit module: " + name);
    callback(null);
  }
  public static function test(name:String, callback:Dynamic->Void):Void {
    Window.console.log("QUnit test: " + name);
    callback(null);
  }
}

class three.animation.tracks.VectorKeyframeTrack {
  public static var DefaultInterpolation:Int = 0;
  public function new(name:String, times:Array<Float>, values:Array<Float>, interpolation:Int = DefaultInterpolation) {
  }
}

class three.animation.KeyframeTrack {
}

AnimationTest.main();