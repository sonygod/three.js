package;

import js.Browser;
import js.html.AudioContext;
import js.html.GainNode;
import QUnit.QUnit;

class AudioContextTest {

    static var context:AudioContext;

    static function mockWindowAudioContext() {
        Browser.window.AudioContext = function() {
            return {
                createGain: function() {
                    return {
                        connect: function() {}
                    };
                }
            };
        };
    }

    static function before() {
        mockWindowAudioContext();
    }

    static function after() {
        Browser.window = null;
    }

    static function getContext() {
        var context = AudioContext.getContext();
        QUnit.ok(context != null, 'AudioContext.getContext creates a context.');
    }

    static function setContext() {
        AudioContext.setContext(new Browser.window.AudioContext());
        var context = AudioContext.getContext();
        QUnit.ok(context != null, 'AudioContext.setContext updates the context.');
    }

    static function main() {
        QUnit.module('Audios');
        QUnit.module('AudioContext');
        QUnit.test('getContext', getContext);
        QUnit.test('setContext', setContext);
        QUnit.run();
    }

    static function init() {
        js.Browser.window.onLoad.add(main);
    }

    static function main() {
        js.Browser.window.onLoad.add(init);
    }
}