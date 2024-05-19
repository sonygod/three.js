import js.Browser;

class AudioContext {

	static var _context(default, null) : js.html.AudioContext;

	public static function getContext():js.html.AudioContext {

		if (_context == null) {

			_context = new js.html.AudioContext();

		}

		return _context;

	}

	public static function setContext(value:js.html.AudioContext):Void {

		_context = value;

	}

}