import js.QUnit;

import Audio from "../../../../src/audio/Audio.hx";

import Object3D from "../../../../src/core/Object3D.hx";

class _Audios_Audio_Test {
    static testExtending() {
        var listener = mockListener();
        var object = new Audio(listener);
        var result = Std.is(Object3D, object);
        var expected = true;
        var message = "Audio extends from Object3D";
        if (result != expected) {
            throw new js.Error("Test failed: " + message);
        }
    }

    static testInstancing() {
        var listener = mockListener();
        var object = new Audio(listener);
        if (object == null) {
            throw new js.Error("Test failed: Can instantiate an Audio.");
        }
    }

    static testType() {
        var listener = mockListener();
        var object = new Audio(listener);
        var result = object.type;
        var expected = "Audio";
        var message = "Audio.type should be Audio";
        if (result != expected) {
            throw new js.Error("Test failed: " + message);
        }
    }
}

function mockListener() {
    return {
        context: {
            createGain: function() {
                return {
                    connect: function() {
                    }
                };
            }
        },
        getInput: function() {
        }
    };
}

class Audios {
    static module_Audio() {
        return QUnit.module("Audio", function() {
            QUnit.test("Extending", _Audios_Audio_Test.testExtending);
            QUnit.test("Instancing", _Audios_Audio_Test.testInstancing);
            QUnit.test("type", _Audios_Audio_Test.testType);
        });
    }
}

export default QUnit.module("Audios", function() {
    Audios.module_Audio();
});