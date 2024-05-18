class AudioListener extends Object3D {

	constructor() {

		super();

		this.type = 'AudioListener';

		this.context = AudioContext.getContext();

		this.gain = this.context.createGain();
		this.gain.connect( this.context.destination );

		this.filter = null;

		this.timeDelta = 0;

		// private

		this._clock = new Clock();

	}

	getInput() {

		return this.gain;

	}

	removeFilter() {

		if ( this.filter !== null ) {

			this.gain.disconnect( this.filter );
			this.filter.disconnect( this.context.destination );
			this.gain.connect( this.context.destination );
			this.filter = null;

		}

		return this;

	}

	getFilter() {

		return this.filter;

	}

	setFilter( value ) {

		if ( this.filter !== null ) {

			this.gain.disconnect( this.filter );
			this.filter.disconnect( this.context.destination );

		} else {

			this.gain.disconnect( this.context.destination );

		}

		this.filter = value;
		this.gain.connect( this.filter );
		this.filter.connect( this.context.destination );

		return this;

	}

	getMasterVolume() {

		return this.gain.gain.value;

	}

	setMasterVolume( value ) {

		this.gain.gain.setTargetAtTime( value, this.context.currentTime, 0.01 );

		return this;

	}

	updateMatrixWorld( force ) {

		super.updateMatrixWorld( force );

		const listener = this.context.listener;
		const up = this.up;

		this.timeDelta = this._clock.getDelta();

		this.matrixWorld.decompose( _position$1, _quaternion$1, _scale$1 );

		_orientation$1.set( 0, 0, - 1 ).applyQuaternion( _quaternion$1 );

		if ( listener.positionX ) {

			// code path for Chrome (see #14393)

			const endTime = this.context.currentTime + this.timeDelta;

			listener.positionX.linearRampToValueAtTime( _position$1.x, endTime );
			listener.positionY.linearRampToValueAtTime( _position$1.y, endTime );
			listener.positionZ.linearRampToValueAtTime( _position$1.z, endTime );
			listener.forwardX.linearRampToValueAtTime( _orientation$1.x, endTime );
			listener.forwardY.linearRampToValueAtTime( _orientation$1.y, endTime );
			listener.forwardZ.linearRampToValueAtTime( _orientation$1.z, endTime );
			listener.upX.linearRampToValueAtTime( up.x, endTime );
			listener.upY.linearRampToValueAtTime( up.y, endTime );
			listener.upZ.linearRampToValueAtTime( up.z, endTime );

		} else {

			listener.setPosition( _position$1.x, _position$1.y, _position$1.z );
			listener.setOrientation( _orientation$1.x, _orientation$1.y, _orientation$1.z, up.x, up.y, up.z );

		}

	}

}