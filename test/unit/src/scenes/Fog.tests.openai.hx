package three.test.unit.src.scenes;

import haxe.unit.TestCase;
import three.scenes.Fog;

class FogTest extends TestCase {

    public function testInstantiation() {
        // no params
        var object = new Fog();
        assertTrue(object != null, 'Can instantiate a Fog.');

        // color
        var object_color = new Fog(0xffffff);
        assertTrue(object_color != null, 'Can instantiate a Fog with color.');

        // color, near, far
        var object_all = new Fog(0xffffff, 0.015, 100);
        assertTrue(object_all != null, 'Can instantiate a Fog with color, near, far.');
    }

    public function todoName() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoColor() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoNear() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFar() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsFog() {
        var object = new Fog();
        assertTrue(object.isFog, 'Fog.isFog should be true');
    }

    public function todoClone() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToJson() {
        // TODO: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

}