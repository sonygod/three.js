import three.math.Vector3;
import three.math.Quaternion;
import three.core.Clock;
import three.core.Object3D;
import three.audio.AudioContext;

class AudioListener extends Object3D {
    public var context:Dynamic;
    public var gain:Dynamic;
    public var filter:Dynamic;
    public var timeDelta:Float;
    
    private var _clock:Clock;

    private static var _position:Vector3 = new Vector3();
    private static var _quaternion:Quaternion = new Quaternion();
    private static var _scale:Vector3 = new Vector3();
    private static var _orientation:Vector3 = new Vector3();

    public function new() {
        super();
        this.type = 'AudioListener';
        this.context = AudioContext.getContext();
        this.gain = this.context.createGain();
        this.gain.connect(this.context.destination);
        this.filter = null;
        this.timeDelta = 0;
        this._clock = new Clock();
    }

    public function getInput():Dynamic {
        return this.gain;
    }

    public function removeFilter():AudioListener {
        if (this.filter != null) {
            this.gain.disconnect(this.filter);
            this.filter.disconnect(this.context.destination);
            this.gain.connect(this.context.destination);
            this.filter = null;
        }
        return this;
    }

    public function getFilter():Dynamic {
        return this.filter;
    }

    public function setFilter(value:Dynamic):AudioListener {
        if (this.filter != null) {
            this.gain.disconnect(this.filter);
            this.filter.disconnect(this.context.destination);
        } else {
            this.gain.disconnect(this.context.destination);
        }
        this.filter = value;
        this.gain.connect(this.filter);
        this.filter.connect(this.context.destination);
        return this;
    }

    public function getMasterVolume():Float {
        return this.gain.gain.value;
    }

    public function setMasterVolume(value:Float):AudioListener {
        this.gain.gain.setTargetAtTime(value, this.context.currentTime, 0.01);
        return this;
    }

    public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);
        var listener = this.context.listener;
        var up = this.up;

        this.timeDelta = this._clock.getDelta();
        this.matrixWorld.decompose(_position, _quaternion, _scale);
        _orientation.set(0, 0, -1).applyQuaternion(_quaternion);

        if (Reflect.hasField(listener, "positionX")) {
            var endTime = this.context.currentTime + this.timeDelta;
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