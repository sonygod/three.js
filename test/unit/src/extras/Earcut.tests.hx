import haxe.unit.TestCase;
import haxe.unit.TestRunner;

class EarcutTests {

    public function new() {}

    public function testTriangulate() {
        #if (haxe_ver >= 4)
        Assert.fail("Not implemented");
        #else
        throw new haxe.exceptions.NotImplementedException();
        #end
    }

    public static function main() {
        var runner = new TestRunner();
        runner.add(new EarcutTests());
        runner.run();
    }
}