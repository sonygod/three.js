package audio;

import js.html.AudioContext;

class AudioContext {

    private static var _context:AudioContext;

    public static function getContext():AudioContext {
        if (_context == null) {
            _context = new (untyped window.AudioContext || untyped window.webkitAudioContext)();
        }
        return _context;
    }

    public static function setContext(value:AudioContext):Void {
        _context = value;
    }

}