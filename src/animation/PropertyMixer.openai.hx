import js.three.math.Quaternion;

class PropertyMixer {

	var binding:Dynamic;
	var valueSize:Int;
	var _mixBufferRegion:Dynamic;
	var _mixBufferRegionAdditive:Dynamic;
	var _setIdentity:Dynamic;
	var _origIndex:Int;
	var _addIndex:Int;
	var cumulativeWeight:Float;
	var cumulativeWeightAdditive:Float;
	var useCount:Int;
	var referenceCount:Int;
	var buffer:Dynamic;
	var _workIndex:Int;

	public function new( binding:Dynamic, typeName:String, valueSize:Int ) {

		this.binding = binding;
		this.valueSize = valueSize;

		var mixFunction:Dynamic;
		var mixFunctionAdditive:Dynamic;
		var setIdentity:Dynamic;

		switch ( typeName ) {

			case 'quaternion':
				mixFunction = _slerp;
				mixFunctionAdditive = _slerpAdditive;
				setIdentity = _setAdditiveIdentityQuaternion;

				this.buffer = new Float64Array( valueSize * 6 );
				this._workIndex = 5;
				break;

			case 'string':
			case 'bool':
				mixFunction = _select;
				mixFunctionAdditive = _select;
				setIdentity = _setAdditiveIdentityOther;

				this.buffer = new JsArray<Float>( valueSize * 5 );
				break;

			default:
				mixFunction = _lerp;
				mixFunctionAdditive = _lerpAdditive;
				setIdentity = _setAdditiveIdentityNumeric;

				this.buffer = new Float64Array( valueSize * 5 );

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

	public function accumulate( accuIndex:Int, weight:Float ) {

		var buffer = this.buffer;
		var stride = this.valueSize;
		var offset = accuIndex * stride + stride;
		var currentWeight = this.cumulativeWeight;

		if ( currentWeight == 0 ) {

			for ( i in 0...stride ) {

				buffer[ offset + i ] = buffer[ i ];

			}

			currentWeight = weight;

		} else {

			currentWeight += weight;
			var mix = weight / currentWeight;
			this._mixBufferRegion( buffer, offset, 0, mix, stride );

		}

		this.cumulativeWeight = currentWeight;

	}

	public function accumulateAdditive( weight:Float ) {

		var buffer = this.buffer;
		var stride = this.valueSize;
		var offset = stride * this._addIndex;

		if ( this.cumulativeWeightAdditive == 0 ) {

			this._setIdentity();

		}

		this._mixBufferRegionAdditive( buffer, offset, 0, weight, stride );
		this.cumulativeWeightAdditive += weight;

	}

	public function apply( accuIndex:Int ) {

		var stride = this.valueSize;
		var buffer = this.buffer;
		var offset = accuIndex * stride + stride;
		var weight = this.cumulativeWeight;
		var weightAdditive = this.cumulativeWeightAdditive;
		var binding = this.binding;
		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;

		if ( weight < 1 ) {

			var originalValueOffset = stride * this._origIndex;
			this._mixBufferRegion( buffer, offset, originalValueOffset, 1 - weight, stride );

		}

		if ( weightAdditive > 0 ) {

			this._mixBufferRegionAdditive( buffer, offset, this._addIndex * stride, 1, stride );

		}

		for ( i in stride...stride + stride ) {

			if ( buffer[ i ] != buffer[ i + stride ] ) {

				binding.setValue( buffer, offset );
				break;

			}

		}

	}

	public function saveOriginalState() {

		var binding = this.binding;
		var buffer = this.buffer;
		var stride = this.valueSize;
		var originalValueOffset = stride * this._origIndex;

		binding.getValue( buffer, originalValueOffset );

		for ( i in stride...originalValueOffset ) {

			buffer[ i ] = buffer[ originalValueOffset + ( i % stride ) ];

		}

		this._setIdentity();
		this.cumulativeWeight = 0;
		this.cumulativeWeightAdditive = 0;

	}

	public function restoreOriginalState() {

		var originalValueOffset = this.valueSize * 3;
		this.binding.setValue( this.buffer, originalValueOffset );

	}

	private function _setAdditiveIdentityNumeric() {

		var startIndex = this._addIndex * this.valueSize;
		var endIndex = startIndex + this.valueSize;

		for ( i in startIndex...endIndex ) {

			this.buffer[ i ] = 0;

		}

	}

	private function _setAdditiveIdentityQuaternion() {

		this._setAdditiveIdentityNumeric();
		this.buffer[ this._addIndex * this.valueSize + 3 ] = 1;

	}

	private function _setAdditiveIdentityOther() {

		var startIndex = this._origIndex * this.valueSize;
		var targetIndex = this._addIndex * this.valueSize;

		for ( i in 0...this.valueSize ) {

			this.buffer[ targetIndex + i ] = this.buffer[ startIndex + i ];

		}

	}

	private function _select( buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int ) {

		if ( t >= 0.5 ) {

			for ( i in 0...stride ) {

				buffer[ dstOffset + i ] = buffer[ srcOffset + i ];

			}

		}

	}

	private function _slerp( buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float ) {

		Quaternion.slerpFlat( buffer, dstOffset, buffer, dstOffset, buffer, srcOffset, t );

	}

	private function _slerpAdditive( buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int ) {

		var workOffset = this._workIndex * stride;
		Quaternion.multiplyQuaternionsFlat( buffer, workOffset, buffer, dstOffset, buffer, srcOffset );
		Quaternion.slerpFlat( buffer, dstOffset, buffer, dstOffset, buffer, workOffset, t );

	}

	private function _lerp( buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int ) {

		var s = 1 - t;

		for ( i in 0...stride ) {

			var j = dstOffset + i;
			buffer[ j ] = buffer[ j ] * s + buffer[ srcOffset + i ] * t;

		}

	}

	private function _lerpAdditive( buffer:Dynamic, dstOffset:Int, srcOffset:Int, t:Float, stride:Int ) {

		for ( i in 0...stride ) {

			var j = dstOffset + i;
			buffer[ j ] = buffer[ j ] + buffer[ srcOffset + i ] * t;

		}

	}

}