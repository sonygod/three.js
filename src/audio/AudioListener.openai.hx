import Vector3 from '../math/Vector3';
import Quaternion from '../math/Quaternion';
import Clock from '../core/Clock';
import Object3D from '../core/Object3D';
import AudioContext from './AudioContext';

class AudioListener extends Object3D {

    public context: AudioContext;
    public gain: GainNode;
    public filter: any;
    public timeDelta: number;

    private _clock: Clock;
    private _position: Vector3;
    private _quaternion: Quaternion;
    private _scale: Vector3;
    private _orientation: Vector3;

    public constructor() {

        super();

        this.type = "AudioListener";

        this.context = AudioContext.getContext();

        this.gain = this.context.createGain();
        this.gain.connect(this.context.destination);

        this.filter = null;

        this.timeDelta = 0;

        this._clock = new Clock();
        this._position = new Vector3();
        this._quaternion = new Quaternion();
        this._scale = new Vector3();
        this._orientation = new Vector3();

    }

    public getInput(): GainNode {

        return this.gain;

    }

    public removeFilter(): AudioListener {

        if (this.filter !== null) {

            this.gain.disconnect(this.filter);
            this.filter.disconnect(this.context.destination);
            this.gain.connect(this.context.destination);
            this.filter = null;

        }

        return this;

    }

    public getFilter(): any {

        return this.filter;

    }

    public setFilter(value: any): AudioListener {

        if (this.filter !== null) {

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

    public getMasterVolume(): number {

        return this.gain.gain.value;

    }

    public setMasterVolume(value: number): AudioListener {

        this.gain.gain.setTargetAtTime(value, this.context.currentTime, 0.01);

        return this;

    }

    public updateMatrixWorld(force: boolean): void {

        super.updateMatrixWorld(force);

        const listener = this.context.listener;
        const up = this.up;

        this.timeDelta = this._clock.getDelta();

        this.matrixWorld.decompose(this._position, this._quaternion, this._scale);

        this._orientation.set(0, 0, -1).applyQuaternion(this._quaternion);

        if (listener.positionX) {

            const endTime = this.context.currentTime + this.timeDelta;

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

export default AudioListener;