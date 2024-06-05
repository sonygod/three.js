import haxe.io.Bytes;
import three.core.BufferAttribute;
import three.core.DynamicDrawUsage;
import three.extras.DataUtils;

class Int8BufferAttribute extends BufferAttribute {
	public function new( array : Int8Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Uint8BufferAttribute extends BufferAttribute {
	public function new( array : Uint8Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Uint8ClampedBufferAttribute extends BufferAttribute {
	public function new( array : Uint8ClampedArray, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Int16BufferAttribute extends BufferAttribute {
	public function new( array : Int16Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Uint16BufferAttribute extends BufferAttribute {
	public function new( array : Uint16Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Int32BufferAttribute extends BufferAttribute {
	public function new( array : Int32Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Uint32BufferAttribute extends BufferAttribute {
	public function new( array : Uint32Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Float16BufferAttribute extends BufferAttribute {
	public function new( array : Uint16Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class Float32BufferAttribute extends BufferAttribute {
	public function new( array : Float32Array, itemSize : Int, normalized : Bool = false ) {
		super(array, itemSize, normalized);
	}
}

class BufferAttribute {
	public var array : Array<Float>;
	public var itemSize : Int;
	public var count : Int;
	public var normalized : Bool;
	public var usage : Int;
	public var updateRanges : Array<DynamicDrawUsage>;
	public var version : Int;
	public var onUploadCallback : DynamicDrawUsage;
	public var needsUpdate : Bool;

	public function new( array : Array<Float>, itemSize : Int, normalized : Bool = false ) {
		this.array = array;
		this.itemSize = itemSize;
		this.count = array.length / itemSize;
		this.normalized = normalized;
		this.usage = DynamicDrawUsage.STATIC_DRAW;
		this.updateRanges = [];
		this.version = 0;
		this.onUploadCallback = null;
		this.needsUpdate = false;
	}

	public function isBufferAttribute() : Bool {
		return true;
	}

	public function setUsage( value : Int ) : Void {
		this.usage = value;
	}

	public function copy( source : BufferAttribute ) : BufferAttribute {
		this.array = source.array.copy();
		this.itemSize = source.itemSize;
		this.count = source.count;
		this.normalized = source.normalized;
		this.usage = source.usage;
		this.needsUpdate = source.needsUpdate;
		return this;
	}

	public function copyAt( index : Int, source : BufferAttribute, offset : Int ) : Void {
		var length = source.itemSize;
		for ( i in 0...length ) {
			this.array[index + i] = source.array[offset + i];
		}
	}

	public function copyArray( array : Array<Float> ) : Void {
		this.array = array.copy();
	}

	public function set( value : Array<Float>, offset : Int = 0 ) : Void {
		var i = offset;
		for ( v in value ) {
			this.array[i++] = v;
		}
	}

	public function setX( index : Int, value : Float ) : Void {
		this.array[index * this.itemSize] = value;
	}

	public function setY( index : Int, value : Float ) : Void {
		this.array[index * this.itemSize + 1] = value;
	}

	public function setZ( index : Int, value : Float ) : Void {
		this.array[index * this.itemSize + 2] = value;
	}

	public function setW( index : Int, value : Float ) : Void {
		this.array[index * this.itemSize + 3] = value;
	}

	public function getX( index : Int ) : Float {
		return this.array[index * this.itemSize];
	}

	public function getY( index : Int ) : Float {
		return this.array[index * this.itemSize + 1];
	}

	public function getZ( index : Int ) : Float {
		return this.array[index * this.itemSize + 2];
	}

	public function getW( index : Int ) : Float {
		return this.array[index * this.itemSize + 3];
	}

	public function setXY( index : Int, x : Float, y : Float ) : Void {
		this.array[index * this.itemSize] = x;
		this.array[index * this.itemSize + 1] = y;
	}

	public function setXYZ( index : Int, x : Float, y : Float, z : Float ) : Void {
		this.array[index * this.itemSize] = x;
		this.array[index * this.itemSize + 1] = y;
		this.array[index * this.itemSize + 2] = z;
	}

	public function setXYZW( index : Int, x : Float, y : Float, z : Float, w : Float ) : Void {
		this.array[index * this.itemSize] = x;
		this.array[index * this.itemSize + 1] = y;
		this.array[index * this.itemSize + 2] = z;
		this.array[index * this.itemSize + 3] = w;
	}

	public function onUpload( value : DynamicDrawUsage ) : Void {
		this.onUploadCallback = value;
	}

	public function clone() : BufferAttribute {
		return new BufferAttribute(this.array.copy(), this.itemSize, this.normalized);
	}

	public function toJSON() : DynamicDrawUsage {
		return {
			itemSize : this.itemSize,
			type : "Float32Array",
			array : this.array,
			normalized : this.normalized,
			name : null,
			usage : this.usage,
		};
	}

	public function addUpdateRange( offset : Int, count : Int ) : Void {
		this.updateRanges.push({offset : offset, count : count});
	}
}

class Main {
	static function main() {
		var array = new Float32Array([1, 2, 3, 4, 5, 6]);
		var attribute = new BufferAttribute(array, 3);
		trace(attribute.count); // 2
		trace(attribute.array); // [1, 2, 3, 4, 5, 6]
	}
}