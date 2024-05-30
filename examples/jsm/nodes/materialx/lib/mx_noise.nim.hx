import Int.Int32;
import UInt.UInt32;
import Float32.Float32;
import Vector.Vec3;
import Bool.Bool;
import UInt.UInt32x3;
import Vector.Vec2;
import Vector.Vec4;
import If;
import TSLFn;
import OperatorNode;
import MathNode;
import FunctionOverloadingNode;
import LoopNode;

class MxNoise {
    static function select(b: Bool, t: Float32, f: Float32): Float32 {
        var fVar = f.toVar();
        var tVar = t.toVar();
        var bVar = b.toVar();
        return If(bVar).then(tVar).else_(fVar);
    }

    static function negateIf(val: Float32, b: Bool): Float32 {
        var valVar = val.toVar();
        var bVar = b.toVar();
        return If(bVar).then(valVar.negate()).else_(valVar);
    }

    static function floor(x: Float32): Int32 {
        var xVar = x.toVar();
        return Int32(MathNode.floor(xVar));
    }

    static function floorfrac(x: Float32, i: Int32): Float32 {
        var xVar = x.toVar();
        i.assign(floor(xVar));
        return xVar.sub(Float32(i));
    }

    static function bilerp(v0: Float32, v1: Float32, v2: Float32, v3: Float32, s: Float32, t: Float32): Float32 {
        var tVar = t.toVar();
        var sVar = s.toVar();
        var v3Var = v3.toVar();
        var v2Var = v2.toVar();
        var v1Var = v1.toVar();
        var v0Var = v0.toVar();
        var s1Var = Float32(1.0).sub(sVar).toVar();
        return Float32(1.0).sub(tVar).mul(v0Var.mul(s1Var).add(v1Var.mul(sVar))).add(tVar.mul(v2Var.mul(s1Var).add(v3Var.mul(sVar))));
    }

    static function trilerp(v0: Float32, v1: Float32, v2: Float32, v3: Float32, v4: Float32, v5: Float32, v6: Float32, v7: Float32, s: Float32, t: Float32, r: Float32): Float32 {
        var rVar = r.toVar();
        var tVar = t.toVar();
        var sVar = s.toVar();
        var v7Var = v7.toVar();
        var v6Var = v6.toVar();
        var v5Var = v5.toVar();
        var v4Var = v4.toVar();
        var v3Var = v3.toVar();
        var v2Var = v2.toVar();
        var v1Var = v1.toVar();
        var v0Var = v0.toVar();
        var s1Var = Float32(1.0).sub(sVar).toVar();
        var t1Var = Float32(1.0).sub(tVar).toVar();
        var r1Var = Float32(1.0).sub(rVar).toVar();
        return r1Var.mul(t1Var.mul(v0Var.mul(s1Var).add(v1Var.mul(sVar))).add(tVar.mul(v2Var.mul(s1Var).add(v3Var.mul(sVar))))).add(rVar.mul(t1Var.mul(v4Var.mul(s1Var).add(v5Var.mul(sVar))).add(tVar.mul(v6Var.mul(s1Var).add(v7Var.mul(sVar))))));
    }

    static function gradientFloat(hash: UInt32, x: Float32, y: Float32): Float32 {
        var yVar = y.toVar();
        var xVar = x.toVar();
        var hashVar = hash.toVar();
        var hVar = hashVar.bitAnd(UInt32(7)).toVar();
        var uVar = Float32(If(hVar.lessThan(UInt32(4))).then(xVar).else_(yVar)).toVar();
        var vVar = Float32(OperatorNode.mul(2.0, If(hVar.lessThan(UInt32(4))).then(yVar).else_(xVar))).toVar();
        return Float32(negateIf(uVar, Bool(hVar.bitAnd(UInt32(1))))).add(Float32(negateIf(vVar, Bool(hVar.bitAnd(UInt32(2))))));
    }

    static function gradientVec3(hash: UInt32x3, x: Float32, y: Float32): Vec3 {
        var yVar = y.toVar();
        var xVar = x.toVar();
        var hashVar = hash.toVar();
        return Vec3(gradientFloat(hashVar.x, xVar, yVar), gradientFloat(hashVar.y, xVar, yVar), gradientFloat(hashVar.z, xVar, yVar));
    }

