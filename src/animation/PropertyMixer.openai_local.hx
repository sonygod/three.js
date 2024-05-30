import js.html.Float64Array;

class PropertyMixer {

	var binding: Dynamic;
	var valueSize: Int;
	var buffer: Float64Array;
	var _workIndex: Int;
	var _origIndex: Int;
	var _addIndex: Int;
	var cumulativeWeight: Float;
	var cumulativeWeightAdditive: Float;
	var useCount: Int;
	var referenceCount: Int;

	public function new(binding: Dynamic, typeName: String, valueSize: Int) {
		this.binding = binding;
		this.valueSize = valueSize;

		var mixFunction: Float -> Void;
		var mixFunctionAdditive: Float -> Void;
		var setIdentity: Void -> Void;

		switch (typeName) {
			case "quaternion":
				mixFunction = _slerp;
				mixFunctionAdditive = _slerpAdditive;
				setIdentity = _setAdditiveIdentityQuaternion;
				this.buffer = new Float64Array(valueSize * 6);
				this._workIndex = 5;
			case "string", "bool":
				mixFunction = _select;
				mixFunctionAdditive = _select;
				setIdentity = _setAdditiveIdentityOther;
				this.buffer = new Array<Float>(valueSize * 5);
			default:
				mixFunction = _lerp;
				mixFunctionAdditive = _lerpAdditive;
				setIdentity = _setAdditiveIdentityNumeric;
				this.buffer = new Float64Array(valueSize * 5);
		}

		this._mixBufferRegion = mixFunction;
		this._mixBufferRegionAdditive = mixFunctionAdditive;
		this._setIdentity = setIdentity;
		this._origIndex = 3;
		this._addIndex = 4;
		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;
		this.useCount = 0;
		this.referenceCount = 0;
	}

	public function accumulate(accuIndex: Int, weight: Float): Void {
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

	public function accumulateAdditive(weight: Float): Void {
		var buffer = this.buffer;
		var stride = this.valueSize;
		var offset = stride * this._addIndex;

		if (this.cumulativeWeightAdditive == 0) {
			this._setIdentity();
		}

		this._mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
		this.cumulativeWeightAdditive += weight;
	}

	public function apply(accuIndex: Int): Void {
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

		for (i in stride...stride + stride) {
			if (buffer[i] != buffer[i + stride]) {
				binding.setValue(buffer, offset);
				break;
			}
		}
	}

	public function saveOriginalState(): Void {
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

	public function restoreOriginalState(): Void {
		var originalValueOffset = this.valueSize * 3;
		this.binding.setValue(this.buffer, originalValueOffset);
	}

	function _setAdditiveIdentityNumeric(): Void {
		var startIndex = this._addIndex * this.valueSize;
		var endIndex = startIndex + this.valueSize;

		for (i in startIndex...endIndex) {
			this.buffer[i] = 0;
		}
	}

	function _setAdditiveIdentityQuaternion(): Void {
		this._setAdditiveIdentityNumeric();
		this.buffer[this._addIndex * this.valueSize + 3] = 1;
	}

	function _setAdditiveIdentityOther(): Void {
		var startIndex = this._origIndex * this.valueSize;
		var targetIndex = this._addIndex * this.valueSize;

		for (i in 0...this.valueSize) {
			this.buffer[targetIndex + i] = this.buffer[startIndex + i];
		}
	}

	function _select(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int): Void {
		if (t >= 0.5) {
			for (i in 0...stride) {
				buffer[dstOffset + i] = buffer[srcOffset + i];
			}
		}
	}

	function _slerp(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float): Void {
		// Implementation for Quaternion.slerpFlat() method is missing
	}

	function _slerpAdditive(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int): Void {
		// Implementation for Quaternion.multiplyQuaternionsFlat() method is missing
		// Implementation for Quaternion.slerpFlat() method is missing
	}

	function _lerp(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int): Void {
		var s = 1 - t;
		for (i in 0...stride) {
			var j = dstOffset + i;
			buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;
		}
	}

	function _lerpAdditive(buffer: Float64Array, dstOffset: Int, srcOffset: Int, t: Float, stride: Int): Void {
		for (i in 0...stride) {
			var j = dstOffset + i;
			buffer[j] = buffer[j] + buffer[srcOffset + i] * t;
		}
	}

}