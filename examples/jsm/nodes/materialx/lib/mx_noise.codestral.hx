// Three.js Transpiler
// https://raw.githubusercontent.com/AcademySoftwareFoundation/MaterialX/main/libraries/stdlib/genglsl/lib/mx_noise.glsl

import js.Browser.window;
import js.lib.Function;

class MXNoise {

    static function mx_select(b: Bool, t: Float, f: Float): Float {
        if (b) {
            return t;
        } else {
            return f;
        }
    }

    static function mx_negate_if(val: Float, b: Bool): Float {
        if (b) {
            return -val;
        } else {
            return val;
        }
    }

    static function mx_floor(x: Float): Int {
        return Math.floor(x);
    }

    static function mx_floorfrac(x: Float, i: Int): Float {
        i = Math.floor(x);
        return x - i;
    }

    static function mx_bilerp_0(v0: Float, v1: Float, v2: Float, v3: Float, s: Float, t: Float): Float {
        return (1.0 - t) * ((1.0 - s) * v0 + s * v1) + t * ((1.0 - s) * v2 + s * v3);
    }

    static function mx_bilerp_1(v0: Array<Float>, v1: Array<Float>, v2: Array<Float>, v3: Array<Float>, s: Float, t: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_bilerp_0(v0[0], v1[0], v2[0], v3[0], s, t);
        result[1] = mx_bilerp_0(v0[1], v1[1], v2[1], v3[1], s, t);
        result[2] = mx_bilerp_0(v0[2], v1[2], v2[2], v3[2], s, t);
        return result;
    }

    static function mx_trilerp_0(v0: Float, v1: Float, v2: Float, v3: Float, v4: Float, v5: Float, v6: Float, v7: Float, s: Float, t: Float, r: Float): Float {
        return (1.0 - r) * ((1.0 - t) * ((1.0 - s) * v0 + s * v1) + t * ((1.0 - s) * v2 + s * v3)) + r * ((1.0 - t) * ((1.0 - s) * v4 + s * v5) + t * ((1.0 - s) * v6 + s * v7));
    }

    static function mx_trilerp_1(v0: Array<Float>, v1: Array<Float>, v2: Array<Float>, v3: Array<Float>, v4: Array<Float>, v5: Array<Float>, v6: Array<Float>, v7: Array<Float>, s: Float, t: Float, r: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_trilerp_0(v0[0], v1[0], v2[0], v3[0], v4[0], v5[0], v6[0], v7[0], s, t, r);
        result[1] = mx_trilerp_0(v0[1], v1[1], v2[1], v3[1], v4[1], v5[1], v6[1], v7[1], s, t, r);
        result[2] = mx_trilerp_0(v0[2], v1[2], v2[2], v3[2], v4[2], v5[2], v6[2], v7[2], s, t, r);
        return result;
    }

    static function mx_gradient_float_0(hash: Int, x: Float, y: Float): Float {
        var h: Int = hash & 7;
        var u: Float = h < 4 ? x : y;
        var v: Float = h < 4 ? 2.0 * y : (h != 12 && h != 14) ? x : y;
        if (h & 1 != 0) u = -u;
        if (h & 2 != 0) v = -v;
        return u + v;
    }

    static function mx_gradient_float_1(hash: Int, x: Float, y: Float, z: Float): Float {
        var h: Int = hash & 15;
        var u: Float = h < 8 ? x : y;
        var v: Float = h < 4 ? y : (h == 12 || h == 14) ? x : z;
        if (h & 1 != 0) u = -u;
        if (h & 2 != 0) v = -v;
        return u + v;
    }

    static function mx_gradient_vec3_0(hash: Array<Int>, x: Float, y: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_gradient_float_0(hash[0], x, y);
        result[1] = mx_gradient_float_0(hash[1], x, y);
        result[2] = mx_gradient_float_0(hash[2], x, y);
        return result;
    }

    static function mx_gradient_vec3_1(hash: Array<Int>, x: Float, y: Float, z: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_gradient_float_1(hash[0], x, y, z);
        result[1] = mx_gradient_float_1(hash[1], x, y, z);
        result[2] = mx_gradient_float_1(hash[2], x, y, z);
        return result;
    }

    static function mx_gradient_scale2d_0(v: Float): Float {
        return 0.6616 * v;
    }