    static function gradientScale2d(v: Float32): Float32 {
        var vVar = v.toVar();
        return OperatorNode.mul(0.6616, vVar);
    }

    static function gradientScale3d(v: Float32): Float32 {
        var vVar = v.toVar();
        return OperatorNode.mul(0.9820, vVar);
    }

    static function rotl32(x: UInt32, k: Int32): UInt32 {
        var kVar = k.toVar();
        var xVar = x.toVar();
        return xVar.shiftLeft(kVar).bitOr(xVar.shiftRight(Int32(32).sub(kVar)));
    }

    static function bjmix(a: UInt32, b: UInt32, c: UInt32): Void {
        var cVar = c.toVar();
        var bVar = b.toVar();
        var aVar = a.toVar();
        aVar.subAssign(cVar);
        aVar.bitXorAssign(rotl32(cVar, Int32(4)));
        cVar.addAssign(bVar);
        bVar.subAssign(aVar);
        bVar.bitXorAssign(rotl32(aVar, Int32(6)));
        aVar.addAssign(cVar);
        cVar.subAssign(bVar);
        cVar.bitXorAssign(rotl32(bVar, Int32(8)));
        bVar.addAssign(aVar);
        aVar.subAssign(cVar);
        aVar.bitXorAssign(rotl32(cVar, Int32(16)));
        cVar.addAssign(bVar);
        bVar.subAssign(aVar);
        bVar.bitXorAssign(rotl32(aVar, Int32(19)));
        aVar.addAssign(cVar);
        cVar.subAssign(bVar);
        cVar.bitXorAssign(rotl32(bVar, Int32(4)));
        bVar.addAssign(aVar);
    }

    static function bjfinal(a: UInt32, b: UInt32, c: UInt32): UInt32 {
        var cVar = c.toVar();
        var bVar = b.toVar();
        var aVar = a.toVar();
        cVar.bitXorAssign(bVar);
        cVar.subAssign(rotl32(bVar, Int32(14)));
        aVar.bitXorAssign(cVar);
        aVar.subAssign(rotl32(cVar, Int32(11)));
        bVar.bitXorAssign(aVar);
        bVar.subAssign(rotl32(aVar, Int32(25)));
        cVar.bitXorAssign(bVar);
        cVar.subAssign(rotl32(bVar, Int32(16)));
        aVar.bitXorAssign(cVar);
        aVar.subAssign(rotl32(cVar, Int32(4)));
        bVar.bitXorAssign(aVar);
        bVar.subAssign(rotl32(aVar, Int32(14)));
        cVar.bitXorAssign(bVar);
        cVar.subAssign(rotl32(bVar, Int32(24)));
        return cVar;
    }

    static function bitsTo01(bits: UInt32): Float32 {
        var bitsVar = bits.toVar();
        return Float32(bitsVar).div(Float32(UInt32(Int32(0xffffffff))));
    }

    static function fade(t: Float32): Float32 {
        var tVar = t.toVar();
        return tVar.mul(tVar.mul(tVar.mul(tVar.mul(tVar.mul(6.0).sub(15.0)).add(10.0))));
    }

    static function hashInt(x: Int32): UInt32 {
        var xVar = x.toVar();
        var len = UInt32(UInt32(1)).toVar();
        var seed = UInt32(UInt32(Int32(0xdeadbeef)).add(len.shiftLeft(UInt32(2)).add(UInt32(13)))).toVar();
        return bjfinal(seed.add(UInt32(xVar)), seed, seed);
    }

    static function hashVec3(x: Int32, y: Int32): UInt32x3 {
        var yVar = y.toVar();
        var xVar = x.toVar();
        var h = UInt32(bjfinal(UInt32(xVar), UInt32(yVar), UInt32(Int32(0xdeadbeef)))).toVar();
        var result = UInt32x3().toVar();
        result.x.assign(h.bitAnd(Int32(0xFF)));
        result.y.assign(h.shiftRight(Int32(8)).bitAnd(Int32(0xFF)));
        result.z.assign(h.shiftRight(Int32(16)).bitAnd(Int32(0xFF)));
        return result;
    }

