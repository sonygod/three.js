import js.Browser;
import js.Browser.document;
import js.Browser.window;

class AnimationClipTests {
    public static function main() {
        var QUnit = js.Browser.getObject("QUnit");
        var AnimationClip = js.Browser.getObject("three.AnimationClip");

        QUnit.module("Animation", function() {
            QUnit.module("AnimationClip", function() {
                QUnit.test("Instancing", function(assert) {
                    var clip:untyped = new AnimationClip("clip1", 1000, [{}]);
                    assert.ok(clip, "AnimationClip can be instanciated");
                });

                QUnit.test("name", function(assert) {
                    var clip:untyped = new AnimationClip("clip1", 1000, [{}]);
                    assert.strictEqual(clip.name === "clip1", true, "AnimationClip can be named");
                });

                // ... add other test cases here
            });
        });
    }
}