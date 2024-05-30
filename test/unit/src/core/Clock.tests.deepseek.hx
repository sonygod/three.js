package;

import js.Lib;
import js.Browser.window;
import js.Browser.performance;

class Clock {
    public var autoStart:Bool;
    public var startTime:Float = 0;
    public var oldTime:Float = 0;
    public var elapsedTime:Float = 0;
    public var running:Bool = false;

    public function new(autoStart:Bool = true) {
        this.autoStart = autoStart;
        if (autoStart) this.start();
    }

    public function start():Void {
        this.startTime = performance.now(); // 获取当前时间
        this.oldTime = this.startTime;
        this.elapsedTime = 0;
        this.running = true;
    }

    public function stop():Void {
        this.getElapsedTime();
        this.running = false;
    }

    public function getElapsedTime():Float {
        this.getDelta();
        return this.elapsedTime;
    }

    public function getDelta():Float {
        var diff:Float = 0;
        if (this.autoStart && !this.running) {
            this.start();
            return 0;
        }
        if (this.running) {
            var newTime:Float = performance.now();
            diff = (newTime - this.oldTime) / 1000;
            this.oldTime = newTime;
            this.elapsedTime += diff;
        }
        return diff;
    }
}

class TestClock {
    static function main() {
        // INSTANCING
        var object = new Clock();
        Lib.assert(object != null, 'Can instantiate a Clock.');

        var object_all = new Clock(false);
        Lib.assert(object_all != null, 'Can instantiate a Clock with autostart.');

        // PROPERTIES
        // TODO: Implement tests for autoStart, startTime, oldTime, elapsedTime, running

        // PUBLIC
        // TODO: Implement tests for start, stop, getElapsedTime, getDelta

        // OTHERS
        var clock = new Clock(false);
        clock.start();
        Lib.assert(performance.next(123), 0.123, 'okay');
        Lib.assert(performance.next(100), 0.223, 'okay');
        clock.stop();
        Lib.assert(performance.next(1000), 0.223, 'don\'t update time if the clock was stopped');
    }
}