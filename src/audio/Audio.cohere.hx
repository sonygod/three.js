package ;

import openfl.media.AudioLoader;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;

class Audio {
    private var _sound:Sound;
    private var _channel:SoundChannel;
    private var _autoPlay:Bool;
    private var _volume:Float;
    private var _isPlaying:Bool;
    private var _soundTransform:SoundTransform;

    public function new(sound:Sound, autoPlay:Bool = false, volume:Float = 1.0, loop:Bool = false) {
        _sound = sound;
        _autoPlay = autoPlay;
        _volume = volume;
        _isPlaying = false;
        _soundTransform = new SoundTransform(volume, 0);

        if (autoPlay) {
            play();
        }
    }

    public function play():Void {
        if (_isPlaying) {
            return;
        }

        _channel = _sound.play(true, _soundTransform);
        _isPlaying = true;
    }

    public function pause():Void {
        if (!_isPlaying) {
            return;
        }

        _channel.stop();
        _isPlaying = false;
    }

    public function stop():Void {
        if (!_isPlaying) {
            return;
        }

        _channel.stop();
        _channel = null;
        _isPlaying = false;
    }

    public function set volume(value:Float):Void {
        _volume = value;
        if (_isPlaying) {
            _soundTransform.volume = value;
        }
    }

    public function get volume():Float {
        return _volume;
    }

    public function set loop(value:Bool):Void {
        if (_isPlaying) {
            _channel.stop();
            _isPlaying = false;
            play();
        }
    }

    public function get loop():Bool {
        return _isPlaying;
    }
}