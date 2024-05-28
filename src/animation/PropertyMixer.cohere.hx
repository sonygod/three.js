import js.Quaternion;

class PropertyMixer {
    public var binding:Dynamic;
    public var valueSize:Int;
    public var _mixBufferRegion:Dynamic;
    public var _mixBufferRegionAdditive:Dynamic;
    public var _setIdentity:Dynamic;
    public var _origIndex:Int;
    public var _addIndex:Int;
    public var cumulativeWeight:Float;
    public var cumulativeWeightAdditive:Float;
    public var useCount:Int;
    public var referenceCount:Int;
    public var buffer:Float64Array;
    public var _workIndex:Int;

    public function new(binding:Dynamic, typeName:String, valueSize:Int) {
        this.binding = binding;
        this.valueSize = valueSize;
        var mixFunction:Dynamic;
        var mixFunctionAdditive:Dynamic;
        var setIdentity:Dynamic;

        // buffer layout: [ incoming | accu0 | accu1 | orig | addAccu | (optional work) ]
        //
        // interpolators can use .buffer as their .result
        // the data then goes to 'incoming'
        //
        // 'accu0' and 'accu1' are used frame-interleaved for
        // the cumulative result and are compared to detect
        // changes
        //
        // 'orig' stores the original state of the property
        //
        // 'add' is used for additive cumulative results
        //
        // 'work' is optional and is only present for quaternion types. It is used
        // to store intermediate quaternion multiplication results

        switch (typeName) {
            case "quaternion":
                mixFunction = $bind(this, _slerp);
                mixFunctionAdditive = $bind(this, _slerpAdditive);
                setIdentity = $bind(this, _setAdditiveIdentityQuaternion);

                buffer = new Float64Array(valueSize * 6);
                _workIndex = 5;
                break;

            case "string":
            case "bool":
                mixFunction = $bind(this, _select);

                // Use the regular mix function and for additive on these types,
                // additive is not relevant for non-numeric types
                mixFunctionAdditive = $bind(this, _select);

                setIdentity = $bind(this, _setAdditiveIdentityOther);

                buffer = new Array<Dynamic>(valueSize * 5);
                break;

            default:
                mixFunction = $bind(this, _lerp);
                mixFunctionAdditive = $bind(this, _lerpAdditive);
                setIdentity = $bind(this, _setAdditiveIdentityNumeric);

                buffer = new Float64Array(valueSize * 5);

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

    // accumulate data in the 'incoming' region into 'accu<i>'
    public function accumulate(accuIndex:Int, weight:Float) {
        // note: happily accumulating nothing when weight = 0, the caller knows
        // the weight and shouldn't have made the call in the first place

        var buffer = this.buffer;
        var stride = this.valueSize;
        var offset = accuIndex * stride + stride;

        var currentWeight = this.cumulativeWeight;

        if (currentWeight == 0) {
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

    // accumulate data in the 'incoming' region into 'add'
    public function accumulateAdditive(weight:Float) {
        var buffer = this.buffer;
        var stride = this.valueSize;
        var offset = stride * _addIndex;

        if (this.cumulativeWeightAdditive == 0) {
            // add = identity

            _setIdentity();
        }

        // add := add + incoming * weight

        _mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
        this.cumulativeWeightAdditive += weight;
    }

    // apply the state of 'accu<i>' to the binding when accus differ
    public function apply(accuIndex:Int) {
        var stride = this.valueSize;
        var buffer = this.buffer;
        var offset = accuIndex * stride + stride;

        var weight = this.cumulativeWeight;
        var weightAdditive = this.cumulativeWeightAdditive;

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

        for (i in stride...(stride + stride)) {
            if (buffer[i] != buffer[i + stride]) {
                // value has changed -> update scene graph

                binding.setValue(buffer, offset);
                break;
            }
        }
    }

    // remember the state of the bound property and copy it to both accus
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

    // apply the state previously taken via 'saveOriginalState' to the binding
    public function restoreOriginalState() {
        var originalValueOffset = this.valueSize * 3;
        this.binding.setValue(this.buffer, originalValueOffset);
    }

    // set additive identity for numeric types
    public function _setAdditiveIdentityNumeric() {
        var startIndex = _addIndex * this.valueSize;
        var endIndex = startIndex + this.valueSize;

        for (i in startIndex...endIndex) {
            this.buffer[i] = 0;
        }
    }

    // set additive identity for quaternions
    public function _setAdditiveIdentityQuaternion() {
        _setAdditiveIdentityNumeric();
        this.buffer[_addIndex * this.valueSize + 3] = 1;
    }

    // set additive identity for other types
    public function _setAdditiveIdentityOther() {
        var startIndex = _origIndex * this.valueSize;
        var targetIndex = _addIndex * this.valueSize;

        for (i in 0...this.valueSize) {
            this.buffer[targetIndex + i] = this.buffer[startIndex + i];
        }
    }

    // mix functions

    // select function for non-numeric types
    public function _select(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        if (t >= 0.5) {
            for (i in 0...stride) {
                buffer[dstOffset + i] = buffer[srcOffset + i];
            }
        }
    }

    // slerp function for quaternions
    public function _slerp(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float) {
        js.Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
    }

    // slerpAdditive function for quaternions
    public function _slerpAdditive(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var workOffset = _workIndex * stride;

        // Store result in intermediate buffer offset
        js.Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);

        // Slerp to the intermediate result
        js.Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
    }

    // lerp function for numeric types
    public function _lerp(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        var s = 1 - t;

        for (i in 0...stride) {
            var j = dstOffset + i;

            buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
        }
    }

    // lerpAdditive function for numeric types
    public function _lerpAdditive(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
        for (i in 0...stride) {
            var j = dstOffset + i;

            buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
        }
    }
}