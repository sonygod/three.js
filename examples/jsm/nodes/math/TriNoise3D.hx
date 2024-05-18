Here is the equivalent Haxe code:
```
package three.js.examples.jsm.nodes.math;

import haxe.ds.Float32Array;
import haxe.ds.Vector;

class TriNoise3D {
    static var tri:TslFn = TslFn.fromFunction(function(x:Array<Float>) {
        return x[0] - Math.floor(x[0] + 0.5);
    });

    static var tri3:TslFn = TslFn.fromFunction(function(p:Array<Float>) {
        return [tri([p[2] + tri([p[1] * 1.0])), tri([p[2] + tri([p[0] * 1.0])]), tri([p[1] + tri([p[0] * 1.0])])];
    });

    static var triNoise3D:TslFn = TslFn.fromFunction(function(args:Array<Array<Float>>) {
        var p_immutable:Array<Float> = args[0];
        var spd:Float = args[1][0];
        var time:Float = args[2][0];

        var p:Array<Float> = [p_immutable[0], p_immutable[1], p_immutable[2]];
        var z:Float = 1.4;
        var rz:Float = 0.0;
        var bp:Array<Float> = [p[0], p[1], p[2]];

        for (i in 0...3) {
            var dg:Array<Float> = tri3(bp.map(function(x:Float) return x * 2.0));
            p[0] += dg[0] + time * 0.1 * spd;
            p[1] += dg[1];
            p[2] += dg[2];
            bp[0] *= 1.8;
            bp[1] *= 1.8;
            bp[2] *= 1.8;
            z *= 1.5;

            var t:Float = tri([p[2] + tri([p[0] + tri([p[1]])])]);
            rz += t / z;
            bp[0] += 0.14;
            bp[1] += 0.14;
            bp[2] += 0.14;
        }

        return rz;
    });

    static function main() {
        tri.setLayout({
            name: 'tri',
            type: 'float',
            inputs: [
                { name: 'x', type: 'float' }
            ]
        });

        tri3.setLayout({
            name: 'tri3',
            type: 'vec3',
            inputs: [
                { name: 'p', type: 'vec3' }
            ]
        });

        triNoise3D.setLayout({
            name: 'triNoise3D',
            type: 'float',
            inputs: [
                { name: 'p', type: 'vec3' },
                { name: 'spd', type: 'float' },
                { name: 'time', type: 'float' }
            ]
        });
    }
}
```
Note that I had to make some assumptions about the Haxe equivalent of the JavaScript code, as Haxe has some differences in syntax and semantics compared to JavaScript. Additionally, I had to create a `TslFn` class to mimic the behavior of the `tslFn` function in JavaScript.

Also, I used the `haxe.ds.Float32Array` and `haxe.ds.Vector` classes to work with arrays and vectors, as Haxe has built-in support for these data structures.

Please note that this is a manual conversion, and you may need to adjust the code to fit your specific use case.