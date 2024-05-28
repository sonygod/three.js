package three.audio;

class AudioContext {
  static var _context:Dynamic;

  static public function getContext():Dynamic {
    if (_context == null) {
      _context = untyped (js.Browser.getWindow().AudioContext != null) ? new js.html.audio.AudioContext() : new js.html.audio.WebkitAudioContext();
    }
    return _context;
  }

  static public function setContext(value:Dynamic) {
    _context = value;
  }
}