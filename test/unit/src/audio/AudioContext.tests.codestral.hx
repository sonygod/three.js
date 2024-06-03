import js.Browser.document;
import qunit.QUnit;
import three.audio.AudioContext;

class AudioContextTests {

    static function mockWindowAudioContext(): Void {
        js.Browser.window.AudioContext = function() {
            return {
                createGain: function() {
                    return {
                        connect: function() {}
                    };
                }
            };
        };
    }

    public static function main() {
        QUnit.module("Audios", () -> {
            QUnit.module("AudioContext", (hooks: QUnitHooks) -> {
                if (js.Browser.window == null) {
                    hooks.before(function() {
                        mockWindowAudioContext();
                    });

                    hooks.after(function() {
                        js.Browser.window = null;
                    });
                }

                QUnit.test("getContext", (assert: QUnitAssert) -> {
                    var context = AudioContext.getContext();
                    assert.strictEqual(
                        Std.is(context, Object), true,
                        "AudioContext.getContext creates a context."
                    );
                });

                QUnit.test("setContext", (assert: QUnitAssert) -> {
                    AudioContext.setContext(new js.Browser.window.AudioContext());
                    var context = AudioContext.getContext();
                    assert.strictEqual(
                        Std.is(context, Object), true,
                        "AudioContext.setContext updates the context."
                    );
                });
            });
        });
    }
}