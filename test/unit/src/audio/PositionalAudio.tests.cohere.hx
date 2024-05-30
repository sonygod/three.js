import js.QUnit;

import js.audio.PositionalAudio;
import js.audio.Audio;

class _Audios {
    static function extend() {
        var listener = mock3DListener();
        var object = new PositionalAudio(listener);
        var result = Std.is(object, Audio);
        QUnit.strictEqual(result, true, "PositionalAudio extends from Audio");
    }

    static function instantiate() {
        var listener = mock3DListener();
        var object = new PositionalAudio(listener);
        QUnit.ok(object, "Can instantiate a PositionalAudio.");
    }

    static function panner() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function disconnect() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function getOutput() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function getRefDistance() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setRefDistance() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function getRolloffFactor() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setRolloffFactor() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function getDistanceModel() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setDistanceModel() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function getMaxDistance() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setMaxDistance() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function setDirectionalCone() {
        QUnit.ok(false, "everything's gonna be alright");
    }

    static function updateMatrixWorld() {
        QUnit.ok(false, "everything's gonna be alright");
    }
}

function mock3DListener() {
    return {
        context: {
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
        },
        getInput: function() {}
    };
}

@:expose("Audios")
class Audios {
    static function $init() {
        QUnit.module("Audios", function() {
            QUnit.module("PositionalAudio", function() {
                QUnit.test("Extending", _Audios.extend);
                QUnit.test("Instancing", _Audios.instantiate);
                QUnit.todo("panner", _Audios.panner);
                QUnit.todo("disconnect", _Audios.disconnect);
                QUnit.todo("getOutput", _Audios.getOutput);
                QUnit.todo("getRefDistance", _Audios.getRefDistance);
                QUnit.todo("setRefDistance", _Audios.setRefDistance);
                QUnit.todo("getRolloffFactor", _Audios.getRolloffFactor);
                QUnit.todo("setRolloffFactor", _Audios.setRolloffFactor);
                QUnit.todo("getDistanceModel", _Audios.getDistanceModel);
                QUnit.todo("setDistanceModel", _Audios.setDistanceModel);
                QUnit.todo("getMaxDistance", _Audios.getMaxDistance);
                QUnit.todo("setMaxDistance", _Audios.setMaxDistance);
                QUnit.todo("setDirectionalCone", _Audios.setDirectionalCone);
                QUnit.todo("updateMatrixWorld", _Audios.updateMatrixWorld);
            });
        });
    }
}