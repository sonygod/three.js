Here is the converted Haxe code:
```
package three.js.examples.jm.misc;

class Timer {
    private var _previousTime:Float;
    private var _currentTime:Float;
    private var _startTime:Float;

    private var _delta:Float;
    private var _elapsed:Float;

    private var _timescale:Float;

    private var _usePageVisibilityAPI:Bool;
    private var _pageVisibilityHandler:Dynamic;

    public function new() {
        _previousTime = 0;
        _currentTime = 0;
        _startTime = now();

        _delta = 0;
        _elapsed = 0;

        _timescale = 1;

        _usePageVisibilityAPI = (untyped document != null && untyped document.hidden != null);

        if (_usePageVisibilityAPI) {
            _pageVisibilityHandler = handleVisibilityChange.bind(this);
            untyped document.addEventListener('visibilitychange', _pageVisibilityHandler, false);
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
            untyped document.removeEventListener('visibilitychange', _pageVisibilityHandler);
        }
        return this;
    }

    public function update(?timestamp:Float):Timer {
        if (_usePageVisibilityAPI && untyped document.hidden) {
            _delta = 0;
        } else {
            _previousTime = _currentTime;
            _currentTime = (timestamp != null ? timestamp : now()) - _startTime;

            _delta = (_currentTime - _previousTime) * _timescale;
            _elapsed += _delta; // _elapsed is the accumulation of all previous deltas
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
        _elapsed += (_delta * _timescale); // _elapsed is the accumulation of all previous deltas
        return this;
    }
}

private function now():Float {
    return (untyped performance == null ? Date : performance).now();
}

private function handleVisibilityChange():Void {
    if (!untyped document.hidden) this.reset();
}
```
Note that I've used the `untyped` keyword to access the `document` and `performance` objects, as they are not part of the Haxe standard library. You may need to adjust the code to fit your specific use case.

Also, I've kept the same naming conventions and coding style as the original JavaScript code. If you want to follow Haxe's conventions, you may want to adjust the code accordingly.