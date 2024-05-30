package test.openfl;

import js.QUnit;

class TestAudios {
    public static function test() : Void {
        QUnit.module("Audios", {
            setup: function() {
                // ...
            },
            teardown: function() {
                // ...
            }
        });

        QUnit.module("AudioAnalyser");

        // INSTANCING
        QUnit.todo("Instancing", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PROPERTIES
        QUnit.todo("analyser", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("data", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("getFrequencyData", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getAverageFrequency", function(assert) {
            assert.ok(false, "everything's gonna be alright");
        });
    }
}