    static function perlinNoiseFloat(p: Vec2): Float32 {
        var pVar = p.toVar();
        var X = Int32().toVar();
        var Y = Int32().toVar();
        var fx = Float32(floorfrac(pVar.x, X)).toVar();
        var fy = Float32(floorfrac(pVar.y, Y)).toVar();
        var u = Float32(fade(fx)).toVar();
        var v = Float32(fade(fy)).toVar();
        var result = Float32(bilerp(gradientFloat(hashInt(X), fx, fy), gradientFloat(hashInt(X.add(Int32(1))), Float32(1.0).sub(fx), fy), gradientFloat(hashInt(Y), fx, Float32(1.0).sub(fy)), gradientFloat(hashInt(Y.add(Int32(1))), Float32(1.0).sub(fx), Float32(1.0).sub(fy)), u, v)).toVar();
        return gradientScale2d(result);
    }

    static function perlinNoiseVec3(p: Vec3): Vec3 {
        var pVar = p.toVar();
        var X = Int32().toVar();
        var Y = Int32().toVar();
        var Z = Int32().toVar();
        var fx = Float32(floorfrac(pVar.x, X)).toVar();
        var fy = Float32(floorfrac(pVar.y, Y)).toVar();
        var fz = Float32(floorfrac(pVar.z, Z)).toVar();
        var u = Float32(fade(fx)).toVar();
        var v = Float32(fade(fy)).toVar();
        var w = Float32(fade(fz)).toVar();
        var result = Vec3(Float32(trilerp(gradientFloat(hashInt(X), fx, fy, fz), gradientFloat(hashInt(X.add(Int32(1))), Float32(1.0).sub(fx), fy, fz), gradientFloat(hashInt(Y), fx, Float32(1.0).sub(fy), fz), gradientFloat(hashInt(Y.add(Int32(1))), Float32(1.0).sub(fx), Float32(1.0).sub(fy), fz), gradientFloat(hashInt(Z), fx, fy, Float32(1.0).sub(fz)), gradientFloat(hashInt(Z.add(Int32(1))), Float32(1.0).sub(fx), fy, Float32(1.0).sub(fz)), gradientFloat(hashInt(Z.add(Int32(1))), fx, Float32(1.0).sub(fy), Float32(1.0).sub(fz)), gradientFloat(hashInt(Z.add(Int32(1))), Float32(1.0).sub(fx), Float32(1.0).sub(fy), Float32(1.0).sub(fz)), u, v, w))).toVar();
        return gradientScale3d(result);
    }

    static function cellNoiseFloat(p: Float32): Float32 {
        var pVar = p.toVar();
        var ix = Int32(floor(pVar)).toVar();
        return bitsTo01(hashInt(ix));
    }

    static function cellNoiseVec3(p: Vec2): Vec3 {
        var pVar = p.toVar();
        var ix = Int32(floor(pVar.x)).toVar();
        var iy = Int32(floor(pVar.y)).toVar();
        return Vec3(bitsTo01(hashInt(ix, iy, Int32(0))), bitsTo01(hashInt(ix, iy, Int32(1))), bitsTo01(hashInt(ix, iy, Int32(2))));
    }

    static function fractalNoiseFloat(p: Vec3, octaves: Int32, lacunarity: Float32, diminish: Float32): Float32 {
        var diminishVar = diminish.toVar();
        var lacunarityVar = lacunarity.toVar();
        var octavesVar = octaves.toVar();
        var pVar = p.toVar();
        var result = Float32(0.0).toVar();
        var amplitude = Float32(1.0).toVar();
        LoopNode.loop({ start: Int32(0), end: octavesVar }, (i) -> {
            result.addAssign(amplitude.mul(perlinNoiseFloat(pVar)));
            amplitude.mulAssign(diminishVar);
            pVar.mulAssign(lacunarityVar);
        });
        return result;
    }

