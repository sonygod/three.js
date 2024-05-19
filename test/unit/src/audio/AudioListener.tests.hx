package three.audio;

import haxe.unit.TestCase;
import three.audio.AudioListener;
import three.core.Object3D;

class AudioListenerTests {
    public function new() {}

    public function testAll() {
        testExtending();
        testInstancing();
        testType();
        // todo: implement other tests
    }

    function testExtending() {
        var object = new AudioListener();
        assertEquals(object instanceof Object3D, true, 'AudioListener extends from Object3D');
    }

    function testInstancing() {
        var object = new AudioListener();
        assertTrue(object != null, 'Can instantiate an AudioListener.');
    }

    function testType() {
        var object = new AudioListener();
        assertEquals(object.type, 'AudioListener', 'AudioListener.type should be AudioListener');
    }

    // todo: implement other tests
}