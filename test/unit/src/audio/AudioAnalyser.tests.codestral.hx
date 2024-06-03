import js.Browser.document;
import js.html.QUnit;

// Importing AudioAnalyser is not possible without the actual Haxe equivalent or extern
// import three.audio.AudioAnalyser;

class AudioAnalyserTests {
    public function new() {
        QUnit.module("Audios", () -> {
            QUnit.module("AudioAnalyser", () -> {
                // INSTANCING
                QUnit.todo("Instancing", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PROPERTIES
                QUnit.todo("analyser", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("data", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("getFrequencyData", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getAverageFrequency", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}

// Instantiate the tests
var tests = new AudioAnalyserTests();