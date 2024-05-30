package three.js.test.unit.src.audio;

import haxe.unit.TestCase;
import js.html.AudioContext;

class AudioContextTest extends TestCase {
    public function new() { super(); }

    override public function setup():Void {
        #if js
        if (typeof window == 'undefined') {
            mockWindowAudioContext();
        }
        #end
    }

    override public function tearDown():Void {
        #if js
        if (typeof window == 'undefined') {
            window = null;
        }
        #end
    }

    function mockWindowAudioContext():Void {
        window = {
            AudioContext: function():AudioContext {
                return {
                    createGain: function():Dynamic {
                        return {
                            connect: function():Void {}
                        };
                    }
                };
            }
        };
    }

    public function testGetContext():Void {
        var context = AudioContext.getContext();
        assertEquals(true, context != null);
    }

    public function testSetContext():Void {
        AudioContext.setContext(new AudioContext());
        var context = AudioContext.getContext();
        assertEquals(true, context != null);
    }
}