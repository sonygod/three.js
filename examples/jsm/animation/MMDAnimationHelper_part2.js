class AudioManager {

	/**
	 * @param {THREE.Audio} audio
	 * @param {Object} params - (optional)
	 * @param {Nuumber} params.delayTime
	 */
	constructor( audio, params = {} ) {

		this.audio = audio;

		this.elapsedTime = 0.0;
		this.currentTime = 0.0;
		this.delayTime = params.delayTime !== undefined
			? params.delayTime : 0.0;

		this.audioDuration = this.audio.buffer.duration;
		this.duration = this.audioDuration + this.delayTime;

	}

	/**
	 * @param {Number} delta
	 * @return {AudioManager}
	 */
	control( delta ) {

		this.elapsed += delta;
		this.currentTime += delta;

		if ( this._shouldStopAudio() ) this.audio.stop();
		if ( this._shouldStartAudio() ) this.audio.play();

		return this;

	}

	// private methods

	_shouldStartAudio() {

		if ( this.audio.isPlaying ) return false;

		while ( this.currentTime >= this.duration ) {

			this.currentTime -= this.duration;

		}

		if ( this.currentTime < this.delayTime ) return false;

		// 'duration' can be bigger than 'audioDuration + delayTime' because of sync configuration
		if ( ( this.currentTime - this.delayTime ) > this.audioDuration ) return false;

		return true;

	}

	_shouldStopAudio() {

		return this.audio.isPlaying &&
			this.currentTime >= this.duration;

	}

}