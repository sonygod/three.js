import js.QUnit;
import openfl.animation.AnimationClip;

class AnimationClipTest {
    public static function main() {
        QUnit.module( "AnimationClip", function() {
            QUnit.test( "Instancing", function(assert) {
                var clip = new AnimationClip("clip1", 1000, [{}]);
                assert.ok(clip, "AnimationClip can be instantiated");
            });

            QUnit.test("name", function(assert) {
                var clip = new AnimationClip("clip1", 1000, [{}]);
                assert.strictEqual(clip.name == "clip1", true, "AnimationClip can be named");
            });

            QUnit.test("tracks", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("duration", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("blendMode", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("uuid", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("static parse", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("static toJSON", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("CreateFromMorphTargetSequence", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("findByName", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("CreateClipsFromMorphTargetSequences", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("parseAnimation", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public resetDuration", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public trim", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public validate", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public optimize", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public clone", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });

            QUnit.test("public toJSON", function(assert) {
                assert.ok(false, "Everything's gonna be alright");
            });
        });
    }
}