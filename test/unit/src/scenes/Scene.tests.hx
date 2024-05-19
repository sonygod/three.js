package three.test.unit.src.scenes;

import haxe.unit.TestCase;
import three.scenes.Scene;
import three.core.Object3D;

class SceneTest extends TestCase {

    public function new() {
        super();
    }

    public function testExtending() {
        var object:Scene = new Scene();
        assertTrue(object instanceof Object3D, 'Scene extends from Object3D');
    }

    public function testInstancing() {
        var object:Scene = new Scene();
        assertNotNull(object, 'Can instantiate a Scene.');
    }

    public function testType() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testBackground() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testEnvironment() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testFog() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testBackgroundBlurriness() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testBackgroundIntensity() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testOverrideMaterial() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsScene() {
        var object:Scene = new Scene();
        assertTrue(object.isScene, 'Scene.isScene should be true');
    }

    public function testCopy() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testToJSON() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }
}