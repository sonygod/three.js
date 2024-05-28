package three.audio;

import three.math.Vector3;
import three.math.Quaternion;
import three.audio.Audio;

class PositionalAudio extends Audio {
    private var _position:Vector3 = new Vector3();
    private var _quaternion:Quaternion = new Quaternion();
    private var _scale:Vector3 = new Vector3();
    private var _orientation:Vector3 = new Vector3();

    public function new(listener:Dynamic) {
        super(listener);

        panner = context.createPanner();
        panner.panningModel = 'HRTF';
        panner.connect(gain);
    }

    override public function connect():Void {
        super.connect();

        panner.connect(gain);
    }

    override public function disconnect():Void {
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

    override public function updateMatrixWorld(force:Bool):Void {
        super.updateMatrixWorld(force);

        if (hasPlaybackControl && !isPlaying) return;

        matrixWorld.decompose(_position, _quaternion, _scale);

        _orientation.set(0, 0, 1).applyQuaternion(_quaternion);

        var panner:Dynamic = this.panner;

        if (panner.positionX != null) {
            // code path for Chrome and Firefox (see #14393)
            var endTime:Float = context.currentTime + listener.timeDelta;

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

// Export the class
#else
export PositionalAudio;
#end