import haxe.unit.TestCase;

class LineLoopTests {
    public function new() {}

    public function testExtending() {
        var lineLoop = new LineLoop();
        assertEquals(lineLoop instanceof Object3D, true, 'LineLoop extends from Object3D');
        assertEquals(lineLoop instanceof Line, true, 'LineLoop extends from Line');
    }

    public function testInstancing() {
        var object = new LineLoop();
        assertTrue(object != null, 'Can instantiate a LineLoop.');
    }

    public function testType() {
        var object = new LineLoop();
        assertEquals(object.type, 'LineLoop', 'LineLoop.type should be LineLoop');
    }

    public function testIsLineLoop() {
        var object = new LineLoop();
        assertTrue(object.isLineLoop, 'LineLoop.isLineLoop should be true');
    }

    public static function main() {
        var runner = new haxe.unit.TestRunner();
        runner.add(new LineLoopTests());
        runner.run();
    }
}