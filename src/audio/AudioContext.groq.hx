package three.js.src.audio;

class AudioContext {
    private static var _context:Dynamic;

    public static function getContext():Dynamic {
        if (_context == null) {
            _context = untyped window.AudioContext != null ? new window.AudioContext() : new window.webkitAudioContext();
        }
        return _context;
    }

    public static function setContext(value:Dynamic):Void {
        _context = value;
    }
}