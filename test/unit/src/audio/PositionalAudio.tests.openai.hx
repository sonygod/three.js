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
                QUnit.test("Extending", (assert) -> {
                    var listener = mock3DListener();
                    var object = new PositionalAudio(listener);
                    assert.isTrue(object instanceof Audio, "PositionalAudio extends from Audio");
                });

                // INSTANCING
                QUnit.test("Instancing", (assert) -> {
                    var listener = mock3DListener();
                    var object = new PositionalAudio(listener);
                    assert.ok(object, "Can instantiate a PositionalAudio.");
                });

                // PROPERTIES
                QUnit.todo("panner", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("disconnect", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getOutput", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getRefDistance", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setRefDistance", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getRolloffFactor", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setRolloffFactor", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getDistanceModel", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setDistanceModel", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getMaxDistance", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setMaxDistance", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("setDirectionalCone", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("updateMatrixWorld", (assert) -> {
                    assert.ok(false, "everything's gonna be alright");
                });
            });
        });
    }
}