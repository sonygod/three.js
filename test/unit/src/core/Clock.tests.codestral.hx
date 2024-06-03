import js.Browser.document;
import three.core.Clock;

class ClockTest {

    static function main() {
        js.QUnit.module("Core", () -> {
            js.QUnit.module("Clock", () -> {

                function mockPerformance() {
                    var reference = (js.Browser.window != null) ? js.Browser.window : js.Browser.self;
                    reference.performance = {
                        deltaTime: 0,
                        next: function(delta: Float) {
                            this.deltaTime += delta;
                        },
                        now: function() {
                            return this.deltaTime;
                        }
                    };
                }

                // INSTANCING
                js.QUnit.test("Instancing", (assert) -> {
                    var object = new Clock();
                    assert.ok(object, 'Can instantiate a Clock.');

                    var object_all = new Clock(false);
                    assert.ok(object_all, 'Can instantiate a Clock with autostart.');
                });

                // OTHERS
                js.QUnit.test("clock with performance", (assert) -> {
                    if (js.Browser.performance == null) {
                        assert.expect(0);
                        return;
                    }

                    mockPerformance();

                    var clock = new Clock(false);

                    clock.start();

                    js.Browser.performance.next(123);
                    assert.numEqual(clock.getElapsedTime(), 0.123, 'okay');

                    js.Browser.performance.next(100);
                    assert.numEqual(clock.getElapsedTime(), 0.223, 'okay');

                    clock.stop();

                    js.Browser.performance.next(1000);
                    assert.numEqual(clock.getElapsedTime(), 0.223, 'don\'t update time if the clock was stopped');
                });
            });
        });
    }
}