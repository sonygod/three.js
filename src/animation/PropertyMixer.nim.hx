import Math.Quaternion;

class PropertyMixer {

	public var binding:Dynamic;
	public var valueSize:Int;

	private var mixFunction:Dynamic;
	private var mixFunctionAdditive:Dynamic;
	private var setIdentity:Dynamic;

	private var buffer:Dynamic;
	private var _workIndex:Int;
	private var _origIndex:Int;
	private var _addIndex:Int;

	private var _mixBufferRegion:Dynamic;
	private var _mixBufferRegionAdditive:Dynamic;
	private var _setIdentity:Dynamic;

	private var cumulativeWeight:Float;
	private var cumulativeWeightAdditive:Float;

	private var useCount:Int;
	private var referenceCount:Int;

	public function new(binding:Dynamic, typeName:String, valueSize:Int) {

		this.binding = binding;
		this.valueSize = valueSize;

		switch (typeName) {

			case 'quaternion':
				mixFunction = this._slerp;
				mixFunctionAdditive = this._slerpAdditive;
				setIdentity = this._setAdditiveIdentityQuaternion;

				this.buffer = new Float64Array(valueSize * 6);
				this._workIndex = 5;
				break;

			case 'string':
			case 'bool':
				mixFunction = this._select;

				// Use the regular mix function and for additive on these types,
				// additive is not relevant for non-numeric types
				mixFunctionAdditive = this._select;

				setIdentity = this._setAdditiveIdentityOther;

				this.buffer = new Array<Dynamic>(valueSize * 5);
				break;

			default:
				mixFunction = this._lerp;
				mixFunctionAdditive = this._lerpAdditive;
				setIdentity = this._setAdditiveIdentityNumeric;

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

	public function accumulate(accuIndex:Int, weight:Float) {

		const buffer = this.buffer,
			stride = this.valueSize,
			offset = accuIndex * stride + stride;

		let currentWeight = this.cumulativeWeight;

		if (currentWeight === 0) {

			// accuN := incoming * weight

			for (i in 0...stride) {

				buffer[offset + i] = buffer[i];

			}

			currentWeight = weight;

		} else {

			// accuN := accuN + incoming * weight

			currentWeight += weight;
			const mix = weight / currentWeight;
			this._mixBufferRegion(buffer, offset, 0, mix, stride);

		}

		this.cumulativeWeight = currentWeight;

	}

	public function accumulateAdditive(weight:Float) {

		const buffer = this.buffer,
			stride = this.valueSize,
			offset = stride * this._addIndex;

		if (this.cumulativeWeightAdditive === 0) {

			// add = identity

			this._setIdentity();

		}

		// add := add + incoming * weight

		this._mixBufferRegionAdditive(buffer, offset, 0, weight, stride);
		this.cumulativeWeightAdditive += weight;

	}

	public function apply(accuIndex:Int) {

		const stride = this.valueSize,
			buffer = this.buffer,
			offset = accuIndex * stride + stride,

			weight = this.cumulativeWeight,
			weightAdditive = this.cumulativeWeightAdditive,

			binding = this.binding;

		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;

		if (weight < 1) {

			// accuN := accuN + original * ( 1 - cumulativeWeight )

			const originalValueOffset = stride * this._origIndex;

			this._mixBufferRegion(
				buffer, offset, originalValueOffset, 1 - weight, stride);

		}

		if (weightAdditive > 0) {

			// accuN := accuN + additive accuN

			this._mixBufferRegionAdditive(buffer, offset, this._addIndex * stride, 1, stride);

		}

		for (i in stride...stride + stride) {

			if (buffer[i] !== buffer[i + stride]) {

				// value has changed -> update scene graph

				binding.setValue(buffer, offset);
				break;

			}

		}

	}

	public function saveOriginalState() {

		const binding = this.binding;

		const buffer = this.buffer,
			stride = this.valueSize,

			originalValueOffset = stride * this._origIndex;

		binding.getValue(buffer, originalValueOffset);

		// accu[0..1] := orig -- initially detect changes against the original
		for (i in 0...stride) {

			buffer[i + stride] = buffer[originalValueOffset + (i % stride)];

		}

		// Add to identity for additive
		this._setIdentity();

		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;

	}

	public function restoreOriginalState() {

		const originalValueOffset = this.valueSize * 3;
		this.binding.setValue(this.buffer, originalValueOffset);

	}

	private function _setAdditiveIdentityNumeric() {

		const startIndex = this._addIndex * this.valueSize;
		const endIndex = startIndex + this.valueSize;

		for (i in startIndex...endIndex) {

			this.buffer[i] = 0;

		}

	}

	private function _setAdditiveIdentityQuaternion() {

		this._setAdditiveIdentityNumeric();
		this.buffer[this._addIndex * this.valueSize + 3] = 1;

	}

	private function _setAdditiveIdentityOther() {

		const startIndex = this._origIndex * this.valueSize;
		const targetIndex = this._addIndex * this.valueSize;

		for (i in 0...this.valueSize) {

			this.buffer[targetIndex + i] = this.buffer[startIndex + i];

		}

	}

	// mix functions

	private function _select(buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {

		if (t >= 0.5) {

			for (i in 0...stride) {

				buffer[dstOffset + i] = buffer[srcOffset + i];

			}

		}

	}

	private function _slerp(buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float) {

		Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t);

	}

	private function _slerpAdditive(buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {

		const workOffset = this._workIndex * stride;

		// Store result in intermediate buffer offset
		Quaternion.multiplyQuaternionsFlat(buffer, workOffset, buffer, dstOffset, buffer, srcOffset);

		// Slerp to the intermediate result
		Quaternion.slerpFlat(buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t);

	}

	private function _lerp(buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {

		const s = 1 - t;

		for (i in 0...stride) {

			const j = dstOffset + i;

			buffer[j] = buffer[j] * s + buffer[srcOffset + i] * t;

		}

	}

	private function _lerpAdditive(buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int) {

		for (i in 0...stride) {

			const j = dstOffset + i;

			buffer[j] = buffer[j] + buffer[srcOffset + i] * t;

		}

	}

}