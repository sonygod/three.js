class AudioManager {

    public var audio:Audio;
    public var elapsedTime:Float;
    public var currentTime:Float;
    public var delayTime:Float;
    public var audioDuration:Float;
    public var duration:Float;

    public function new(audio:Audio, ?params:Dynamic) {

        this.audio = audio;

        this.elapsedTime = 0.0;
        this.currentTime = 0.0;
        this.delayTime = params != null && params.delayTime != null
            ? Std.parseFloat(params.delayTime) : 0.0;

        this.audioDuration = this.audio.buffer.duration;
        this.duration = this.audioDuration + this.delayTime;

    }

    public function control(delta:Float):AudioManager {

        this.elapsedTime += delta;
        this.currentTime += delta;

        if (this._shouldStopAudio()) this.audio.stop();
        if (this._shouldStartAudio()) this.audio.play();

        return this;

    }

    // private methods

    private function _shouldStartAudio():Bool {

        if (this.audio.isPlaying) return false;

        while (this.currentTime >= this.duration) {

            this.currentTime -= this.duration;

        }

        if (this.currentTime < this.delayTime) return false;

        // 'duration' can be bigger than 'audioDuration + delayTime' because of sync configuration
        if ((this.currentTime - this.delayTime) > this.audioDuration) return false;

        return true;

    }

    private function _shouldStopAudio():Bool {

        return this.audio.isPlaying &&
            this.currentTime >= this.duration;

    }

}