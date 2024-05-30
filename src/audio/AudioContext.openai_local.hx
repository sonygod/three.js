package three.audio;

class AudioContext {

    private static var _context:Dynamic;

    public static function getContext():Dynamic {

        if (_context == null) {

            #if js
            _context = new (untyped __js__('window.AudioContext || window.webkitAudioContext'))();
            #end

        }

        return _context;

    }

    public static function setContext(value:Dynamic):Void {

        _context = value;

    }

}