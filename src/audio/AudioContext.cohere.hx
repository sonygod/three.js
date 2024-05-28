class AudioContext {
    private static var _context:Dynamic;

    public static function getContext():Dynamic {
        if (_context == null) {
            _context = new (js.Browser.window.AudioContext || js.Browser.window.webkitAudioContext)();
        }
        return _context;
    }

    public static function setContext(value:Dynamic):Void {
        _context = value;
    }
}