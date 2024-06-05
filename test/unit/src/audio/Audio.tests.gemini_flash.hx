import qunit.QUnit;
import three.core.Object3D;
import three.audio.Audio;

class MockListener {
  public function new() {
  }

  public function getContext() {
    return {
      createGain: function() {
        return {
          connect: function() {}
        };
      }
    };
  }

  public function getInput() {
    return null;
  }
}

class AudiosTest {
  static function main() {
    QUnit.module("Audios", function() {
      QUnit.module("Audio", function() {
        // INHERITANCE
        QUnit.test("Extending", function(assert) {
          var listener = new MockListener();
          var object = new Audio(listener);
          assert.strictEqual(object.is(Object3D), true, "Audio extends from Object3D");
        });

        // INSTANCING
        QUnit.test("Instancing", function(assert) {
          var listener = new MockListener();
          var object = new Audio(listener);
          assert.ok(object, "Can instantiate an Audio.");
        });

        // PROPERTIES
        QUnit.test("type", function(assert) {
          var listener = new MockListener();
          var object = new Audio(listener);
          assert.ok(object.type == "Audio", "Audio.type should be Audio");
        });

        QUnit.todo("listener", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("context", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("gain", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("autoplay", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("buffer", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("detune", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("loop", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("loopStart", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("loopEnd", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("offset", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("duration", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("playbackRate", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("isPlaying", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("hasPlaybackControl", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("source", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("sourceType", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("filters", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        // PUBLIC
        QUnit.todo("getOutput", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setNodeSource", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setMediaElementSource", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setMediaStreamSource", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setBuffer", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("play", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("pause", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("stop", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("connect", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("disconnect", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFilters", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setFilters", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setDetune", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getDetune", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getFilter", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setFilter", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setPlaybackRate", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getPlaybackRate", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("onEnded", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getLoop", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setLoop", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setLoopStart", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setLoopEnd", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("getVolume", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });

        QUnit.todo("setVolume", function(assert) {
          assert.ok(false, "everything's gonna be alright");
        });
      });
    });
  }
}

class Main {
  static function main() {
    AudiosTest.main();
  }
}