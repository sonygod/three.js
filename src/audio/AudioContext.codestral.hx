class AudioContext {

    private static var _context:js.AudioContext;

    public static function getContext():js.AudioContext {

        if (_context == null) {

            var ContextType = js.Browser.window.AudioContext != null ? js.Browser.window.AudioContext : js.Browser.window.webkitAudioContext;
            _context = new ContextType();

        }

        return _context;
    }

    public static function setContext(value:js.AudioContext) {

        _context = value;

    }

}