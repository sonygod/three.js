class AudioContext {

	static var _context:AudioContext;

	public static function getContext():AudioContext {

		if (_context == null) {
			_context = new (js.Browser.window.AudioContext || js.Browser.window.webkitAudioContext)();
		}

		return _context;

	}

	public static function setContext(value:AudioContext) {

		_context = value;

	}

}