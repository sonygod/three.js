package three.js.test.unit.src.geometries;

import utest.Runner;
import utest.ui.Report;
import three.js.geometries.TetrahedronGeometry;
import three.js.geometries.PolyhedronGeometry;
import three.js.utils.qunit.QUnitUtils;

class TetrahedronGeometryTests {
    public static function main() {
        var runner = new Runner();
        runner.addCase(new TetrahedronGeometryTests());
        Report.create(runner);
        runner.run();
    }

    public function new() {}

    public function setup() {}

    public function tearDown() {}

    public function testExtending() {
        var object = new TetrahedronGeometry();
        Assert.isTrue(object instanceof PolyhedronGeometry, 'TetrahedronGeometry extends from PolyhedronGeometry');
    }

    public function testInstancing() {
        var object = new TetrahedronGeometry();
        Assert.notNull(object, 'Can instantiate a TetrahedronGeometry.');
    }

    public function testType() {
        var object = new TetrahedronGeometry();
        Assert.equals(object.type, 'TetrahedronGeometry', 'TetrahedronGeometry.type should be TetrahedronGeometry');
    }

    public function testTodoParameters() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testTodoFromJSON() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function testStandardGeometryTests() {
        var geometries = [
            new TetrahedronGeometry(),
            new TetrahedronGeometry(10),
            new TetrahedronGeometry(10, null),
        ];
        QUnitUtils.runStdGeometryTests(geometries);
    }
}