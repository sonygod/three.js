import qunit.QUnit;
import three.audio.Audio;
import three.audio.PositionalAudio;

class Mock3DListener {
  public var context: {
    createGain: () -> {
      connect: () -> Void;
    };
    createPanner: () -> {
      connect: () -> Void;
    };
  };
  public var getInput: () -> Void;

  public function new() {
    this.context = {
      createGain: function() {
        return {
          connect: function() {}
        };
      },
      createPanner: function() {
        return {
          connect: function() {}
        };
      }
    };
    this.getInput = function() {};
  }
}

class AudiosTest extends QUnit.Module {
  public function new() {
    super("Audios");

    var positionalAudioModule = new QUnit.Module("PositionalAudio", this);

    positionalAudioModule.test("Extending", function(assert) {
      var listener = new Mock3DListener();
      var object = new PositionalAudio(listener);
      assert.ok(Std.is(object, Audio), "PositionalAudio extends from Audio");
    });

    positionalAudioModule.test("Instancing", function(assert) {
      var listener = new Mock3DListener();
      var object = new PositionalAudio(listener);
      assert.ok(object != null, "Can instantiate a PositionalAudio.");
    });

    positionalAudioModule.todo("panner", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("disconnect", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("getOutput", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("getRefDistance", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("setRefDistance", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("getRolloffFactor", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("setRolloffFactor", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("getDistanceModel", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("setDistanceModel", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("getMaxDistance", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("setMaxDistance", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("setDirectionalCone", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });

    positionalAudioModule.todo("updateMatrixWorld", function(assert) {
      assert.ok(false, "everything's gonna be alright");
    });
  }
}

class AudiosTestMain {
  static function main() {
    new AudiosTest();
  }
}