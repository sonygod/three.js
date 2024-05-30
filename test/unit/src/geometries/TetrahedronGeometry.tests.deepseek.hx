// 导入必要的类
import three.js.test.unit.src.geometries.TetrahedronGeometry;
import three.js.test.unit.src.geometries.PolyhedronGeometry;
import three.js.test.unit.utils.qunit_utils.runStdGeometryTests;

// 定义模块
class TetrahedronGeometryTests {

    static function main() {

        // 定义变量
        var geometries:Array<TetrahedronGeometry>;

        // 在每个测试之前执行的函数
        function beforeEach() {

            var parameters = {
                radius: 10,
                detail: null
            };

            geometries = [
                new TetrahedronGeometry(),
                new TetrahedronGeometry(parameters.radius),
                new TetrahedronGeometry(parameters.radius, parameters.detail)
            ];

        }

        // 测试继承
        function testExtending() {

            var object = new TetrahedronGeometry();
            unittest.assert(object instanceof PolyhedronGeometry);

        }

        // 测试实例化
        function testInstancing() {

            var object = new TetrahedronGeometry();
            unittest.assert(object != null);

        }

        // 测试类型
        function testType() {

            var object = new TetrahedronGeometry();
            unittest.assert(object.type == "TetrahedronGeometry");

        }

        // 测试参数（待办事项）
        function testParameters() {

            unittest.todo("Parameters test is not implemented yet.");

        }

        // 测试从JSON（待办事项）
        function testFromJSON() {

            unittest.todo("FromJSON test is not implemented yet.");

        }

        // 测试标准几何体
        function testStandardGeometry() {

            runStdGeometryTests(unittest, geometries);

        }

        // 运行测试
        beforeEach();
        testExtending();
        testInstancing();
        testType();
        testParameters();
        testFromJSON();
        testStandardGeometry();

    }

}