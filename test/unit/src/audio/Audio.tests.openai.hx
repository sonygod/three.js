import haxe.unit.TestCase;
import Audio from "../../../../src/audio/Audio.hx";
import Object3D from "../../../../src/core/Object3D.hx";

class AudioTests {

    public function new() {}

    public function testExtending():Void {
        var listener:Dynamic = mockListener();
        var object:Audio = new Audio(listener);
        assertEquals(true, Std.is(object, Object3D), 'Audio extends from Object3D');
    }

    public function testInstancing():Void {
        var listener:Dynamic = mockListener();
        var object:Audio = new Audio(listener);
        assertNotNull(object, 'Can instantiate an Audio.');
    }

    public function testType():Void {
        var listener:Dynamic = mockListener();
        var object:Audio = new Audio(listener);
        assertEquals('Audio', object.type, 'Audio.type should be Audio');
    }

    // ...

    function mockListener():Dynamic {
        return {
            context: {
                createGain: function():Dynamic {
                    return {
                        connect: function() {}
                    };
                }
            },
            getInput: function() {}
        };
    }

    static public function main() {
        var testCase = new AudioTests();
        testCase.testExtending();
        testCase.testInstancing();
        testCase.testType();
        // ...
    }
}