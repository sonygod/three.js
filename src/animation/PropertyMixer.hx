package three.animation;

import three.math.Quaternion;

class PropertyMixer {
    public var binding:Dynamic;
    public var valueSize:Int;
    public var buffer:Array<Float>;
    public var _mixBufferRegion:Dynamic;
    public var _mixBufferRegionAdditive:Dynamic;
    public var _setIdentity:Dynamic;
    public var _origIndex:Int;
    public var _addIndex:Int;
    public var cumulativeWeight:Float;
    public var cumulativeWeightAdditive:Float;
    public var useCount:Int;
    public var referenceCount:Int;
    public var _workIndex:Int;

    public function new(binding:Dynamic, typeName:String, valueSize:Int) {
        this.binding = binding;
        this.valueSize = valueSize;

        var mixFunction:Dynamic;
        var mixFunctionAdditive:Dynamic;
        var setIdentity:Dynamic;

        switch (typeName) {
            case 'quaternion':
                mixFunction = _slerp;
                mixFunctionAdditive = _slerpAdditive;
                setIdentity = _setAdditiveIdentityQuaternion;
                buffer = new Array<Float>(valueSize * 6);
                _workIndex = 5;
            case 'string', 'bool':
                mixFunction = _select;
                mixFunctionAdditive = _select;
                setIdentity = _setAdditiveIdentityOther;
                buffer = new Array<Float>(valueSize * 5);
            default:
                mixFunction = _lerp;
                mixFunctionAdditive = _lerpAdditive;
                setIdentity = _setAdditiveIdentityNumeric;
                buffer = new Array<Float>(valueSize * 5);
        }

        _mixBufferRegion = mixFunction;
        _mixBufferRegionAdditive = mixFunctionAdditive;
        _setIdentity = setIdentity;
        _origIndex = 3;
        _addIndex = 4;

        cumulativeWeight = 0;
        cumulativeWeightAdditive = 0;

        useCount = 0;
        referenceCount = 0;
    }

    public function accumulate(accuIndex:Int, weight:Float) {
        var buffer:Array<Float> = this.buffer;
        var stride:Int = valueSize;
        var offset:Int = accuIndex * stride + stride;

        var currentWeight:Float = cumulativeWeight;

        if (currentWeight == 0) {
            for (i in 0...stride) {
                buffer[offset + i] = buffer[i];
            }
            currentWeight = weight;
        } else {
            currentWeight += weight;
            var mix:Float = weight / currentWeight;
            _mixBufferRegion(buffer, offset, 0, mix, stride);
        }

        cumulativeWeight = currentWeight;
    }

    public function accumulateAdditive(weight:Float) {
        var buffer:Array<Float> = this.buffer;
        var stride:Int = valueSize;
        var offset:Int = stride * _addIndex;

        if (cumulativeWeightAdditive == 0) {
            _setIdentity();
        }

        _mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
        cumulativeWeightAdditive += weight;
    }

    public function apply(accuIndex:Int) {
        var stride:Int = valueSize;
        var buffer:Array<Float> = this.buffer;
        var offset:Int = accuIndex * stride + stride;

        var weight:Float = cumulativeWeight;
        var weightAdditive:Float = cumulativeWeightAdditive;

        cumulativeWeight = 0;
        cumulativeWeightAdditive = 0;

        if (weight < 1) {
            var originalValueOffset:Int = stride * _origIndex;

            _mixBufferRegion(buffer, offset, originalValueOffset, 1 - weight, stride);
        }

        if (weightAdditive > 0) {
            _mixBufferRegionAdditive(buffer, offset, _addIndex * stride, 1, stride);
        }

        for (i in stride...stride * 2) {
            if (buffer[i] != buffer[i + stride]) {
                binding.setValue(buffer, offset);
                break;
            }
        }
    }

    public function saveOriginalState() {
        var binding:Dynamic = this.binding;
        var buffer:Array<Float> = this.buffer;
        var stride:Int = valueSize;

        var originalValueOffset:Int = stride * _origIndex;

        binding.getValue(buffer, originalValueOffset);

        for (i in stride...originalValueOffset) {
            buffer[i] = buffer[originalValueOffset + (i % stride)];
        }

        _setIdentity();

        cumulativeWeight = 0;
        cumulativeWeightAdditive = 0;
    }

    public function restoreOriginalState() {
        var originalValueOffset:Int = valueSize * 3;
        binding.setValue(buffer, originalValueOffset);
    }

    public function _setAdditiveIdentityNumeric() {
        var startIndex:Int = _addIndex * valueSize;
        var endIndex:Int = startIndex + valueSize;

        for (i in startIndex...endIndex) {
            buffer[i] = 0;
        }
    }

    public function _setAdditiveIdentityQuaternion() {
        _setAdditiveIdentityNumeric();
        buffer[_addIndex * valueSize + 3] = 1;
    }

    public function _setAdditiveIdentityOther() {
        var startIndex:Int = _origIndex * valueSize;
        var targetIndex:Int = _addIndex * valueSize;

        for (i in 0...valueSize) {
            buffer[targetIndex + i] = buffer[startIndex + i];
        }
    }

    public function _select(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        if (t >= 0.5) {
            for (i in 0...stride) {
                buffer[dstOffset + i] = buffer[srcOffset + i];
            }
        }
    }

    public function _slerp(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float) {
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
    }

    public function _slerpAdditive(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var workOffset:Int = _workIndex * stride;

        Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
    }

    public function _lerp(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var s:Float = 1 - t;

        for (i in 0...stride) {
            var j:Int = dstOffset + i;
            buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
        }
    }

    public function _lerpAdditive(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        for (i in 0...stride) {
            var j:Int = dstOffset + i;
            buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
        }
    }
}