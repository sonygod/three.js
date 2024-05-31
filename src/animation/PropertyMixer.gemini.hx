import three.math.Quaternion;

class PropertyMixer {

	public var binding:Dynamic;
	public var valueSize:Int;
	public var buffer:Float64Array;
	public var _mixBufferRegion:Dynamic;
	public var _mixBufferRegionAdditive:Dynamic;
	public var _setIdentity:Dynamic;
	public var _origIndex:Int;
	public var _addIndex:Int;
	public var _workIndex:Int;

	public var cumulativeWeight:Float = 0;
	public var cumulativeWeightAdditive:Float = 0;

	public var useCount:Int = 0;
	public var referenceCount:Int = 0;

	public function new(binding:Dynamic, typeName:String, valueSize:Int) {
		this.binding = binding;
		this.valueSize = valueSize;

		this._origIndex = 3;
		this._addIndex = 4;

		switch (typeName) {
			case 'quaternion':
				this._mixBufferRegion = this._slerp;
				this._mixBufferRegionAdditive = this._slerpAdditive;
				this._setIdentity = this._setAdditiveIdentityQuaternion;
				this.buffer = new Float64Array(valueSize * 6);
				this._workIndex = 5;
				break;
			case 'string':
			case 'bool':
				this._mixBufferRegion = this._select;
				this._mixBufferRegionAdditive = this._select;
				this._setIdentity = this._setAdditiveIdentityOther;
				this.buffer = new Array(valueSize * 5);
				break;
			default:
				this._mixBufferRegion = this._lerp;
				this._mixBufferRegionAdditive = this._lerpAdditive;
				this._setIdentity = this._setAdditiveIdentityNumeric;
				this.buffer = new Float64Array(valueSize * 5);
		}
	}

	public function accumulate(accuIndex:Int, weight:Float) {
		var buffer = this.buffer;
		var stride = this.valueSize;
		var offset = accuIndex * stride + stride;
		var currentWeight = this.cumulativeWeight;

		if (currentWeight == 0) {
			for (i in 0...stride) {
				buffer[offset + i] = buffer[i];
			}
			currentWeight = weight;
		} else {
			currentWeight += weight;
			var mix = weight / currentWeight;
			this._mixBufferRegion(buffer, offset, 0, mix, stride);
		}

		this.cumulativeWeight = currentWeight;
	}

	public function accumulateAdditive(weight:Float) {
		var buffer = this.buffer;
		var stride = this.valueSize;
		var offset = stride * this._addIndex;

		if (this.cumulativeWeightAdditive == 0) {
			this._setIdentity();
		}

		this._mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
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
			var originalValueOffset = stride * this._origIndex;
			this._mixBufferRegion(buffer, offset, originalValueOffset, 1 - weight, stride);
		}

		if (weightAdditive > 0) {
			this._mixBufferRegionAdditive(buffer, offset, this._addIndex * stride, 1, stride);
		}

		for (i in stride...(stride + stride)) {
			if (buffer[i] != buffer[i + stride]) {
				binding.setValue(buffer, offset);
				break;
			}
		}
	}

	public function saveOriginalState() {
		var binding = this.binding;
		var buffer = this.buffer;
		var stride = this.valueSize;
		var originalValueOffset = stride * this._origIndex;

		binding.getValue(buffer, originalValueOffset);

		for (i in stride...originalValueOffset) {
			buffer[i] = buffer[originalValueOffset + (i % stride)];
		}

		this._setIdentity();

		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;
	}

	public function restoreOriginalState() {
		var originalValueOffset = this.valueSize * 3;
		this.binding.setValue(this.buffer, originalValueOffset);
	}

	public function _setAdditiveIdentityNumeric() {
		var startIndex = this._addIndex * this.valueSize;
		var endIndex = startIndex + this.valueSize;

		for (i in startIndex...endIndex) {
			this.buffer[i] = 0;
		}
	}

	public function _setAdditiveIdentityQuaternion() {
		this._setAdditiveIdentityNumeric();
		this.buffer[this._addIndex * this.valueSize + 3] = 1;
	}

	public function _setAdditiveIdentityOther() {
		var startIndex = this._origIndex * this.valueSize;
		var targetIndex = this._addIndex * this.valueSize;

		for (i in 0...this.valueSize) {
			this.buffer[targetIndex + i] = this.buffer[startIndex + i];
		}
	}

	// mix functions

	public function _select(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
		if (t >= 0.5) {
			for (i in 0...stride) {
				buffer[dstOffset + i] = buffer[srcOffset + i];
			}
		}
	}

	public function _slerp(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float) {
		Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);
	}

	public function _slerpAdditive(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
		var workOffset = this._workIndex * stride;
		Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);
		Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);
	}

	public function _lerp(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
		var s = 1 - t;
		for (i in 0...stride) {
			var j = dstOffset + i;
			buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
		}
	}

	public function _lerpAdditive(buffer:Float64Array, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {
		for (i in 0...stride) {
			var j = dstOffset + i;
			buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
		}
	}
}