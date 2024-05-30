import haxe.io.Bytes;

class RadixSort {
    static inline function get(el:Dynamic):Int {
        return el as Int;
    }

    static function radixSortBlock(depth:Int, start:Int, len:Int, data:Array<Int>, bins:Array<Int>, cache:Array<Int>, recurse:Dynamic -> Int -> Int -> Void) {
        const a = data[depth & 1];
        const b = data[(depth + 1) & 1];

        const shift = (3 - depth) << POWER;
        const end = start + len;

        const bin = bins[depth + 1];
        const cache = cache[depth] as Array<Int>;

        bin.fill(0);

        for (let j = start; j < end; j++) {
            bin[(get(a[j]) >> shift) & BIN_MAX]++;
        }

        var i = 0;
        while (i < BIN_SIZE) {
            cache[i] = bin[i];
            i++;
        }

        accumulate(bin);

        for (let j = end - 1; j >= start; j--) {
            b[start + --bin[(get(a[j]) >> shift) & BIN_MAX]] = a[j];
        }

        if (depth == ITERATIONS - 1) {
            return;
        }

        recurse(cache, depth, start);
    }

    static function insertionSortBlock(depth:Int, start:Int, len:Int, data:Array<Int>) {
        const a = data[depth & 1];
        const b = data[(depth + 1) & 1];

        for (let j = start + 1; j < start + len; j++) {
            const p = a[j];
            let t = get(p);
            let i = j;

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
            for (let i = start; i < start + len; i++) {
                b[i] = a[i];
            }
        }
    }

    static function radixSort(arr:Array<Int>, opt:Dynamic = null) {
        const len = arr.length;

        const options = (if (opt != null) opt else {});
        const aux = (if (options.aux != null) options.aux else new Array<Int>(len));
        const get = (if (options.get != null) options.get else RadixSort.get);

        const data = [arr, aux];

        var compare:Dynamic -> Dynamic -> Bool;
        var accumulate:Array<Int> -> Void;
        var recurse:Dynamic -> Int -> Int -> Void;

        if (options.reversed != null) {
            compare = (a, b) -> a < b;
            accumulate = (bin) -> {
                for (let j = BIN_SIZE - 2; j >= 0; j--) {
                    bin[j] += bin[j + 1];
                }
            };

            recurse = (cache, depth, start) -> {
                var prev = 0;
                for (let j = BIN_MAX; j >= 0; j--) {
                    const cur = cache[j];
                    if (cur != prev) {
                        if (cur - prev > 32) {
                            RadixSort.radixSortBlock(depth + 1, start + prev, cur - prev, data, bins, cache, recurse);
                        } else {
                            RadixSort.insertionSortBlock(depth + 1, start + prev, cur - prev, data);
                        }
                        prev = cur;
                    }
                }
            };
        } else {
            compare = (a, b) -> a > b;
            accumulate = (bin) -> {
                for (let j = 1; j < BIN_SIZE; j++) {
                    bin[j] += bin[j - 1];
                }
            };

            recurse = (cache, depth, start) -> {
                var prev = 0;
                for (let j = 0; j < BIN_SIZE; j++) {
                    const cur = cache[j];
                    if (cur != prev) {
                        if (cur - prev > 32) {
                            RadixSort.radixSortBlock(depth + 1, start + prev, cur - prev, data, bins, cache, recurse);
                        } else {
                            RadixSort.insertionSortBlock(depth + 1, start + prev, cur - prev, data);
                        }
                        prev = cur;
                    }
                }
            };
        }

        RadixSort.radixSortBlock(0, 0, len, data, bins, bins, recurse);
    }

    static var POWER:Int = 3;
    static var BIT_MAX:Int = 32;
    static var BIN_BITS:Int = 1 << POWER;
    static var BIN_SIZE:Int = 1 << BIN_BITS;
    static var BIN_MAX:Int = BIN_SIZE - 1;
    static var ITERATIONS:Int = BIT_MAX / BIN_BITS;

    static var bins:Array<Int> = [];
    static var binsBuffer:Bytes = Bytes.alloc((ITERATIONS + 1) * BIN_SIZE * 4);

    static function new() {
        var c = 0;
        for (let i = 0; i < ITERATIONS + 1; i++) {
            bins.push(new Array<Int>(BIN_SIZE));
            c += BIN_SIZE * 4;
        }

        for (let i = 0; i < ITERATIONS; i++) {
            bins[i].buffer = binsBuffer.slice(c - BIN_SIZE * 4, c);
            c -= BIN_SIZE * 4;
        }
    }
}

class Test {
    static function main() {
        var arr = [1, 3, 5, 2, 4, 6];
        RadixSort.radixSort(arr);
        trace(arr); // Output: [1, 2, 3, 4, 5, 6]
    }
}