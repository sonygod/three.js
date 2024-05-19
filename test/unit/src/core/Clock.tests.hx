package three.test.unit.src.core;

import three.core.Clock;

class ClockTests {

    public function new() {}

    public static function main() {
        QUnit.module("Core", () => {
            QUnit.module("Clock", () => {
                function mockPerformance() {
                    var reference = (untyped __global__["global"] != null) ? untyped __global__["global"] : untyped __js__("self");
                    reference.performance = {
                        deltaTime: 0,
                        next: function(delta) {
                            this.deltaTime += delta;
                        },
                        now: function() {
                            return this.deltaTime;
                        }
                    };
                }

                // INSTANCING
                QUnit.test("Instancing", (assert) => {
                    // no params
                    var object = new Clock();
                    assert.ok(object, "Can instantiate a Clock.");
                    // autostart
                    var object_all = new Clock(false);
                    assert.ok(object_all, "Can instantiate a Clock with autostart.");
                });

                // PROPERTIES
                QUnit.todo("autoStart", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("startTime", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("oldTime", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("elapsedTime", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("running", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // PUBLIC
                QUnit.todo("start", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("stop", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getElapsedTime", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                QUnit.todo("getDelta", (assert) => {
                    assert.ok(false, "everything's gonna be alright");
                });

                // OTHERS
                QUnit.test("clock with performance", (assert) => {
                    if (untyped __js__("typeof performance") == "undefined") {
                        assert.expect(0);
                        return;
                    }

                    mockPerformance();

                    var clock = new Clock(false);

                    clock.start();

                    untyped __js__("performance").next(123);
                    assert.numEqual(clock.getElapsedTime(), 0.123, "okay");

                    untyped __js__("performance").next(100);
                    assert.numEqual(clock.getElapsedTime(), 0.223, "okay");

                    clock.stop();

                    untyped __js__("performance").next(1000);
                    assert.numEqual(clock.getElapsedTime(), 0.223, "don't update time if the clock was stopped");
                });
            });
        });
    }
}