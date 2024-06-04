import haxe.io.Bytes;

// Hybrid radix sort from
// - https://gist.github.com/sciecode/93ed864dd77c5c8803c6a86698d68dab
// - https://github.com/mrdoob/three.js/pull/27202#issuecomment-1817640271
class RadixSort {

	static public const POWER:Int = 3;
	static public const BIT_MAX:Int = 32;
	static public const BIN_BITS:Int = 1 << POWER;
	static public const BIN_SIZE:Int = 1 << BIN_BITS;
	static public const BIN_MAX:Int = BIN_SIZE - 1;
	static public const ITERATIONS:Int = BIT_MAX / BIN_BITS;

	static public var bins:Array<Uint32Array> = new Array<Uint32Array>(ITERATIONS);
	static public var bins_buffer:Bytes = Bytes.alloc((ITERATIONS + 1) * BIN_SIZE * 4);

	static public function new() {
		var c:Int = 0;
		for (i in 0...(ITERATIONS + 1)) {
			bins[i] = new Uint32Array(bins_buffer, c, BIN_SIZE);
			c += BIN_SIZE * 4;
		}
	}

	static public function defaultGet(el:Dynamic):Int {
		return el;
	}

	static public function radixSort<T>(arr:Array<T>, opt:Dynamic):Void {
		var len = arr.length;

		var options = opt == null ? {} : opt;
		var aux = options.aux == null ? new arr.constructor(len) : options.aux;
		var get = options.get == null ? defaultGet : options.get;

		var data:Array<Array<T>> = [arr, aux];

		var compare:Function, accumulate:Function, recurse:Function;

		if (options.reversed) {
			compare = (a:Dynamic, b:Dynamic) -> a < b;
			accumulate = (bin:Uint32Array) -> {
				for (j in (BIN_SIZE - 2)...-1) {
					bin[j] += bin[j + 1];
				}
			};

			recurse = (cache:Uint32Array, depth:Int, start:Int) -> {
				var prev:Int = 0;
				for (j in BIN_MAX...-1) {
					var cur = cache[j];
					var diff = cur - prev;
					if (diff != 0) {
						if (diff > 32) {
							radixSortBlock(depth + 1, start + prev, diff);
						} else {
							insertionSortBlock(depth + 1, start + prev, diff);
						}
						prev = cur;
					}
				}
			};
		} else {
			compare = (a:Dynamic, b:Dynamic) -> a > b;
			accumulate = (bin:Uint32Array) -> {
				for (j in 1...BIN_SIZE) {
					bin[j] += bin[j - 1];
				}
			};

			recurse = (cache:Uint32Array, depth:Int, start:Int) -> {
				var prev:Int = 0;
				for (j in 0...BIN_SIZE) {
					var cur = cache[j];
					var diff = cur - prev;
					if (diff != 0) {
						if (diff > 32) {
							radixSortBlock(depth + 1, start + prev, diff);
						} else {
							insertionSortBlock(depth + 1, start + prev, diff);
						}
						prev = cur;
					}
				}
			};
		}

		var insertionSortBlock = (depth:Int, start:Int, len:Int) -> {
			var a = data[depth & 1];
			var b = data[(depth + 1) & 1];

			for (j in (start + 1)...(start + len)) {
				var p = a[j];
				var t = get(p);
				var i = j;
				while (i > 0) {
					if (compare(get(a[i - 1]), t)) {
						a[i] = a[--i];
					} else {
						break;
					}
				}
				a[i] = p;
			}

			if ((depth & 1) == 1) {
				for (i in start...(start + len)) {
					b[i] = a[i];
				}
			}
		};

		var radixSortBlock = (depth:Int, start:Int, len:Int) -> {
			var a = data[depth & 1];
			var b = data[(depth + 1) & 1];

			var shift = (3 - depth) << POWER;
			var end = start + len;

			var cache = bins[depth];
			var bin = bins[depth + 1];

			bin.fill(0);

			for (j in start...end) {
				bin[(get(a[j]) >> shift) & BIN_MAX]++;
			}

			accumulate(bin);

			cache.set(bin);

			for (j in (end - 1)...start) {
				b[start + --bin[(get(a[j]) >> shift) & BIN_MAX]] = a[j];
			}

			if (depth == ITERATIONS - 1) {
				return;
			}

			recurse(cache, depth, start);
		};

		radixSortBlock(0, 0, len);
	}
}

// Example usage:
var arr:Array<Int> = [10, 5, 8, 2, 1, 9, 3, 7, 6, 4];
RadixSort.radixSort(arr, {reversed: true});
trace(arr); // [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]