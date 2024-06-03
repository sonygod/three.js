import three.audio.AudioListener;
import three.core.Object3D;
import qunit.QUnit;

class AudioListenerTests {

    public function new() {
        QUnit.module("Audios", () -> {
            QUnit.module("AudioListener", (hooks) -> {

                function mockWindowAudioContext() {
                    js.Browser.window = {
                        new: function() {
                            return {
                                createGain: function() {
                                    return {
                                        connect: function() {}
                                    };
                                }
                            };
                        }
                    };
                }

                if (js.Browser.window == null) {
                    hooks.before(function() {
                        mockWindowAudioContext();
                    });

                    hooks.after(function() {
                        js.Browser.window = null;
                    });
                }

                // INHERITANCE
                QUnit.test("Extending", (assert) -> {
                    var object = new AudioListener();
                    assert.strictEqual(Std.is(object, Object3D), true, 'AudioListener extends from Object3D');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var object = new AudioListener();
                    assert.ok(object, 'Can instantiate an AudioListener.');
                });

                // PROPERTIES
                QUnit.test("type", (assert) -> {
                    var object = new AudioListener();
                    assert.ok(object.type == 'AudioListener', 'AudioListener.type should be AudioListener');
                });

                // TODOs
                QUnit.todo("context", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("gain", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("filter", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("timeDelta", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // TODOs for public methods
                QUnit.todo("getInput", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("removeFilter", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getFilter", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setFilter", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getMasterVolume", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setMasterVolume", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("updateMatrixWorld", (assert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}