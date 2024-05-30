import js.html.AudioContext;

class AudioContext {
    static var _context:Dynamic;

    static function getContext():Dynamic {
        if (_context === null) {
            _context = Type.createInstance(Type.resolve(js.Browser.window, 'AudioContext') || Type.resolve(js.Browser.window, 'webkitAudioContext'), []);
        }
        return _context;
    }

    static function setContext(value:Dynamic):Void {
        _context = value;
    }
}