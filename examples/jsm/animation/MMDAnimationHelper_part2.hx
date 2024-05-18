package three.js.examples.jm.animation;

class AudioManager {
    public var audio:three.js.Audio;
    public var elapsedTime:Float;
    public var currentTime:Float;
    public var delayTime:Float;
    public var audioDuration:Float;
    public var duration:Float;

    public function new(audio:three.js.Audio, ?params:Dynamic) {
        this.audio = audio;

        this.elapsedTime = 0.0;
        this.currentTime = 0.0;
        this.delayTime = params != null && params.delayTime != null ? params.delayTime : 0.0;

        this.audioDuration = audio.buffer.duration;
        this.duration = this.audioDuration + this.delayTime;
    }

    public function control(delta:Float):AudioManager {
        this.elapsedTime += delta;
        this.currentTime += delta;

        if (_shouldStopAudio()) audio.stop();
        if (_shouldStartAudio()) audio.play();

        return this;
    }

    private function _shouldStartAudio():Bool {
        if (audio.isPlaying) return false;

        while (currentTime >= duration) {
            currentTime -= duration;
        }

        if (currentTime < delayTime) return false;

        // 'duration' can be bigger than 'audioDuration + delayTime' because of sync configuration
        if ((currentTime - delayTime) > audioDuration) return false;

        return true;
    }

    private function _shouldStopAudio():Bool {
        return audio.isPlaying && currentTime >= duration;
    }
}