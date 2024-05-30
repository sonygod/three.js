package;

import three.audio.AudioListener;
import three.core.Object3D;
import js.Browser;
import js.Lib;

class AudioListenerTest {

    static function main() {
        var listener = new AudioListener();
        Lib.assert(listener instanceof Object3D);
        Lib.assert(listener.type == "AudioListener");
    }

    static function mockWindowAudioContext() {
        Browser.window.AudioContext = function () {
            return {
                createGain: function () {
                    return {
                        connect: function () {}
                    };
                }
            };
        };
    }
}

class TestRunner {
    static function main() {
        AudioListenerTest.mockWindowAudioContext();
        AudioListenerTest.main();
    }
}

TestRunner.main();