import js.Browser.document;
import three.math.Vector3;
import three.math.Quaternion;
import three.core.Clock;
import three.core.Object3D;
import three.audio.AudioContext;

class AudioListener extends Object3D {
    public var context:AudioContext;
    public var gain:Dynamic;
    public var filter:Dynamic;
    public var timeDelta:Float;
    private var _clock:Clock;
    private var _position:Vector3;
    private var _quaternion:Quaternion;
    private var _scale:Vector3;
    private var _orientation:Vector3;

    public function new() {
        super();

        this.type = 'AudioListener';

        this.context = AudioContext.getContext();
        this.gain = this.context.createGain();
        this.gain.connect(this.context.destination);
        this.filter = null;
        this.timeDelta = 0.0;

        this._clock = new Clock();
        this._position = new Vector3();
        this._quaternion = new Quaternion();
        this._scale = new Vector3();
        this._orientation = new Vector3();
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

    override public function updateMatrixWorld(force:Bool = false):Void {
        super.updateMatrixWorld(force);

        var listener = this.context.listener;
        var up = this.up;

        this.timeDelta = this._clock.getDelta();

        this.matrixWorld.decompose(this._position, this._quaternion, this._scale);

        this._orientation.set(0, 0, -1).applyQuaternion(this._quaternion);

        if (Reflect.hasField(listener, "positionX")) {
            var endTime = this.context.currentTime + this.timeDelta;

            listener.positionX.linearRampToValueAtTime(this._position.x, endTime);
            listener.positionY.linearRampToValueAtTime(this._position.y, endTime);
            listener.positionZ.linearRampToValueAtTime(this._position.z, endTime);
            listener.forwardX.linearRampToValueAtTime(this._orientation.x, endTime);
            listener.forwardY.linearRampToValueAtTime(this._orientation.y, endTime);
            listener.forwardZ.linearRampToValueAtTime(this._orientation.z, endTime);
            listener.upX.linearRampToValueAtTime(up.x, endTime);
            listener.upY.linearRampToValueAtTime(up.y, endTime);
            listener.upZ.linearRampToValueAtTime(up.z, endTime);
        } else {
            listener.setPosition(this._position.x, this._position.y, this._position.z);
            listener.setOrientation(this._orientation.x, this._orientation.y, this._orientation.z, up.x, up.y, up.z);
        }
    }
}