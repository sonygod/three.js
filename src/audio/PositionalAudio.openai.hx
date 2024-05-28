package three.audio;

import three.math.Vector3;
import three.math.Quaternion;
import three.audio.Audio;

class PositionalAudio extends Audio {
	var panner:Dynamic;

	public function new(listener:Dynamic) {
		super(listener);

		panner = context.createPanner();
		panner.panningModel = 'HRTF';
		panner.connect(gain);
	}

	override public function connect() {
		super.connect();
		panner.connect(gain);
	}

	override public function disconnect() {
		super.disconnect();
		panner.disconnect(gain);
	}

	public function getOutput() {
		return panner;
	}

	public function getRefDistance() {
		return panner.refDistance;
	}

	public function setRefDistance(value:Float) {
		panner.refDistance = value;
		return this;
	}

	public function getRolloffFactor() {
		return panner.rolloffFactor;
	}

	public function setRolloffFactor(value:Float) {
		panner.rolloffFactor = value;
		return this;
	}

	public function getDistanceModel() {
		return panner.distanceModel;
	}

	public function setDistanceModel(value:String) {
		panner.distanceModel = value;
		return this;
	}

	public function getMaxDistance() {
		return panner.maxDistance;
	}

	public function setMaxDistance(value:Float) {
		panner.maxDistance = value;
		return this;
	}

	public function setDirectionalCone(coneInnerAngle:Float, coneOuterAngle:Float, coneOuterGain:Float) {
		panner.coneInnerAngle = coneInnerAngle;
		panner.coneOuterAngle = coneOuterAngle;
		panner.coneOuterGain = coneOuterGain;
		return this;
	}

	override public function updateMatrixWorld(force:Bool = false) {
		super.updateMatrixWorld(force);

		if (hasPlaybackControl && !isPlaying) return;

		matrixWorld.decompose(_position, _quaternion, _scale);

		_orientation.set(0, 0, 1).applyQuaternion(_quaternion);

		var panner = this.panner;

		if (Reflect.hasField(panner, 'positionX')) {
			// code path for Chrome and Firefox (see #14393)
			var endTime = context.currentTime + listener.timeDelta;

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

	static var _position:Vector3 = new Vector3();
	static var _quaternion:Quaternion = new Quaternion();
	static var _scale:Vector3 = new Vector3();
	static var _orientation:Vector3 = new Vector3();
}