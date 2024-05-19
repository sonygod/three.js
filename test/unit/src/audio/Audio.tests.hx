package three.audio;

import js.html.qunit.QUnit;
import three.Audio;
import three.Object3D;

class AudioTests {
    public function new() {}

    public static function main():Void {
        QUnit.module("Audios", () => {
            QUnit.module("Audio", () => {
                function mockListener():Dynamic {
                    return {
                        context: {
                            createGain: () -> {
                                return {
                                    connect: () -> {}
                                };
                            }
                        },
                        getInput: () -> {}
                    };
                }

                // INHERITANCE
                QUnit.test("Extending", (assert:QUnitAssert) -> {
                    var listener = mockListener();
                    var object:Audio = new Audio(listener);
                    assert.ok(object instanceof Object3D, 'Audio extends from Object3D');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) -> {
                    var listener = mockListener();
                    var object:Audio = new Audio(listener);
                    assert.ok(object != null, 'Can instantiate an Audio.');
                });

                // PROPERTIES
                QUnit.test("type", (assert:QUnitAssert) -> {
                    var listener = mockListener();
                    var object:Audio = new Audio(listener);
                    assert.ok(object.type == 'Audio', 'Audio.type should be Audio');
                });

                QUnit.todo("listener", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("context", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("gain", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("autoplay", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("buffer", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("detune", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("loop", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("loopStart", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("loopEnd", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("offset", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("duration", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("playbackRate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("isPlaying", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("hasPlaybackControl", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("source", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("sourceType", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("filters", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.todo("getOutput", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setNodeSource", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setMediaElementSource", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setMediaStreamSource", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setBuffer", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("play", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("pause", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("stop", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("connect", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("disconnect", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getFilters", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setFilters", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setDetune", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getDetune", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getFilter", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setFilter", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setPlaybackRate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getPlaybackRate", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("onEnded", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getLoop", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setLoop", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setLoopStart", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setLoopEnd", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getVolume", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setVolume", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}