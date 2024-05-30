import js.Browser.Window;
import js.html.AudioContext;
import js.QUnit.*;

class AudiosTest {
    static function testAudioContext() {
        function mockWindowAudioContext() {
            window = {
                AudioContext: function() {
                    return {
                        createGain: function() {
                            return {
                                connect: function() {
                                }
                            };
                        }
                    };
                }
            };
        }

        if (window == null) {
            before(function() {
                mockWindowAudioContext();
            });

            after(function() {
                window = null;
            });
        }

        // STATIC
        test("getContext", function() {
            var context = AudioContext.getContext();
            ok(Std.is(context, Object), "AudioContext.getContext creates a context.");
        });

        test("setContext", function() {
            AudioContext.setContext(new window.AudioContext());
            var context = AudioContext.getContext();
            ok(Std.is(context, Object), "AudioContext.setContext updates the context.");
        });
    }
}

class Audios {
    static function test() {
        module("Audios", function() {
            module("AudioContext", function() {
                AudiosTest.testAudioContext();
            });
        });
    }
}