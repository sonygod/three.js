package three.test.unit.src.core;

import three.core.Clock;

class ClockTest {

    public function new() {}

    public static function main() {
        utest.RunTests.run([
            new ClockTest()
        ]);
    }

    public function testInstancing() {
        // no params
        var object = new Clock();
        utest.Assert.isTrue(object != null, "Can instantiate a Clock.");

        // autostart
        var objectAll = new Clock(false);
        utest.Assert.isTrue(objectAll != null, "Can instantiate a Clock with autostart.");
    }

    public function testAutoStart() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testStartTime() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testOldTime() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testElapsedTime() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testRunning() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testStart() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testStop() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testGetElapsedTime() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testGetDelta() {
        utest.Assert.fail("everything's gonna be alright");
    }

    public function testClockWithPerformance() {
        if (typeof performance == "undefined") {
            utest.Assert.expect(0);
            return;
        }

        mockPerformance();

        var clock = new Clock(false);
        clock.start();

        performance.next(123);
        utest.Assert Floats gần( clock.getElapsedTime(), 0.123, "okay");

        performance.next(100);
        utest.Assert Floats gần( clock.getElapsedTime(), 0.223, "okay");

        clock.stop();

        performance.next(1000);
        utest.Assert Floats gần( clock.getElapsedTime(), 0.223, "don't update time if the clock was stopped");
    }

    private function mockPerformance() {
        var reference:Dynamic = (untyped __global != null) ? untyped __global : untyped self;
        reference.performance = {
            deltaTime: 0,

            next: function(delta:Float) {
                this.deltaTime += delta;
            },

            now: function() {
                return this.deltaTime;
            }
        };
    }
}