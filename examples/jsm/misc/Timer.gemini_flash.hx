import haxe.Timer;
import js.Browser;
import js.html.Window;

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
		this._previousTime = 0;
		this._currentTime = 0;
		this._startTime = now();
		this._delta = 0;
		this._elapsed = 0;
		this._timescale = 1;
		this._usePageVisibilityAPI = ( typeof(Browser.document) != 'undefined' && Browser.document.hidden != null );
		if ( this._usePageVisibilityAPI ) {
			this._pageVisibilityHandler = handleVisibilityChange.bind(this);
			Browser.document.addEventListener('visibilitychange', this._pageVisibilityHandler, false);
		}
	}

	public function getDelta():Float {
		return this._delta / 1000;
	}

	public function getElapsed():Float {
		return this._elapsed / 1000;
	}

	public function getTimescale():Float {
		return this._timescale;
	}

	public function setTimescale(timescale:Float):Timer {
		this._timescale = timescale;
		return this;
	}

	public function reset():Timer {
		this._currentTime = now() - this._startTime;
		return this;
	}

	public function dispose():Timer {
		if ( this._usePageVisibilityAPI ) {
			Browser.document.removeEventListener('visibilitychange', this._pageVisibilityHandler);
		}
		return this;
	}

	public function update(timestamp:Float = -1):Timer {
		if ( this._usePageVisibilityAPI && Browser.document.hidden ) {
			this._delta = 0;
		} else {
			this._previousTime = this._currentTime;
			this._currentTime = ( timestamp != -1 ? timestamp : now() ) - this._startTime;
			this._delta = ( this._currentTime - this._previousTime ) * this._timescale;
			this._elapsed += this._delta;
		}
		return this;
	}

}

class FixedTimer extends Timer {

	public function new(fps:Float = 60) {
		super();
		this._delta = ( 1 / fps ) * 1000;
	}

	public function update():Timer {
		this._elapsed += ( this._delta * this._timescale );
		return this;
	}

}

function now():Float {
	return ( typeof(Browser.window.performance) != 'undefined' ? Browser.window.performance.now() : Date.now() );
}

function handleVisibilityChange() {
	if ( Browser.document.hidden == false ) this.reset();
}