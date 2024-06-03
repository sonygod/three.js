import QUnit;
import QUnitTestRunner;

class InterpolationsTests {

    public static function main() {
        QUnit.module("Extras", () -> {
            QUnit.module("Core", () -> {
                QUnit.module("Interpolations", () -> {
                    QUnitTestRunner.current.addTest("CatmullRom", (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnitTestRunner.current.addTest("QuadraticBezier", (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });

                    QUnitTestRunner.current.addTest("CubicBezier", (assert) -> {
                        assert.ok(false, 'everything\'s gonna be alright');
                    });
                });
            });
        });
    }
}