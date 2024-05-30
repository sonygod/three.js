import haxe.unit.TestCase;
import three.textures.Source;

class SourceTests {
    public function new() {}

    public function testInstancing() {
        var object = new Source();
        assertTrue(object != null, 'Can instantiate a Source.');
    }

    public function testData() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testNeedsUpdate() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testUuid() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testVersion() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsSource() {
        var object = new Source();
        assertTrue(object.isSource, 'Source.isSource should be true');
    }

    public function testToJson() {
        // todo: implement
        assertTrue(false, 'everything\'s gonna be alright');
    }
}