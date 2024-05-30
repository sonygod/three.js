import js.QUnit;

import AudioListener from "../../../../src/audio/AudioListener.hx";
import Object3D from "../../../../src/core/Object3D.hx";

class _Audios_AudioListenerTest {
    static testExtending() {
        var object = new AudioListener();
        var result = Std.is(object, Object3D);
        var expected = true;
        if (result != expected) {
            throw haxe.Unit.Error.Custom({ customMessage : "AudioListener extends from Object3D", expected : expected, result : result, paramName : null});
        }
    }
    static testInstancing() {
        var object = new AudioListener();
        if (object == null) {
            throw haxe.Unit.Error.Custom({ customMessage : "Can instantiate an AudioListener.", expected : null, result : null, paramName : null});
        }
    }
    static testType() {
        var object = new AudioListener();
        var result = object.type;
        var expected = "AudioListener";
        if (result != expected) {
            throw haxe.Unit.Error.Custom({ customMessage : "AudioListener.type should be AudioListener", expected : expected, result : result, paramName : null});
        }
    }
    static testContext() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testGain() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testFilter() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testTimeDelta() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testGetInput() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testRemoveFilter() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testGetFilter() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testSetFilter() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testGetMasterVolume() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testSetMasterVolume() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
    static testUpdateMatrixWorld() {
        throw haxe.Unit.Error.Skip("everything's gonna be alright");
    }
}
QUnit.module("Audios", function() {
    QUnit.module("AudioListener", function(hooks) {
        if (typeof window == "undefined") {
            hooks.before(function() {
                global.window = { AudioContext : function() {
                        return { createGain : function() {
                                return { connect : function(){}};
                            }};
                    }};
            });
            hooks.after(function() {
                global.window = null;
            });
        }
        QUnit.test("Extending", _Audios_AudioListenerTest.testExtending);
        QUnit.test("Instancing", _Audios_AudioListenerTest.testInstancing);
        QUnit.test("type", _Audios_AudioListenerTest.testType);
        QUnit.todo("context", _Audios_AudioListenerTest.testContext);
        QUnit.todo("gain", _Audios_AudioListenerTest.testGain);
        QUnit.todo("filter", _Audios_AudioListenerTest.testFilter);
        QUnit.todo("timeDelta", _Audios_AudioListenerTest.testTimeDelta);
        QUnit.todo("getInput", _Audios_AudioListenerTest.testGetInput);
        QUnit.todo("removeFilter", _Audios_AudioListenerTest.testRemoveFilter);
        QUnit.todo("getFilter", _Audios_AudioListenerTest.testGetFilter);
        QUnit.todo("setFilter", _Audios_AudioListenerTest.testSetFilter);
        QUnit.todo("getMasterVolume", _Audios_AudioListenerTest.testGetMasterVolume);
        QUnit.todo("setMasterVolume", _Audios_AudioListenerTest.testSetMasterVolume);
        QUnit.todo("updateMatrixWorld", _Audios_AudioListenerTest.testUpdateMatrixWorld);
    });
});