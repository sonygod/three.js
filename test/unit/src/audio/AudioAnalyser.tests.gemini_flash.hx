import qunit.QUnit;

class AudioAnalyser {
  // ... implementation of AudioAnalyser class ...
}

class AudiosTest {
  static function main() {
    QUnit.module("Audios", function() {
      QUnit.module("AudioAnalyser", function() {
        QUnit.todo("Instancing", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("analyser", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("data", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFrequencyData", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getAverageFrequency", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

AudiosTest.main();