    static function mx_gradient_scale3d_0(v: Float): Float {
        return 0.9820 * v;
    }

    static function mx_gradient_scale2d_1(v: Array<Float>): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_gradient_scale2d_0(v[0]);
        result[1] = mx_gradient_scale2d_0(v[1]);
        result[2] = mx_gradient_scale2d_0(v[2]);
        return result;
    }

    static function mx_gradient_scale3d_1(v: Array<Float>): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_gradient_scale3d_0(v[0]);
        result[1] = mx_gradient_scale3d_0(v[1]);
        result[2] = mx_gradient_scale3d_0(v[2]);
        return result;
    }

    static function mx_rotl32(x: Int, k: Int): Int {
        return (x << k) | (x >>> (32 - k));
    }

    static function mx_bjmix(a: Int, b: Int, c: Int): Void {
        a -= c;
        a ^= mx_rotl32(c, 4);
        c += b;
        b -= a;
        b ^= mx_rotl32(a, 6);
        a += c;
        c -= b;
        c ^= mx_rotl32(b, 8);
        b += a;
        a -= c;
        a ^= mx_rotl32(c, 16);
        c += b;
        b -= a;
        b ^= mx_rotl32(a, 19);
        a += c;
        c -= b;
        c ^= mx_rotl32(b, 4);
        b += a;
    }

    static function mx_bjfinal(a: Int, b: Int, c: Int): Int {
        c ^= b;
        c -= mx_rotl32(b, 14);
        a ^= c;
        a -= mx_rotl32(c, 11);
        b ^= a;
        b -= mx_rotl32(a, 25);
        c ^= b;
        c -= mx_rotl32(b, 16);
        a ^= c;
        a -= mx_rotl32(c, 4);
        b ^= a;
        b -= mx_rotl32(a, 14);
        c ^= b;
        c -= mx_rotl32(b, 24);
        return c;
    }

    static function mx_bits_to_01(bits: Int): Float {
        return bits / 4294967295.0;
    }

    static function mx_fade(t: Float): Float {
        return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
    }

    static function mx_hash_int_0(x: Int): Int {
        var seed: Int = 0xdeadbeef + (1 << 2) + 13;
        return mx_bjfinal(seed + x, seed, seed);
    }

    static function mx_hash_int_1(x: Int, y: Int): Int {
        var seed: Int = 0xdeadbeef + (2 << 2) + 13;
        var a: Int = seed;
        var b: Int = seed;
        var c: Int = seed;
        a += x;
        b += y;
        return mx_bjfinal(a, b, c);
    }

    static function mx_hash_int_2(x: Int, y: Int, z: Int): Int {
        var seed: Int = 0xdeadbeef + (3 << 2) + 13;
        var a: Int = seed;
        var b: Int = seed;
        var c: Int = seed;
        a += x;
        b += y;
        c += z;
        return mx_bjfinal(a, b, c);
    }

    static function mx_hash_int_3(x: Int, y: Int, z: Int, xx: Int): Int {
        var seed: Int = 0xdeadbeef + (4 << 2) + 13;
        var a: Int = seed;
        var b: Int = seed;
        var c: Int = seed;
        a += x;
        b += y;
        c += z;
        mx_bjmix(a, b, c);
        a += xx;
        return mx_bjfinal(a, b, c);
    }

    static function mx_hash_int_4(x: Int, y: Int, z: Int, xx: Int, yy: Int): Int {
        var seed: Int = 0xdeadbeef + (5 << 2) + 13;
        var a: Int = seed;
        var b: Int = seed;
        var c: Int = seed;
        a += x;
        b += y;
        c += z;
        mx_bjmix(a, b, c);
        a += xx;
        b += yy;
        return mx_bjfinal(a, b, c);
    }

    static function mx_hash_vec3_0(x: Int, y: Int): Array<Int> {
        var h: Int = mx_hash_int_0(x, y);
        var result: Array<Int> = new Array<Int>();
        result[0] = h & 0xFF;
        result[1] = (h >> 8) & 0xFF;
        result[2] = (h >> 16) & 0xFF;
        return result;
    }

    static function mx_hash_vec3_1(x: Int, y: Int, z: Int): Array<Int> {
        var h: Int = mx_hash_int_1(x, y, z);
        var result: Array<Int> = new Array<Int>();
        result[0] = h & 0xFF;
        result[1] = (h >> 8) & 0xFF;
        result[2] = (h >> 16) & 0xFF;
        return result;
    }

    static function mx_perlin_noise_float_0(p: Array<Float>): Float {
        var X: Int = 0;
        var Y: Int = 0;
        var fx: Float = mx_floorfrac(p[0], X);
        var fy: Float = mx_floorfrac(p[1], Y);
        var u: Float = mx_fade(fx);
        var v: Float = mx_fade(fy);
        var result: Float = mx_bilerp_0(mx_gradient_float_0(mx_hash_int_0(X, Y), fx, fy), mx_gradient_float_0(mx_hash_int_0(X + 1, Y), fx - 1.0, fy), mx_gradient_float_0(mx_hash_int_0(X, Y + 1), fx, fy - 1.0), mx_gradient_float_0(mx_hash_int_0(X + 1, Y + 1), fx - 1.0, fy - 1.0), u, v);
        return mx_gradient_scale2d_0(result);
    }

    static function mx_perlin_noise_float_1(p: Array<Float>): Float {
        var X: Int = 0;
        var Y: Int = 0;
        var Z: Int = 0;
        var fx: Float = mx_floorfrac(p[0], X);
        var fy: Float = mx_floorfrac(p[1], Y);
        var fz: Float = mx_floorfrac(p[2], Z);
        var u: Float = mx_fade(fx);
        var v: Float = mx_fade(fy);
        var w: Float = mx_fade(fz);
        var result: Float = mx_trilerp_0(mx_gradient_float_1(mx_hash_int_1(X, Y, Z), fx, fy, fz), mx_gradient_float_1(mx_hash_int_1(X + 1, Y, Z), fx - 1.0, fy, fz), mx_gradient_float_1(mx_hash_int_1(X, Y + 1, Z), fx, fy - 1.0, fz), mx_gradient_float_1(mx_hash_int_1(X + 1, Y + 1, Z), fx - 1.0, fy - 1.0, fz), mx_gradient_float_1(mx_hash_int_1(X, Y, Z + 1), fx, fy, fz - 1.0), mx_gradient_float_1(mx_hash_int_1(X + 1, Y, Z + 1), fx - 1.0, fy, fz - 1.0), mx_gradient_float_1(mx_hash_int_1(X, Y + 1, Z + 1), fx, fy - 1.0, fz - 1.0), mx_gradient_float_1(mx_hash_int_1(X + 1, Y + 1, Z + 1), fx - 1.0, fy - 1.0, fz - 1.0), u, v, w);
        return mx_gradient_scale3d_0(result);
    }

    static function mx_perlin_noise_vec3_0(p: Array<Float>): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var fx: Float = mx_floorfrac(p[0], X);
        var fy: Float = mx_floorfrac(p[1], Y);
        var u: Float = mx_fade(fx);
        var v: Float = mx_fade(fy);
        var result: Array<Float> = mx_bilerp_1(mx_gradient_vec3_0(mx_hash_vec3_0(X, Y), fx, fy), mx_gradient_vec3_0(mx_hash_vec3_0(X + 1, Y), fx - 1.0, fy), mx_gradient_vec3_0(mx_hash_vec3_0(X, Y + 1), fx, fy - 1.0), mx_gradient_vec3_0(mx_hash_vec3_0(X + 1, Y + 1), fx - 1.0, fy - 1.0), u, v);
        return mx_gradient_scale2d_1(result);
    }

    static function mx_perlin_noise_vec3_1(p: Array<Float>): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var Z: Int = 0;
        var fx: Float = mx_floorfrac(p[0], X);
        var fy: Float = mx_floorfrac(p[1], Y);
        var fz: Float = mx_floorfrac(p[2], Z);
        var u: Float = mx_fade(fx);
        var v: Float = mx_fade(fy);
        var w: Float = mx_fade(fz);
        var result: Array<Float> = mx_trilerp_1(mx_gradient_vec3_1(mx_hash_vec3_1(X, Y, Z), fx, fy, fz), mx_gradient_vec3_1(mx_hash_vec3_1(X + 1, Y, Z), fx - 1.0, fy, fz), mx_gradient_vec3_1(mx_hash_vec3_1(X, Y + 1, Z), fx, fy - 1.0, fz), mx_gradient_vec3_1(mx_hash_vec3_1(X + 1, Y + 1, Z), fx - 1.0, fy - 1.0, fz), mx_gradient_vec3_1(mx_hash_vec3_1(X, Y, Z + 1), fx, fy, fz - 1.0), mx_gradient_vec3_1(mx_hash_vec3_1(X + 1, Y, Z + 1), fx - 1.0, fy, fz - 1.0), mx_gradient_vec3_1(mx_hash_vec3_1(X, Y + 1, Z + 1), fx, fy - 1.0, fz - 1.0), mx_gradient_vec3_1(mx_hash_vec3_1(X + 1, Y + 1, Z + 1), fx - 1.0, fy - 1.0, fz - 1.0), u, v, w);
        return mx_gradient_scale3d_1(result);
    }

    static function mx_cell_noise_float_0(p: Float): Float {
        var ix: Int = mx_floor(p);
        return mx_bits_to_01(mx_hash_int_0(ix));
    }

    static function mx_cell_noise_float_1(p: Array<Float>): Float {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        return mx_bits_to_01(mx_hash_int_1(ix, iy));
    }

    static function mx_cell_noise_float_2(p: Array<Float>): Float {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        var iz: Int = mx_floor(p[2]);
        return mx_bits_to_01(mx_hash_int_2(ix, iy, iz));
    }

    static function mx_cell_noise_float_3(p: Array<Float>): Float {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        var iz: Int = mx_floor(p[2]);
        var iw: Int = mx_floor(p[3]);
        return mx_bits_to_01(mx_hash_int_3(ix, iy, iz, iw));
    }

    static function mx_cell_noise_vec3_0(p: Float): Array<Float> {
        var ix: Int = mx_floor(p);
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_bits_to_01(mx_hash_int_1(ix, 0));
        result[1] = mx_bits_to_01(mx_hash_int_1(ix, 1));
        result[2] = mx_bits_to_01(mx_hash_int_1(ix, 2));
        return result;
    }

    static function mx_cell_noise_vec3_1(p: Array<Float>): Array<Float> {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_bits_to_01(mx_hash_int_2(ix, iy, 0));
        result[1] = mx_bits_to_01(mx_hash_int_2(ix, iy, 1));
        result[2] = mx_bits_to_01(mx_hash_int_2(ix, iy, 2));
        return result;
    }

    static function mx_cell_noise_vec3_2(p: Array<Float>): Array<Float> {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        var iz: Int = mx_floor(p[2]);
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_bits_to_01(mx_hash_int_3(ix, iy, iz, 0));
        result[1] = mx_bits_to_01(mx_hash_int_3(ix, iy, iz, 1));
        result[2] = mx_bits_to_01(mx_hash_int_3(ix, iy, iz, 2));
        return result;
    }

    static function mx_cell_noise_vec3_3(p: Array<Float>): Array<Float> {
        var ix: Int = mx_floor(p[0]);
        var iy: Int = mx_floor(p[1]);
        var iz: Int = mx_floor(p[2]);
        var iw: Int = mx_floor(p[3]);
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_bits_to_01(mx_hash_int_4(ix, iy, iz, iw, 0));
        result[1] = mx_bits_to_01(mx_hash_int_4(ix, iy, iz, iw, 1));
        result[2] = mx_bits_to_01(mx_hash_int_4(ix, iy, iz, iw, 2));
        return result;
    }

    static function mx_fractal_noise_float(p: Array<Float>, octaves: Int, lacunarity: Float, diminish: Float): Float {
        var result: Float = 0.0;
        var amplitude: Float = 1.0;
        for (var i: Int = 0; i < octaves; i++) {
            result += amplitude * mx_perlin_noise_float_1(p);
            amplitude *= diminish;
            p[0] *= lacunarity;
            p[1] *= lacunarity;
            p[2] *= lacunarity;
        }
        return result;
    }

    static function mx_fractal_noise_vec3(p: Array<Float>, octaves: Int, lacunarity: Float, diminish: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = 0.0;
        result[1] = 0.0;
        result[2] = 0.0;
        var amplitude: Float = 1.0;
        for (var i: Int = 0; i < octaves; i++) {
            var temp: Array<Float> = mx_perlin_noise_vec3_1(p);
            result[0] += amplitude * temp[0];
            result[1] += amplitude * temp[1];
            result[2] += amplitude * temp[2];
            amplitude *= diminish;
            p[0] *= lacunarity;
            p[1] *= lacunarity;
            p[2] *= lacunarity;
        }
        return result;
    }

    static function mx_fractal_noise_vec2(p: Array<Float>, octaves: Int, lacunarity: Float, diminish: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        result[0] = mx_fractal_noise_float(p, octaves, lacunarity, diminish);
        result[1] = mx_fractal_noise_float([p[0] + 19, p[1] + 193, p[2] + 17], octaves, lacunarity, diminish);
        return result;
    }

    static function mx_fractal_noise_vec4(p: Array<Float>, octaves: Int, lacunarity: Float, diminish: Float): Array<Float> {
        var result: Array<Float> = new Array<Float>();
        var c: Array<Float> = mx_fractal_noise_vec3(p, octaves, lacunarity, diminish);
        var f: Float = mx_fractal_noise_float([p[0] + 19, p[1] + 193, p[2] + 17], octaves, lacunarity, diminish);
        result[0] = c[0];
        result[1] = c[1];
        result[2] = c[2];
        result[3] = f;
        return result;
    }

    static function mx_worley_distance_0(p: Array<Float>, x: Int, y: Int, xoff: Int, yoff: Int, jitter: Float, metric: Int): Float {
        var tmp: Array<Float> = mx_cell_noise_vec3_0(x + xoff, y + yoff);
        var off: Array<Float> = [tmp[0], tmp[1]];
        off[0] -= 0.5;
        off[1] -= 0.5;
        off[0] *= jitter;
        off[1] *= jitter;
        off[0] += 0.5;
        off[1] += 0.5;
        var cellpos: Array<Float> = [x + off[0], y + off[1]];
        var diff: Array<Float> = [cellpos[0] - p[0], cellpos[1] - p[1]];
        if (metric == 2) {
            return Math.abs(diff[0]) + Math.abs(diff[1]);
        } else if (metric == 3) {
            return Math.max(Math.abs(diff[0]), Math.abs(diff[1]));
        } else {
            return diff[0] * diff[0] + diff[1] * diff[1];
        }
    }

    static function mx_worley_distance_1(p: Array<Float>, x: Int, y: Int, z: Int, xoff: Int, yoff: Int, zoff: Int, jitter: Float, metric: Int): Float {
        var off: Array<Float> = mx_cell_noise_vec3_1(x + xoff, y + yoff, z + zoff);
        off[0] -= 0.5;
        off[1] -= 0.5;
        off[2] -= 0.5;
        off[0] *= jitter;
        off[1] *= jitter;
        off[2] *= jitter;
        off[0] += 0.5;
        off[1] += 0.5;
        off[2] += 0.5;
        var cellpos: Array<Float> = [x + off[0], y + off[1], z + off[2]];
        var diff: Array<Float> = [cellpos[0] - p[0], cellpos[1] - p[1], cellpos[2] - p[2]];
        if (metric == 2) {
            return Math.abs(diff[0]) + Math.abs(diff[1]) + Math.abs(diff[2]);
        } else if (metric == 3) {
            return Math.max(Math.max(Math.abs(diff[0]), Math.abs(diff[1])), Math.abs(diff[2]));
        } else {
            return diff[0] * diff[0] + diff[1] * diff[1] + diff[2] * diff[2];
        }
    }

    static function mx_worley_noise_float_0(p: Array<Float>, jitter: Float, metric: Int): Float {
        var X: Int = 0;
        var Y: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y)];
        var sqdist: Float = 1e6;
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                var dist: Float = mx_worley_distance_0(localpos, x, y, X, Y, jitter, metric);
                sqdist = Math.min(sqdist, dist);
            }
        }
        if (metric == 0) {
            sqdist = Math.sqrt(sqdist);
        }
        return sqdist;
    }

    static function mx_worley_noise_vec2_0(p: Array<Float>, jitter: Float, metric: Int): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y)];
        var sqdist: Array<Float> = [1e6, 1e6];
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                var dist: Float = mx_worley_distance_0(localpos, x, y, X, Y, jitter, metric);
                if (dist < sqdist[0]) {
                    sqdist[1] = sqdist[0];
                    sqdist[0] = dist;
                } else if (dist < sqdist[1]) {
                    sqdist[1] = dist;
                }
            }
        }
        if (metric == 0) {
            sqdist[0] = Math.sqrt(sqdist[0]);
            sqdist[1] = Math.sqrt(sqdist[1]);
        }
        return sqdist;
    }

    static function mx_worley_noise_vec3_0(p: Array<Float>, jitter: Float, metric: Int): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y)];
        var sqdist: Array<Float> = [1e6, 1e6, 1e6];
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                var dist: Float = mx_worley_distance_0(localpos, x, y, X, Y, jitter, metric);
                if (dist < sqdist[0]) {
                    sqdist[2] = sqdist[1];
                    sqdist[1] = sqdist[0];
                    sqdist[0] = dist;
                } else if (dist < sqdist[1]) {
                    sqdist[2] = sqdist[1];
                    sqdist[1] = dist;
                } else if (dist < sqdist[2]) {
                    sqdist[2] = dist;
                }
            }
        }
        if (metric == 0) {
            sqdist[0] = Math.sqrt(sqdist[0]);
            sqdist[1] = Math.sqrt(sqdist[1]);
            sqdist[2] = Math.sqrt(sqdist[2]);
        }
        return sqdist;
    }

    static function mx_worley_noise_float_1(p: Array<Float>, jitter: Float, metric: Int): Float {
        var X: Int = 0;
        var Y: Int = 0;
        var Z: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y), mx_floorfrac(p[2], Z)];
        var sqdist: Float = 1e6;
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                for (var z: Int = -1; z <= 1; z++) {
                    var dist: Float = mx_worley_distance_1(localpos, x, y, z, X, Y, Z, jitter, metric);
                    sqdist = Math.min(sqdist, dist);
                }
            }
        }
        if (metric == 0) {
            sqdist = Math.sqrt(sqdist);
        }
        return sqdist;
    }

    static function mx_worley_noise_vec2_1(p: Array<Float>, jitter: Float, metric: Int): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var Z: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y), mx_floorfrac(p[2], Z)];
        var sqdist: Array<Float> = [1e6, 1e6];
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                for (var z: Int = -1; z <= 1; z++) {
                    var dist: Float = mx_worley_distance_1(localpos, x, y, z, X, Y, Z, jitter, metric);
                    if (dist < sqdist[0]) {
                        sqdist[1] = sqdist[0];
                        sqdist[0] = dist;
                    } else if (dist < sqdist[1]) {
                        sqdist[1] = dist;
                    }
                }
            }
        }
        if (metric == 0) {
            sqdist[0] = Math.sqrt(sqdist[0]);
            sqdist[1] = Math.sqrt(sqdist[1]);
        }
        return sqdist;
    }

    static function mx_worley_noise_vec3_1(p: Array<Float>, jitter: Float, metric: Int): Array<Float> {
        var X: Int = 0;
        var Y: Int = 0;
        var Z: Int = 0;
        var localpos: Array<Float> = [mx_floorfrac(p[0], X), mx_floorfrac(p[1], Y), mx_floorfrac(p[2], Z)];
        var sqdist: Array<Float> = [1e6, 1e6, 1e6];
        for (var x: Int = -1; x <= 1; x++) {
            for (var y: Int = -1; y <= 1; y++) {
                for (var z: Int = -1; z <= 1; z++) {
                    var dist: Float = mx_worley_distance_1(localpos, x, y, z, X, Y, Z, jitter, metric);
                    if (dist < sqdist[0]) {
                        sqdist[2] = sqdist[1];
                        sqdist[1] = sqdist[0];
                        sqdist[0] = dist;
                    } else if (dist < sqdist[1]) {
                        sqdist[2] = sqdist[1];
                        sqdist[1] = dist;
                    } else if (dist < sqdist[2]) {
                        sqdist[2] = dist;
                    }
                }
            }
        }
        if (metric == 0) {
            sqdist[0] = Math.sqrt(sqdist[0]);
            sqdist[1] = Math.sqrt(sqdist[1]);
            sqdist[2] = Math.sqrt(sqdist[2]);
        }
        return sqdist;
    }
}