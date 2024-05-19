import js.three.math.Vector3;
import js.three.math.Quaternion;
import js.three.audio.Audio;

class PositionalAudio extends Audio {
    var _position = new Vector3();
    var _quaternion = new Quaternion();
    var _scale = new Vector3();
    var _orientation = new Vector3();

    public function new(listener: Listener) {
        super(listener);

        panner = context.createPanner();
        panner.panningModel = "HRTF";
        panner.connect(gain);
    }

    public function connect(): Void {
        super.connect();

        panner.connect(gain);
    }

    public function disconnect(): Void {
        super.disconnect();

        panner.disconnect(gain);
    }

    public override function getOutput(): dynamic {
        return panner;
    }

    public function getRefDistance(): Float {
        return panner.refDistance;
    }

    public function setRefDistance(value: Float): PositionalAudio {
        panner.refDistance = value;

        return this;
    }

    public function getRolloffFactor(): Float {
        return panner.rolloffFactor;
    }

    public function setRolloffFactor(value: Float): PositionalAudio {
        panner.rolloffFactor = value;

        return this;
    }

    public function getDistanceModel(): String {
        return panner.distanceModel;
    }

    public function setDistanceModel(value: String): PositionalAudio {
        panner.distanceModel = value;

        return this;
    }

    public function getMaxDistance(): Float {
        return panner.maxDistance;
    }

    public function setMaxDistance(value: Float): PositionalAudio {
        panner.maxDistance = value;

        return this;
    }

    public function setDirectionalCone(coneInnerAngle: Float, coneOuterAngle: Float, coneOuterGain: Float): PositionalAudio {
        panner.coneInnerAngle = coneInnerAngle;
        panner.coneOuterAngle = coneOuterAngle;
        panner.coneOuterGain = coneOuterGain;

        return this;
    }

    public override function updateMatrixWorld(force: Bool): Void {
        super.updateMatrixWorld(force);

        if (hasPlaybackControl && !isPlaying)
            return;

        matrixWorld.decompose(_position, _quaternion, _scale);

        _orientation.set(0, 0, 1).applyQuaternion(_quaternion);

        var panner = this.panner;

        if (panner.positionX) {
            // code path for Chrome and Firefox (see #14393)

            var endTime = context.currentTime + listener.timeDelta;

            panner.positionX.linearRampToValueAtTime(_position.x, endTime);
            panner.positionY.linearRampToValueAtTime(_position.y, endTime);
            panner.positionZ.linearRampToValueAtTime(_position.z, endTime);
            panner.orientationX.linearRampToValueAtTime(_orientation.x, endTime);
            panner.orientationY.linearRampToValueAtTime(_orientation.y, endTime);
            panner.orientationZ.linearRampToValueAtTime(_orientation.z, endTime);
        }
        else {
            panner.setPosition(_position.x, _position.y, _position.z);
            panner.setOrientation(_orientation.x, _orientation.y, _orientation.z);
        }
    }
}