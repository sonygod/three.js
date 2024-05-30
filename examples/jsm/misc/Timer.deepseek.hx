class Timer {

	var _previousTime:Float;
	var _currentTime:Float;
	var _startTime:Float;
	var _delta:Float;
	var _elapsed:Float;
	var _timescale:Float;
	var _usePageVisibilityAPI:Bool;
	var _pageVisibilityHandler:Dynamic;

	public function new() {

		_previousTime = 0;
		_currentTime = 0;
		_startTime = now();
		_delta = 0;
		_elapsed = 0;
		_timescale = 1;
		_usePageVisibilityAPI = (typeof document !== 'undefined' && document.hidden !== undefined);

		if (_usePageVisibilityAPI) {
			_pageVisibilityHandler = handleVisibilityChange.bind(this);
			document.addEventListener('visibilitychange', _pageVisibilityHandler, false);
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
			document.removeEventListener('visibilitychange', _pageVisibilityHandler);
		}
		return this;
	}

	public function update(timestamp:Float):Timer {
		if (_usePageVisibilityAPI && document.hidden) {
			_delta = 0;
		} else {
			_previousTime = _currentTime;
			_currentTime = (timestamp !== undefined ? timestamp : now()) - _startTime;
			_delta = (_currentTime - _previousTime) * _timescale;
			_elapsed += _delta;
		}
		return this;
	}

}

class FixedTimer extends Timer {

	public function new(fps:Float = 60) {
		super();
		_delta = (1 / fps) * 1000;
	}

	public function update():Timer {
		_elapsed += (_delta * _timescale);
		return this;
	}

}

static function now():Float {
	return (typeof performance === 'undefined' ? Date : performance).now();
}

static function handleVisibilityChange() {
	if (document.hidden === false) this.reset();
}

typedef TimerType = {
	var _previousTime:Float;
	var _currentTime:Float;
	var _startTime:Float;
	var _delta:Float;
	var _elapsed:Float;
	var _timescale:Float;
	var _usePageVisibilityAPI:Bool;
	var _pageVisibilityHandler:Dynamic;
}

typedef FixedTimerType = {
	var _delta:Float;
}