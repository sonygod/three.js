import three.math.Quaternion;

class PropertyMixer {
    var binding: Dynamic;
    var valueSize: Int;

    var buffer: Float64Array | Array<Dynamic>;
    var _workIndex: Int;
    var _origIndex: Int;
    var _addIndex: Int;

    var cumulativeWeight: Float;
    var cumulativeWeightAdditive: Float;

    var useCount: Int;
    var referenceCount: Int;

    var _mixBufferRegion: (Float64Array | Array<Dynamic>, Int, Int, Float, Int) -> Void;
    var _mixBufferRegionAdditive: (Float64Array | Array<Dynamic>, Int, Int, Float, Int) -> Void;
    var _setIdentity: Void -> Void;

    function new(binding: Dynamic, typeName: String, valueSize: Int) {
        this.binding = binding;
        this.valueSize = valueSize;
        this.cumulativeWeight = 0.;
        this.cumulativeWeightAdditive = 0.;
        this.useCount = 0;
        this.referenceCount = 0;

        switch(typeName) {
            case "quaternion":
                this._mixBufferRegion = this._slerp;
                this._mixBufferRegionAdditive = this._slerpAdditive;
                this._setIdentity = this._setAdditiveIdentityQuaternion;
                this.buffer = new Float64Array(valueSize * 6);
                this._workIndex = 5;
                break;

            case "string":
            case "bool":
                this._mixBufferRegion = this._select;
                this._mixBufferRegionAdditive = this._select;
                this._setIdentity = this._setAdditiveIdentityOther;
                this.buffer = new Array<Dynamic>(valueSize * 5);
                break;

            default:
                this._mixBufferRegion = this._lerp;
                this._mixBufferRegionAdditive = this._lerpAdditive;
                this._setIdentity = this._setAdditiveIdentityNumeric;
                this.buffer = new Float64Array(valueSize * 5);
        }

        this._origIndex = 3;
        this._addIndex = 4;
    }

    function accumulate(accuIndex: Int, weight: Float) {
        var offset = accuIndex * this.valueSize + this.valueSize;
        var currentWeight = this.cumulativeWeight;

        if (currentWeight == 0.) {
            for (var i = 0; i < this.valueSize; ++ i) {
                this.buffer[offset + i] = this.buffer[i];
            }

            currentWeight = weight;
        } else {
            currentWeight += weight;
            var mix = weight / currentWeight;
            this._mixBufferRegion(this.buffer, offset, 0, mix, this.valueSize);
        }

        this.cumulativeWeight = currentWeight;
    }

    function accumulateAdditive(weight: Float) {
        var offset = this.valueSize * this._addIndex;

        if (this.cumulativeWeightAdditive == 0.) {
            this._setIdentity();
        }

        this._mixBufferRegionAdditive(this.buffer, offset, 0, weight, this.valueSize);
        this.cumulativeWeightAdditive += weight;
    }

    function apply(accuIndex: Int) {
        var offset = accuIndex * this.valueSize + this.valueSize;
        var weight = this.cumulativeWeight;
        var weightAdditive = this.cumulativeWeightAdditive;

        this.cumulativeWeight = 0.;
        this.cumulativeWeightAdditive = 0.;

        if (weight < 1.) {
            var originalValueOffset = this.valueSize * this._origIndex;
            this._mixBufferRegion(this.buffer, offset, originalValueOffset, 1. - weight, this.valueSize);
        }

        if (weightAdditive > 0.) {
            this._mixBufferRegionAdditive(this.buffer, offset, this._addIndex * this.valueSize, 1., this.valueSize);
        }

        for (var i = this.valueSize; i < this.valueSize + this.valueSize; ++ i) {
            if (this.buffer[i] != this.buffer[i + this.valueSize]) {
                this.binding.setValue(this.buffer, offset);
                break;
            }
        }
    }

    function saveOriginalState() {
        var originalValueOffset = this.valueSize * this._origIndex;
        this.binding.getValue(this.buffer, originalValueOffset);

        for (var i = this.valueSize; i < originalValueOffset; ++ i) {
            this.buffer[i] = this.buffer[originalValueOffset + (i % this.valueSize)];
        }

        this._setIdentity();
        this.cumulativeWeight = 0.;
        this.cumulativeWeightAdditive = 0.;
    }

    function restoreOriginalState() {
        var originalValueOffset = this.valueSize * 3;
        this.binding.setValue(this.buffer, originalValueOffset);
    }

    function _setAdditiveIdentityNumeric() {
        var startIndex = this._addIndex * this.valueSize;
        var endIndex = startIndex + this.valueSize;

        for (var i = startIndex; i < endIndex; i ++) {
            this.buffer[i] = 0.;
        }
    }

    function _setAdditiveIdentityQuaternion() {
        this._setAdditiveIdentityNumeric();
        this.buffer[this._addIndex * this.valueSize + 3] = 1.;
    }

    function _setAdditiveIdentityOther() {
        var startIndex = this._origIndex * this.valueSize;
        var targetIndex = this._addIndex * this.valueSize;

        for (var i = 0; i < this.valueSize; i ++) {
            this.buffer[targetIndex + i] = this.buffer[startIndex + i];
        }
    }

    function _select(buffer: Float64Array | Array<Dynamic>, dstOffset: Int, srcOffset: Int, t: Float, stride: Int) {
        if (t >= 0.5) {
            for (var i = 0; i < stride; ++ i) {
                buffer[dstOffset + i] = buffer[srcOffset + i];
            }
        }
    }

    function _slerp(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float) {
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
    }

    function _slerpAdditive(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int) {
        var workOffset = this._workIndex * stride;
        Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
    }

    function _lerp(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int) {
        var s = 1. - t;

        for (var i = 0; i < stride; ++ i) {
            var j = dstOffset + i;
            buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
        }
    }

    function _lerpAdditive(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int) {
        for (var i = 0; i < stride; ++ i) {
            var j = dstOffset + i;
            buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
        }
    }
}