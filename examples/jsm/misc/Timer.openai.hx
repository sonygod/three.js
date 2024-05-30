package three.js.examples.jsm.misc;

class Timer {
    
    private var _previousTime:Float;
    private var _currentTime:Float;
    private var _startTime:Float;

    private var _delta:Float;
    private var _elapsed:Float;

    private var _timescale:Float;

    private var _usePageVisibilityAPI:Bool;
    private var _pageVisibilityHandler:Void->Void;

    public function new() {
        _previousTime = 0;
        _currentTime = 0;
        _startTime = now();

        _delta = 0;
        _elapsed = 0;

        _timescale = 1;

        _usePageVisibilityAPI = ( js.Browser.document != null && js.Browser.document.hidden != null );

        if (_usePageVisibilityAPI) {
            _pageVisibilityHandler = handleVisibilityChange;
            js.Browser.document.addEventListener('visibilitychange', _pageVisibilityHandler);
        }
    }

    public function getDelta():Float {
        return _delta / 1000;
    }

    public function getElapsed():Float {
        return _elapsed / 1000;
    }

    public function getTimescale():Float {
        return _timescale;
    }

    public function setTimescale(timescale:Float):Timer {
        _timescale = timescale;
        return this;
    }

    public function reset():Timer {
        _currentTime = now() - _startTime;
        return this;
    }

    public function dispose():Timer {
        if (_usePageVisibilityAPI) {
            js.Browser.document.removeEventListener('visibilitychange', _pageVisibilityHandler);
        }
        return this;
    }

    public function update(?timestamp:Float):Timer {
        if (_usePageVisibilityAPI && js.Browser.document.hidden) {
            _delta = 0;
        } else {
            _previousTime = _currentTime;
            _currentTime = (timestamp != null ? timestamp : now()) - _startTime;
            _delta = (_currentTime - _previousTime) * _timescale;
            _elapsed += _delta;
        }
        return this;
    }
}

class FixedTimer extends Timer {
    
    public function new(?fps:Int = 60) {
        super();
        _delta = (1 / fps) * 1000;
    }

    override public function update():FixedTimer {
        _elapsed += (_delta * _timescale);
        return this;
    }
}

private function now():Float {
    return (js.Browser.performance != null ? js.Browser.performance.now() : Date.now());
}

private function handleVisibilityChange():Void {
    if (!js.Browser.document.hidden) {
        this.reset();
    }
}

extern class Timer {}
extern class FixedTimer {}

@:keep
@:expose("three.js.examples.jsm.misc")
class TimerModule {
    public static function __init__() {
        untyped __js__("module.exports = { Timer: three.js.examples.jsm.misc.Timer, FixedTimer: three.js.examples.jsm.misc.FixedTimer }");
    }
}