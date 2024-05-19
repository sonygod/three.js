package three.test.unit.src.audio;

import three.audio.PositionalAudio;
import three.audio.Audio;

class PositionalAudioTests {
    public function new() {}

    public static function main() {
        QUnit.module("Audios", () -> {
            QUnit.module("PositionalAudio", () -> {
                function mock3DListener():Dynamic {
                    return {
                        context: {
                            createGain: () -> {
                                return {
                                    connect: () -> {}
                                };
                            },
                            createPanner: () -> {
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
                    var listener = mock3DListener();
                    var object = new PositionalAudio(listener);
                    assert.strictEqual(object instanceof Audio, true, 'PositionalAudio extends from Audio');
                });

                // INSTANCING
                QUnit.test("Instancing", (assert:QUnitAssert) -> {
                    var listener = mock3DListener();
                    var object = new PositionalAudio(listener);
                    assert.ok(object, 'Can instantiate a PositionalAudio.');
                });

                // PROPERTIES
                QUnit.todo("panner", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                // PUBLIC
                QUnit.todo("disconnect", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getOutput", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getRefDistance", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setRefDistance", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getRolloffFactor", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setRolloffFactor", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getDistanceModel", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setDistanceModel", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("getMaxDistance", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setMaxDistance", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("setDirectionalCone", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });

                QUnit.todo("updateMatrixWorld", (assert:QUnitAssert) -> {
                    assert.ok(false, 'everything\'s gonna be alright');
                });
            });
        });
    }
}