class Float16BufferAttribute extends BufferAttribute {

	public function new(array:Array<Float>, itemSize:Int, normalized:Bool) {
		super(new Uint16Array(array), itemSize, normalized);
		this.isFloat16BufferAttribute = true;
	}

	public function getX(index:Int):Float {
		var x = fromHalfFloat(this.array[index * this.itemSize]);
		if (this.normalized) x = denormalize(x, this.array);
		return x;
	}

	public function setX(index:Int, x:Float):Float16BufferAttribute {
		if (this.normalized) x = normalize(x, this.array);
		this.array[index * this.itemSize] = toHalfFloat(x);
		return this;
	}

	public function getY(index:Int):Float {
		var y = fromHalfFloat(this.array[index * this.itemSize + 1]);
		if (this.normalized) y = denormalize(y, this.array);
		return y;
	}

	public function setY(index:Int, y:Float):Float16BufferAttribute {
		if (this.normalized) y = normalize(y, this.array);
		this.array[index * this.itemSize + 1] = toHalfFloat(y);
		return this;
	}

	public function getZ(index:Int):Float {
		var z = fromHalfFloat(this.array[index * this.itemSize + 2]);
		if (this.normalized) z = denormalize(z, this.array);
		return z;
	}

	public function setZ(index:Int, z:Float):Float16BufferAttribute {
		if (this.normalized) z = normalize(z, this.array);
		this.array[index * this.itemSize + 2] = toHalfFloat(z);
		return this;
	}

	public function getW(index:Int):Float {
		var w = fromHalfFloat(this.array[index * this.itemSize + 3]);
		if (this.normalized) w = denormalize(w, this.array);
		return w;
	}

	public function setW(index:Int, w:Float):Float16BufferAttribute {
		if (this.normalized) w = normalize(w, this.array);
		this.array[index * this.itemSize + 3] = toHalfFloat(w);
		return this;
	}

	public function setXY(index:Int, x:Float, y:Float):Float16BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		return this;
	}

	public function setXYZ(index:Int, x:Float, y:Float, z:Float):Float16BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		this.array[index + 2] = toHalfFloat(z);
		return this;
	}

	public function setXYZW(index:Int, x:Float, y:Float, z:Float, w:Float):Float16BufferAttribute {
		index *= this.itemSize;
		if (this.normalized) {
			x = normalize(x, this.array);
			y = normalize(y, this.array);
			z = normalize(z, this.array);
			w = normalize(w, this.array);
		}
		this.array[index + 0] = toHalfFloat(x);
		this.array[index + 1] = toHalfFloat(y);
		this.array[index + 2] = toHalfFloat(z);
		this.array[index + 3] = toHalfFloat(w);
		return this;
	}
}