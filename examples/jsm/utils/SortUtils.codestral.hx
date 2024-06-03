package three.jsm.utils;

import js.html.ArrayBuffer;
import js.html.ArrayBufferView;
import js.html.Uint32Array;

class SortUtils {
    private static final int POWER = 3;
    private static final int BIT_MAX = 32;
    private static final int BIN_BITS = 1 << POWER;
    private static final int BIN_SIZE = 1 << BIN_BITS;
    private static final int BIN_MAX = BIN_SIZE - 1;
    private static final int ITERATIONS = BIT_MAX / BIN_BITS;

    private static final Array<Uint32Array> bins = new Array<Uint32Array>();
    private static final ArrayBuffer bins_buffer = new ArrayBuffer((ITERATIONS + 1) * BIN_SIZE * 4);

    static {
        var c:Int = 0;
        for (var i:Int = 0; i < ITERATIONS + 1; i++) {
            bins[i] = new Uint32Array(bins_buffer, c, BIN_SIZE);
            c += BIN_SIZE * 4;
        }
    }

    private static function defaultGet(el:Dynamic):Float {
        return el as Float;
    }

    public static function radixSort(arr:Array<Dynamic>, opt:Dynamic = null):Void {
        var len:Int = arr.length;

        var options = opt == null ? {} : opt;
        var aux:Array<Dynamic> = (options.hasOwnProperty('aux') ? options.aux : new Array<Dynamic>(len));
        var get = options.hasOwnProperty('get') ? options.get : defaultGet;

        var data:Array<Array<Dynamic>> = [arr, aux];

        var compare:Dynamic;
        var accumulate:Dynamic;
        var recurse:Dynamic;

        if (options.hasOwnProperty('reversed')) {
            compare = function(a:Dynamic, b:Dynamic):Bool {
                return a < b;
            };
            accumulate = function(bin:Uint32Array):Void {
                for (var j:Int = BIN_SIZE - 2; j >= 0; j--) {
                    bin[j] += bin[j + 1];
                }
            };
            recurse = function(cache:Uint32Array, depth:Int, start:Int):Void {
                var prev:Int = 0;
                for (var j:Int = BIN_MAX; j >= 0; j--) {
                    var cur:Int = cache[j], diff:Int = cur - prev;
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
            compare = function(a:Dynamic, b:Dynamic):Bool {
                return a > b;
            };
            accumulate = function(bin:Uint32Array):Void {
                for (var j:Int = 1; j < BIN_SIZE; j++) {
                    bin[j] += bin[j - 1];
                }
            };
            recurse = function(cache:Uint32Array, depth:Int, start:Int):Void {
                var prev:Int = 0;
                for (var j:Int = 0; j < BIN_SIZE; j++) {
                    var cur:Int = cache[j], diff:Int = cur - prev;
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

        function insertionSortBlock(depth:Int, start:Int, len:Int):Void {
            var a:Array<Dynamic> = data[depth & 1];
            var b:Array<Dynamic> = data[(depth + 1) & 1];

            for (var j:Int = start + 1; j < start + len; j++) {
                var p:Dynamic = a[j], t:Float = get(p);
                var i:Int = j;
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
                for (var i:Int = start; i < start + len; i++) {
                    b[i] = a[i];
                }
            }
        }

        function radixSortBlock(depth:Int, start:Int, len:Int):Void {
            var a:Array<Dynamic> = data[depth & 1];
            var b:Array<Dynamic> = data[(depth + 1) & 1];

            var shift:Int = (3 - depth) << POWER;
            var end:Int = start + len;

            var cache:Uint32Array = bins[depth];
            var bin:Uint32Array = bins[depth + 1];

            bin.fill(0);

            for (var j:Int = start; j < end; j++) {
                bin[(get(a[j]) >> shift) & BIN_MAX]++;
            }

            accumulate(bin);

            cache.set(bin);

            for (var j:Int = end - 1; j >= start; j--) {
                b[start + --bin[(get(a[j]) >> shift) & BIN_MAX]] = a[j];
            }

            if (depth == ITERATIONS - 1) return;

            recurse(cache, depth, start);
        }

        radixSortBlock(0, 0, len);
    }
}