    static function fractalNoiseVec3(p: Vec3, octaves: Int32, lacunarity: Float32, diminish: Float32): Vec3 {
        var diminishVar = diminish.toVar();
        var lacunarityVar = lacunarity.toVar();
        var octavesVar = octaves.toVar();
        var pVar = p.toVar();
        var result = Vec3(0.0).toVar();
        var amplitude = Float32(1.0).toVar();
        LoopNode.loop({ start: Int32(0), end: octavesVar }, (i) -> {
            result.addAssign(amplitude.mul(perlinNoiseVec3(pVar)));
            amplitude.mulAssign(diminishVar);
            pVar.mulAssign(lacunarityVar);
        });
        return result;
    }

    static function worleyDistance(p: Vec2, x: Int32, y: Int32, xoff: Int32, yoff: Int32, jitter: Float32, metric: Int32): Float32 {
        var metricVar = metric.toVar();
        var jitterVar = jitter.toVar();
        var yoffVar = yoff.toVar();
        var xoffVar = xoff.toVar();
        var yVar = y.toVar();
        var xVar = x.toVar();
        var pVar = p.toVar();
        var tmp = Vec3(cellNoiseVec3(Vec2(xVar.add(xoffVar), yVar.add(yoffVar)))).toVar();
        var off = Vec2(tmp.x, tmp.y).toVar();
        off.subAssign(0.5);
        off.mulAssign(jitterVar);
        off.addAssign(0.5);
        var cellpos = Vec2(Vec2(Float32(xVar), Float32(yVar)).add(off)).toVar();
        var diff = Vec2(cellpos.sub(pVar)).toVar();
        If(metricVar.equal(Int32(2))).then(() -> {
            return MathNode.abs(diff.x).add(MathNode.abs(diff.y));
        }).elseif(metricVar.equal(Int32(3))).then(() -> {
            return MathNode.max(MathNode.abs(diff.x), MathNode.abs(diff.y));
        }).else(() -> {
            return MathNode.dot(diff, diff);
        });
    }

    static function worleyNoiseFloat(p: Vec2, jitter: Float32, metric: Int32): Float32 {
        var metricVar = metric.toVar();
        var jitterVar = jitter.toVar();
        var pVar = p.toVar();
        var X = Int32().toVar();
        var Y = Int32().toVar();
        var localpos = Vec2(floorfrac(pVar.x, X), floorfrac(pVar.y, Y)).toVar();
        var sqdist = Float32(1e6).toVar();
        LoopNode.loop({ start: -1, end: Int32(1), name: 'x', condition: '<=' }, (x) -> {
            LoopNode.loop({ start: -1, end: Int32(1), name: 'y', condition: '<=' }, (y) -> {
                var dist = Float32(worleyDistance(localpos, x, y, X, Y, jitterVar, metricVar)).toVar();
                sqdist.assign(MathNode.min(sqdist, dist));
            });
        });
        If(metricVar.equal(Int32(0))).then(() -> {
            sqdist.assign(MathNode.sqrt(sqdist));
        });
        return sqdist;
    }

    static function worleyNoiseVec3(p: Vec2, jitter: Float32, metric: Int32): Vec3 {
        var metricVar = metric.toVar();
        var jitterVar = jitter.toVar();
        var pVar = p.toVar();
        var X = Int32().toVar();
        var Y = Int32().toVar();
        var localpos = Vec2(floorfrac(pVar.x, X), floorfrac(pVar.y, Y)).toVar();
        var sqdist = Vec3(1e6, 1e6, 1e6).toVar();
        LoopNode.loop({ start: -1, end: Int32(1), name: 'x', condition: '<=' }, (x) -> {
            LoopNode.loop({ start: -1, end: Int32(1), name: 'y', condition: '<=' }, (y) -> {
                var dist = Float32(worleyDistance(localpos, x, y, X, Y, jitterVar, metricVar)).toVar();
                If(dist.lessThan(sqdist.x)).then(() -> {
                    sqdist.y.assign(sqdist.x);
                    sqdist.x.assign(dist);
                }).elseif(dist.lessThan(sqdist.y)).then(() -> {
                    sqdist.y.assign(dist);
                });
            });
        });
        If(metricVar.equal(Int32(0))).then(() -> {
            sqdist.assign(Vec3(MathNode.sqrt(sqdist.x), MathNode.sqrt(sqdist.y), MathNode.sqrt(sqdist.z)));
        });
        return sqdist;
    }
}