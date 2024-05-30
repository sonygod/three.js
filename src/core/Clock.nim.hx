import haxe.Timer;

class Clock {
    public var autoStart(default, null):Bool;
    public var startTime(default, null):Float;
    public var oldTime(default, null):Float;
    public var elapsedTime(default, null):Float;
    public var running(default, null):Bool;

    public function new(autoStart:Bool = true) {
        this.autoStart = autoStart;
        this.startTime = 0;
        this.oldTime = 0;
        this.elapsedTime = 0;
        this.running = false;
    }

    public function start() {
        this.startTime = Timer.stamp();
        this.oldTime = this.startTime;
        this.elapsedTime = 0;
        this.running = true;
    }

    public function stop() {
        this.getElapsedTime();
        this.running = false;
        this.autoStart = false;
    }

    public function getElapsedTime() {
        this.getDelta();
        return this.elapsedTime;
    }

    public function getDelta() {
        var diff = 0;

        if (this.autoStart && !this.running) {
            this.start();
            return 0;
        }

        if (this.running) {
            var newTime = Timer.stamp();
            diff = (newTime - this.oldTime) / 1000;
            this.oldTime = newTime;
            this.elapsedTime += diff;
        }

        return diff;
    }
}