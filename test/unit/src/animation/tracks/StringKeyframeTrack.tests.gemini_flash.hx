import qunit.QUnit;
import three.animation.tracks.StringKeyframeTrack;
import three.animation.KeyframeTrack;

class AnimationTest {

	static function main() {
		QUnit.module("Animation", function() {
			QUnit.module("Tracks", function() {
				QUnit.module("StringKeyframeTrack", function() {

					var parameters = {
						name: ".name",
						times: [0, 1],
						values: ["foo", "bar"]
					};

					// INHERITANCE
					QUnit.test("Extending", function(assert) {
						var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
						assert.strictEqual(object.is(KeyframeTrack), true, "StringKeyframeTrack extends from KeyframeTrack");
					});

					// INSTANCING
					QUnit.test("Instancing", function(assert) {
						// name, times, values
						var object = new StringKeyframeTrack(parameters.name, parameters.times, parameters.values);
						assert.ok(object, "Can instantiate a StringKeyframeTrack.");
					});
				});
			});
		});
	}
}

AnimationTest.main();