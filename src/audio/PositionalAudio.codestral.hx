import js.Browser.document;
import three.math.Vector3;
import three.math.Quaternion;
import three.audio.Audio;

class PositionalAudio extends Audio {

    var _position:Vector3;
    var _quaternion:Quaternion;
    var _scale:Vector3;
    var _orientation:Vector3;

    var panner:Dynamic;

    public function new(listener:Dynamic) {
        super(listener);

        _position = new Vector3();
        _quaternion = new Quaternion();
        _scale = new Vector3();
        _orientation = new Vector3();

        panner = context.createPanner();
        panner.panningModel = 'HRTF';
        panner.connect(gain);
    }

    override function connect() {
        super.connect();
        panner.connect(gain);
    }

    override function disconnect() {
        super.disconnect();
        panner.disconnect(gain);
    }

    public function getOutput():Dynamic {
        return panner;
    }

    public function getRefDistance():Float {
        return panner.refDistance;
    }

    public function setRefDistance(value:Float):PositionalAudio {
        panner.refDistance = value;
        return this;
    }

    public function getRolloffFactor():Float {
        return panner.rolloffFactor;
    }

    public function setRolloffFactor(value:Float):PositionalAudio {
        panner.rolloffFactor = value;
        return this;
    }

    public function getDistanceModel():String {
        return panner.distanceModel;
    }

    public function setDistanceModel(value:String):PositionalAudio {
        panner.distanceModel = value;
        return this;
    }

    public function getMaxDistance():Float {
        return panner.maxDistance;
    }

    public function setMaxDistance(value:Float):PositionalAudio {
        panner.maxDistance = value;
        return this;
    }

    public function setDirectionalCone(coneInnerAngle:Float, coneOuterAngle:Float, coneOuterGain:Float):PositionalAudio {
        panner.coneInnerAngle = coneInnerAngle;
        panner.coneOuterAngle = coneOuterAngle;
        panner.coneOuterGain = coneOuterGain;
        return this;
    }

    override function updateMatrixWorld(force:Bool) {
        super.updateMatrixWorld(force);

        if (hasPlaybackControl && !isPlaying) return;

        matrixWorld.decompose(_position, _quaternion, _scale);

        _orientation.set(0, 0, 1).applyQuaternion(_quaternion);

        if (panner.positionX != null) {
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
}