class Clock {
    var autoStart: Bool;
    var startTime: Float;
    var oldTime: Float;
    var elapsedTime: Float;
    var running: Bool;

    public function new(autoStart: Bool = true) {
        this.autoStart = autoStart;
        this.startTime = 0.0;
        this.oldTime = 0.0;
        this.elapsedTime = 0.0;
        this.running = false;
    }

    public function start() {
        this.startTime = now();
        this.oldTime = this.startTime;
        this.elapsedTime = 0.0;
        this.running = true;
    }

    public function stop() {
        this.getElapsedTime();
        this.running = false;
        this.autoStart = false;
    }

    public function getElapsedTime(): Float {
        this.getDelta();
        return this.elapsedTime;
    }

    public function getDelta(): Float {
        var diff: Float = 0.0;

        if (this.autoStart && !this.running) {
            this.start();
            return 0.0;
        }

        if (this.running) {
            var newTime: Float = now();
            diff = (newTime - this.oldTime) / 1000.0;
            this.oldTime = newTime;
            this.elapsedTime += diff;
        }

        return diff;
    }

    private function now(): Float {
        // Haxe does not have a direct equivalent to JavaScript's performance.now(),
        // so you might need to use a library or implement a custom function.
        // For simplicity, this function just returns the current time in milliseconds.
        return Sys.time();
    }
}