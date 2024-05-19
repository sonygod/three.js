package three.test.unit.src.extras.core;

import haxe.unit.TestCase;
import three.extras.core.Shape;
import three.extras.core.Path;

class ShapeTest extends TestCase {
    public function new() {
        super();
    }

    public function testExtending() {
        var object = new Shape();
        assertTrue(object instanceof Path, 'Shape extends from Path');
    }

    public function testInstancing() {
        var object = new Shape();
        assertNotNull(object, 'Can instantiate a Shape.');
    }

    public function testType() {
        var object = new Shape();
        assertEquals(object.type, 'Shape', 'Shape.type should be Shape');
    }

    public function testUuid() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testHoles() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testGetPointsHoles() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testExtractPoints() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCopy() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testToJSON() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testFromJSON() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }
}