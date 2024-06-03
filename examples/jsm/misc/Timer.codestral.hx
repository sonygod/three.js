class Timer {
    private var _previousTime: Float = 0.0;
    private var _currentTime: Float = 0.0;
    private var _startTime: Float = now();
    private var _delta: Float = 0.0;
    private var _elapsed: Float = 0.0;
    private var _timescale: Float = 1.0;

    public function new() {
        // Empty constructor
    }

    public function getDelta(): Float {
        return this._delta / 1000;
    }

    public function getElapsed(): Float {
        return this._elapsed / 1000;
    }

    public function getTimescale(): Float {
        return this._timescale;
    }

    public function setTimescale(timescale: Float): Timer {
        this._timescale = timescale;
        return this;
    }

    public function reset(): Timer {
        this._currentTime = now() - this._startTime;
        return this;
    }

    public function dispose(): Timer {
        // There's no equivalent for Page Visibility API in Haxe, so this function is empty
        return this;
    }

    public function update(timestamp: Float = now()): Timer {
        this._previousTime = this._currentTime;
        this._currentTime = timestamp - this._startTime;
        this._delta = (this._currentTime - this._previousTime) * this._timescale;
        this._elapsed += this._delta;
        return this;
    }
}

class FixedTimer extends Timer {
    public function new(fps: Int = 60) {
        super();
        this._delta = (1 / fps) * 1000;
    }

    public function update(): Timer {
        this._elapsed += (this._delta * this._timescale);
        return this;
    }
}

function now(): Float {
    return js.Date.now();
}

// There's no equivalent for Page Visibility API in Haxe, so this function is not included