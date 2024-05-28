package three.animation;

import three.math.Quaternion;

class PropertyMixer {
    public var binding:Dynamic;
    public var valueSize:Int;
    public var buffer:Array<Float>;
    public var _mixBufferRegion:Dynamic->Int->Int->Float->Int->Void;
    public var _mixBufferRegionAdditive:Dynamic->Int->Int->Float->Int->Void;
    public var _setIdentity:Void->Void;
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

        var mixFunction:Dynamic->Int->Int->Float->Int->Void;
        var mixFunctionAdditive:Dynamic->Int->Int->Float->Int->Void;
        var setIdentity:Void->Void;

        switch (typeName) {
            case 'quaternion':
                mixFunction = _slerp;
                mixFunctionAdditive = _slerpAdditive;
                setIdentity = _setAdditiveIdentityQuaternion;

                buffer = new Array<Float>();
                _workIndex = 5;
                for (i in 0...valueSize * 6) buffer.push(0.0);
                break;

            case 'string', 'bool':
                mixFunction = _select;

                // Use the regular mix function and for additive on these types,
                // additive is not relevant for non-numeric types
                mixFunctionAdditive = _select;

                setIdentity = _setAdditiveIdentityOther;

                buffer = new Array();
                for (i in 0...valueSize * 5) buffer.push(null);
                break;

            default:
                mixFunction = _lerp;
                mixFunctionAdditive = _lerpAdditive;
                setIdentity = _setAdditiveIdentityNumeric;

                buffer = new Array<Float>();
                for (i in 0...valueSize * 5) buffer.push(0.0);
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
        // note: happily accumulating nothing when weight = 0, the caller knows
        // the weight and shouldn't have made the call in the first place

        var buffer = this.buffer;
        var stride = this.valueSize;
        var offset = accuIndex * stride + stride;

        var currentWeight = this.cumulativeWeight;

        if (currentWeight === 0) {
            // accuN := incoming * weight

            for (i in 0...stride) {
                buffer[offset + i] = buffer[i];
            }

            currentWeight = weight;

        } else {
            // accuN := accuN + incoming * weight

            currentWeight += weight;
            var mix = weight / currentWeight;
            _mixBufferRegion(buffer, offset, 0, mix, stride);
        }

        this.cumulativeWeight = currentWeight;
    }

    public function accumulateAdditive(weight:Float) {
        var buffer = this.buffer;
        var stride = this.valueSize;
        var offset = stride * _addIndex;

        if (this.cumulativeWeightAdditive === 0) {
            // add = identity

            _setIdentity();
        }

        // add := add + incoming * weight

        _mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
        this.cumulativeWeightAdditive += weight;
    }

    public function apply(accuIndex:Int) {
        var stride = this.valueSize;
        var buffer = this.buffer;
        var offset = accuIndex * stride + stride;

        var weight = this.cumulativeWeight;
        var weightAdditive = this.cumulativeWeightAdditive;

        var binding = this.binding;

        this.cumulativeWeight = 0;
        this.cumulativeWeightAdditive = 0;

        if (weight < 1) {
            // accuN := accuN + original * ( 1 - cumulativeWeight )

            var originalValueOffset = stride * _origIndex;

            _mixBufferRegion(buffer, offset, originalValueOffset, 1 - weight, stride);
        }

        if (weightAdditive > 0) {
            // accuN := accuN + additive accuN

            _mixBufferRegionAdditive(buffer, offset, _addIndex * stride, 1, stride);
        }

        for (i in stride...stride + stride) {
            if (buffer[i] != buffer[i + stride]) {
                // value has changed -> update scene graph

                binding.setValue(buffer, offset);
                break;
            }
        }
    }

    public function saveOriginalState() {
        var binding = this.binding;

        var buffer = this.buffer;
        var stride = this.valueSize;

        var originalValueOffset = stride * _origIndex;

        binding.getValue(buffer, originalValueOffset);

        // accu[0..1] := orig -- initially detect changes against the original
        for (i in stride...originalValueOffset) {
            buffer[i] = buffer[originalValueOffset + (i % stride)];
        }

        // Add to identity for additive
        _setIdentity();

        this.cumulativeWeight = 0;
        this.cumulativeWeightAdditive = 0;
    }

    public function restoreOriginalState() {
        var originalValueOffset = this.valueSize * 3;
        this.binding.setValue(this.buffer, originalValueOffset);
    }

    private function _setAdditiveIdentityNumeric() {
        var startIndex = _addIndex * this.valueSize;
        var endIndex = startIndex + this.valueSize;

        for (i in startIndex...endIndex) {
            buffer[i] = 0;
        }
    }

    private function _setAdditiveIdentityQuaternion() {
        _setAdditiveIdentityNumeric();
        buffer[_addIndex * this.valueSize + 3] = 1;
    }

    private function _setAdditiveIdentityOther() {
        var startIndex = _origIndex * this.valueSize;
        var targetIndex = _addIndex * this.valueSize;

        for (i in 0...this.valueSize) {
            buffer[targetIndex + i] = buffer[startIndex + i];
        }
    }

    // mix functions

    private function _select(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        if (t >= 0.5) {
            for (i in 0...stride) {
                buffer[dstOffset + i] = buffer[srcOffset + i];
            }
        }
    }

    private function _slerp(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float) {
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
    }

    private function _slerpAdditive(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var workOffset = _workIndex * stride;

        // Store result in intermediate buffer offset
        Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);

        // Slerp to the intermediate result
        Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
    }

    private function _lerp(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var s = 1 - t;

        for (i in 0...stride) {
            var j = dstOffset + i;

            buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
        }
    }

    private function _lerpAdditive(buffer:Array<Float>, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        for (i in 0...stride) {
            var j = dstOffset + i;

            buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
        }
    }
}