class AudioContext {

    static var _context:AudioContext;

    static function getContext():AudioContext {

        if ( _context == null ) {

            _context = new ( js.Browser.window.AudioContext || js.Browser.window.webkitAudioContext )();

        }

        return _context;

    }

    static function setContext(value:AudioContext):Void {

        _context = value;

    }

}