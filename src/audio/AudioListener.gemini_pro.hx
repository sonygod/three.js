import three.math.Vector3;
import three.math.Quaternion;
import three.core.Clock;
import three.core.Object3D;
import three.audio.AudioContext;

class AudioListener extends Object3D {

	public var type:String = "AudioListener";
	public var context:AudioContext;
	public var gain:Dynamic;
	public var filter:Dynamic;
	public var timeDelta:Float;
	private var _clock:Clock;

	public function new() {
		super();
		context = AudioContext.getContext();
		gain = context.createGain();
		gain.connect(context.destination);
		filter = null;
		timeDelta = 0;
		_clock = new Clock();
	}

	public function getInput():Dynamic {
		return gain;
	}

	public function removeFilter():AudioListener {
		if (filter != null) {
			gain.disconnect(filter);
			filter.disconnect(context.destination);
			gain.connect(context.destination);
			filter = null;
		}
		return this;
	}

	public function getFilter():Dynamic {
		return filter;
	}

	public function setFilter(value:Dynamic):AudioListener {
		if (filter != null) {
			gain.disconnect(filter);
			filter.disconnect(context.destination);
		} else {
			gain.disconnect(context.destination);
		}
		filter = value;
		gain.connect(filter);
		filter.connect(context.destination);
		return this;
	}

	public function getMasterVolume():Float {
		return gain.gain.value;
	}

	public function setMasterVolume(value:Float):AudioListener {
		gain.gain.setTargetAtTime(value, context.currentTime, 0.01);
		return this;
	}

	override public function updateMatrixWorld(force:Bool = false):Void {
		super.updateMatrixWorld(force);
		var listener = context.listener;
		var up = up;
		timeDelta = _clock.getDelta();
		var _position = new Vector3();
		var _quaternion = new Quaternion();
		var _scale = new Vector3();
		var _orientation = new Vector3();
		matrixWorld.decompose(_position, _quaternion, _scale);
		_orientation.set(0, 0, -1).applyQuaternion(_quaternion);
		if (listener.positionX != null) {
			var endTime = context.currentTime + timeDelta;
			listener.positionX.linearRampToValueAtTime(_position.x, endTime);
			listener.positionY.linearRampToValueAtTime(_position.y, endTime);
			listener.positionZ.linearRampToValueAtTime(_position.z, endTime);
			listener.forwardX.linearRampToValueAtTime(_orientation.x, endTime);
			listener.forwardY.linearRampToValueAtTime(_orientation.y, endTime);
			listener.forwardZ.linearRampToValueAtTime(_orientation.z, endTime);
			listener.upX.linearRampToValueAtTime(up.x, endTime);
			listener.upY.linearRampToValueAtTime(up.y, endTime);
			listener.upZ.linearRampToValueAtTime(up.z, endTime);
		} else {
			listener.setPosition(_position.x, _position.y, _position.z);
			listener.setOrientation(_orientation.x, _orientation.y, _orientation.z, up.x, up.y, up.z);
		}
	}

}