@:noCompletion
class Clock {

    public var autoStart:Bool;
    public var startTime:Float;
    public var oldTime:Float;
    public var elapsedTime:Float;
    public var running:Bool;

    public function new(autoStart:Bool = true) {
        this.autoStart = autoStart;
        this.startTime = 0;
        this.oldTime = 0;
        this.elapsedTime = 0;
        this.running = false;
    }

    public function start():Void {
        this.startTime = now();
        this.oldTime = this.startTime;
        this.elapsedTime = 0;
        this.running = true;
    }

    public function stop():Void {
        this.getElapsedTime();
        this.running = false;
        this.autoStart = false;
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
            var newTime:Float = now();
            diff = (newTime - this.oldTime) / 1000;
            this.oldTime = newTime;
            this.elapsedTime += diff;
        }
        return diff;
    }
}

function now():Float {
    return (typeof performance == 'undefined' ? Date.now() : performance.now()); 
}

typedef ClockType = Clock;
```