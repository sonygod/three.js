class SortUtils {
    static var POWER:Int = 3;
    static var BIT_MAX:Int = 32;
    static var BIN_BITS:Int = (1 << POWER);
    static var BIN_SIZE:Int = (1 << BIN_BITS);
    static var BIN_MAX:Int = BIN_SIZE - 1;
    static var ITERATIONS:Int = BIT_MAX / BIN_BITS;

    static var bins:Array<Uint32Array> = new Array();
    static var bins_buffer:ArrayBuffer<Int> = new ArrayBuffer((ITERATIONS + 1) * BIN_SIZE * 4);

    static var c:Int = 0;
    for (i in 0...(ITERATIONS + 1)) {
        bins[i] = new Uint32Array(bins_buffer, c, BIN_SIZE);
        c += BIN_SIZE * 4;
    }

    static function defaultGet(el:Dynamic):Dynamic {
        return el;
    }

    static function radixSort(arr:Array<Dynamic>, opt:Dynamic):Void {
        var len:Int = arr.length;

        var options:Dynamic = opt || {};
        var aux:Array<Dynamic> = options.aux || new arr.constructor(len);
        var get:Dynamic = options.get || defaultGet;

        var data:Array<Array<Dynamic>> = [arr, aux];

        var compare:Dynamic;
        var accumulate:Dynamic;
        var recurse:Dynamic;

        if (options.reversed) {
            compare = (a:Dynamic, b:Dynamic) -> a < b;
            accumulate = (bin:Uint32Array) -> {
                for (j in BIN_SIZE - 2...0)
                    bin[j] += bin[j + 1];
            };

            recurse = (cache:Uint32Array, depth:Int, start:Int) -> {
                var prev:Int = 0;
                for (j in BIN_MAX...0) {
                    var cur:Int = cache[j];
                    var diff:Int = cur - prev;
                    if (diff != 0) {
                        if (diff > 32)
                            radixSortBlock(depth + 1, start + prev, diff);
                        else
                            insertionSortBlock(depth + 1, start + prev, diff);
                        prev = cur;
                    }
                }
            };
        } else {
            compare = (a:Dynamic, b:Dynamic) -> a > b;
            accumulate = (bin:Uint32Array) -> {
                for (j in 1...BIN_SIZE)
                    bin[j] += bin[j - 1];
            };

            recurse = (cache:Uint32Array, depth:Int, start:Int) -> {
                var prev:Int = 0;
                for (j in 0...BIN_SIZE) {
                    var cur:Int = cache[j];
                    var diff:Int = cur - prev;
                    if (diff != 0) {
                        if (diff > 32)
                            radixSortBlock(depth + 1, start + prev, diff);
                        else
                            insertionSortBlock(depth + 1, start + prev, diff);
                        prev = cur;
                    }
                }
            };
        }

        var insertionSortBlock = (depth:Int, start:Int, len:Int) -> {
            var a:Array<Dynamic> = data[depth & 1];
            var b:Array<Dynamic> = data[(depth + 1) & 1];

            for (j in start + 1...start + len) {
                var p:Dynamic = a[j];
                var t:Dynamic = get(p);
                var i:Int = j;
                while (i > 0) {
                    if (compare(get(a[i - 1]), t))
                        a[i] = a[--i];
                    else
                        break;
                }
                a[i] = p;
            }

            if ((depth & 1) == 1) {
                for (i in start...start + len)
                    b[i] = a[i];
            }
        };

        var radixSortBlock = (depth:Int, start:Int, len:Int) -> {
            var a:Array<Dynamic> = data[depth & 1];
            var b:Array<Dynamic> = data[(depth + 1) & 1];

            var shift:Int = (3 - depth) << POWER;
            var end:Int = start + len;

            var cache:Uint32Array = bins[depth];
            var bin:Uint32Array = bins[depth + 1];

            bin.fill(0);

            for (j in start...end)
                bin[(get(a[j]) >> shift) & BIN_MAX]++;

            accumulate(bin);

            cache.set(bin);

            for (j in end - 1...start)
                b[start + --bin[(get(a[j]) >> shift) & BIN_MAX]] = a[j];

            if (depth == ITERATIONS - 1) return;

            recurse(cache, depth, start);
        };

        radixSortBlock(0, 0, len);
    }
}