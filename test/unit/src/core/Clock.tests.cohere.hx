import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.Browser.window;
import js.Browser.self;

import Clock from "../../../../src/core/Clock";

class _Test {
    static function main() {
        module("Core", setup: Setup.init, teardown: Setup.destroy);

        module("Clock", () -> {
            function mockPerformance() {
                var reference = (typeof global != "undefined") ? global : self;
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
            test("Instancing", function(assert) {
                // no params
                var object = new Clock();
                assert.ok(object, "Can instantiate a Clock.");

                // autostart
                var object_all = new Clock(false);
                assert.ok(object_all, "Can instantiate a Clock with autostart.");
            });

            // PROPERTIES
            todo("autoStart", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("startTime", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("oldTime", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("elapsedTime", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("running", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            // PUBLIC
            todo("start", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("stop", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("getElapsedTime", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            todo("getDelta", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });

            // OTHERS
            test("clock with performance", function(assert) {
                if (typeof performance == "undefined") {
                    assert.expect(0);
                    return;
                }

                mockPerformance();

                var clock = new Clock(false);

                clock.start();

                performance.next(123);
                assert.numEqual(clock.getElapsedTime(), 0.123, "okay");

                performance.next(100);
                assert.numEqual(clock.getElapsedTime(), 0.223, "okay");

                clock.stop();

                performance.next(1000);
                assert.numEqual(clock.getElapsedTime(), 0.223, "don't update time if the clock was stopped");
            });
        });
    }
}

class Setup {
    static function init() {
        if (window != null) {
            window.performance = { now: function() { return 0; } };
        } else if (self != null) {
            self.performance = { now: function() { return 0; } };
        }
    }

    static function destroy() {
        if (window != null) {
            delete window.performance;
        } else if (self != null) {
            delete self.performance;
        }
    }
}

@:init _Test.main();