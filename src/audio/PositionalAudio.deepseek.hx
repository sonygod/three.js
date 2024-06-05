import three.math.Vector3;
import three.math.Quaternion;
import three.audio.Audio;

class PositionalAudio extends Audio {

	var _position:Vector3 = new Vector3();
	var _quaternion:Quaternion = new Quaternion();
	var _scale:Vector3 = new Vector3();
	var _orientation:Vector3 = new Vector3();

	public function new(listener:Dynamic) {
		super(listener);
		this.panner = this.context.createPanner();
		this.panner.panningModel = 'HRTF';
		this.panner.connect(this.gain);
	}

	public function connect():Void {
		super.connect();
		this.panner.connect(this.gain);
	}

	public function disconnect():Void {
		super.disconnect();
		this.panner.disconnect(this.gain);
	}

	public function getOutput():Dynamic {
		return this.panner;
	}

	public function getRefDistance():Float {
		return this.panner.refDistance;
	}

	public function setRefDistance(value:Float):PositionalAudio {
		this.panner.refDistance = value;
		return this;
	}

	public function getRolloffFactor():Float {
		return this.panner.rolloffFactor;
	}

	public function setRolloffFactor(value:Float):PositionalAudio {
		this.panner.rolloffFactor = value;
		return this;
	}

	public function getDistanceModel():String {
		return this.panner.distanceModel;
	}

	public function setDistanceModel(value:String):PositionalAudio {
		this.panner.distanceModel = value;
		return this;
	}

	public function getMaxDistance():Float {
		return this.panner.maxDistance;
	}

	public function setMaxDistance(value:Float):PositionalAudio {
		this.panner.maxDistance = value;
		return this;
	}

	public function setDirectionalCone(coneInnerAngle:Float, coneOuterAngle:Float, coneOuterGain:Float):PositionalAudio {
		this.panner.coneInnerAngle = coneInnerAngle;
		this.panner.coneOuterAngle = coneOuterAngle;
		this.panner.coneOuterGain = coneOuterGain;
		return this;
	}

	public function updateMatrixWorld(force:Bool):Void {
		super.updateMatrixWorld(force);
		if (this.hasPlaybackControl && !this.isPlaying) return;
		this.matrixWorld.decompose(_position, _quaternion, _scale);
		_orientation.set(0, 0, 1).applyQuaternion(_quaternion);
		var panner = this.panner;
		if (panner.positionX) {
			var endTime = this.context.currentTime + this.listener.timeDelta;
			panner.positionX.linearRampToValueAtTime(_position.x, endTime);
			panner.positionY.linearRampToValueAtTime(_position.y, endTime);
			panner.positionZ.linearRampToValueAtTime(_position.z, endTime);
			panner.orientationX.linearRampToValueAtTime(_orientation.x, endTime);
			panner.orientationY.linearRampToValueAtTime(_orientation.y, endTime);
			panner.orientationZ.linearRampToValueAtTime(_orientation.z, endTime);
		} else {
			panner.setPosition(_position.x, _position.y, _position.z);
			panner.setOrientation(_orientation.x, _orientation.y, _orientation.z);
		}
	}
}