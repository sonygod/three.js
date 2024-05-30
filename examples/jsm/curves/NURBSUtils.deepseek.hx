import three.Vector3;
import three.Vector4;

class NURBSUtils {

    static function findSpan(p:Int, u:Float, U:Array<Float>):Int {
        var n = U.length - p - 1;
        if (u >= U[n]) {
            return n - 1;
        }
        if (u <= U[p]) {
            return p;
        }
        var low = p;
        var high = n;
        var mid = Math.floor((low + high) / 2);
        while (u < U[mid] || u >= U[mid + 1]) {
            if (u < U[mid]) {
                high = mid;
            } else {
                low = mid;
            }
            mid = Math.floor((low + high) / 2);
        }
        return mid;
    }

    static function calcBasisFunctions(span:Int, u:Float, p:Int, U:Array<Float>):Array<Float> {
        var N = [];
        var left = [];
        var right = [];
        N[0] = 1.0;
        for (j in 1...p + 1) {
            left[j] = u - U[span + 1 - j];
            right[j] = U[span + j] - u;
            var saved = 0.0;
            for (r in 0...j) {
                var rv = right[r + 1];
                var lv = left[j - r];
                var temp = N[r] / (rv + lv);
                N[r] = saved + rv * temp;
                saved = lv * temp;
            }
            N[j] = saved;
        }
        return N;
    }

    static function calcBSplinePoint(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float):Vector4 {
        var span = findSpan(p, u, U);
        var N = calcBasisFunctions(span, u, p, U);
        var C = new Vector4(0, 0, 0, 0);
        for (j in 0...p + 1) {
            var point = P[span - p + j];
            var Nj = N[j];
            var wNj = point.w * Nj;
            C.x += point.x * wNj;
            C.y += point.y * wNj;
            C.z += point.z * wNj;
            C.w += point.w * Nj;
        }
        return C;
    }

    static function calcBasisFunctionDerivatives(span:Int, u:Float, p:Int, n:Int, U:Array<Float>):Array<Array<Float>> {
        var zeroArr = [];
        for (i in 0...p + 1)
            zeroArr[i] = 0.0;
        var ders = [];
        for (i in 0...n + 1)
            ders[i] = zeroArr.slice();
        var ndu = [];
        for (i in 0...p + 1)
            ndu[i] = zeroArr.slice();
        ndu[0][0] = 1.0;
        var left = zeroArr.slice();
        var right = zeroArr.slice();
        for (j in 1...p + 1) {
            left[j] = u - U[span + 1 - j];
            right[j] = U[span + j] - u;
            var saved = 0.0;
            for (r in 0...j) {
                var rv = right[r + 1];
                var lv = left[j - r];
                ndu[j][r] = rv + lv;
                var temp = ndu[r][j - 1] / ndu[j][r];
                ndu[r][j] = saved + rv * temp;
                saved = lv * temp;
            }
            ndu[j][j] = saved;
        }
        for (j in 0...p + 1) {
            ders[0][j] = ndu[j][p];
        }
        for (r in 0...p + 1) {
            var s1 = 0;
            var s2 = 1;
            var a = [];
            for (i in 0...p + 1) {
                a[i] = zeroArr.slice();
            }
            a[0][0] = 1.0;
            for (k in 1...n + 1) {
                var d = 0.0;
                var rk = r - k;
                var pk = p - k;
                if (r >= k) {
                    a[s2][0] = a[s1][0] / ndu[pk + 1][rk];
                    d = a[s2][0] * ndu[rk][pk];
                }
                var j1 = (rk >= -1) ? 1 : -rk;
                var j2 = (r - 1 <= pk) ? k - 1 : p - r;
                for (j in j1...j2 + 1) {
                    a[s2][j] = (a[s1][j] - a[s1][j - 1]) / ndu[pk + 1][rk + j];
                    d += a[s2][j] * ndu[rk + j][pk];
                }
                if (r <= pk) {
                    a[s2][k] = -a[s1][k - 1] / ndu[pk + 1][r];
                    d += a[s2][k] * ndu[r][pk];
                }
                ders[k][r] = d;
                var j = s1;
                s1 = s2;
                s2 = j;
            }
        }
        var r = p;
        for (k in 1...n + 1) {
            for (j in 0...p + 1) {
                ders[k][j] *= r;
            }
            r *= p - k;
        }
        return ders;
    }

    static function calcBSplineDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector4> {
        var du = (nd < p) ? nd : p;
        var CK = [];
        var span = findSpan(p, u, U);
        var nders = calcBasisFunctionDerivatives(span, u, p, du, U);
        var Pw = [];
        for (i in 0...P.length) {
            var point = P[i].clone();
            var w = point.w;
            point.x *= w;
            point.y *= w;
            point.z *= w;
            Pw[i] = point;
        }
        for (k in 0...nd + 1) {
            var point = Pw[span - p].clone().multiplyScalar(nders[k][0]);
            for (j in 1...p + 1) {
                point.add(Pw[span - p + j].clone().multiplyScalar(nders[k][j]));
            }
            CK[k] = point;
        }
        for (k in du + 1...nd + 1) {
            CK[k] = new Vector4(0, 0, 0, 0);
        }
        return CK;
    }

    static function calcKoverI(k:Int, i:Int):Float {
        var nom = 1;
        for (j in 2...k + 1) {
            nom *= j;
        }
        var denom = 1;
        for (j in 2...i + 1) {
            denom *= j;
        }
        for (j in 2...k - i + 1) {
            denom *= j;
        }
        return nom / denom;
    }

    static function calcRationalCurveDerivatives(Pders:Array<Vector4>):Array<Vector3> {
        var nd = Pders.length;
        var Aders = [];
        var wders = [];
        for (i in 0...nd) {
            var point = Pders[i];
            Aders[i] = new Vector3(point.x, point.y, point.z);
            wders[i] = point.w;
        }
        var CK = [];
        for (k in 0...nd) {
            var v = Aders[k].clone();
            for (i in 1...k + 1) {
                v.sub(CK[k - i].clone().multiplyScalar(calcKoverI(k, i) * wders[i]));
            }
            CK[k] = v.divideScalar(wders[0]);
        }
        return CK;
    }

    static function calcNURBSDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector3> {
        var Pders = calcBSplineDerivatives(p, U, P, u, nd);
        return calcRationalCurveDerivatives(Pders);
    }

    static function calcSurfacePoint(p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Array<Vector4>>, u:Float, v:Float, target:Vector3) {
        var uspan = findSpan(p, u, U);
        var vspan = findSpan(q, v, V);
        var Nu = calcBasisFunctions(uspan, u, p, U);
        var Nv = calcBasisFunctions(vspan, v, q, V);
        var temp = [];
        for (l in 0...q + 1) {
            temp[l] = new Vector4(0, 0, 0, 0);
            for (k in 0...p + 1) {
                var point = P[uspan - p + k][vspan - q + l].clone();
                var w = point.w;
                point.x *= w;
                point.y *= w;
                point.z *= w;
                temp[l].add(point.multiplyScalar(Nu[k]));
            }
        }
        var Sw = new Vector4(0, 0, 0, 0);
        for (l in 0...q + 1) {
            Sw.add(temp[l].multiplyScalar(Nv[l]));
        }
        Sw.divideScalar(Sw.w);
        target.set(Sw.x, Sw.y, Sw.z);
    }

    static function calcVolumePoint(p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Array<Array<Vector4>>>, u:Float, v:Float, w:Float, target:Vector3) {
        var uspan = findSpan(p, u, U);
        var vspan = findSpan(q, v, V);
        var wspan = findSpan(r, w, W);
        var Nu = calcBasisFunctions(uspan, u, p, U);
        var Nv = calcBasisFunctions(vspan, v, q, V);
        var Nw = calcBasisFunctions(wspan, w, r, W);
        var temp = [];
        for (m in 0...r + 1) {
            temp[m] = [];
            for (l in 0...q + 1) {
                temp[m][l] = new Vector4(0, 0, 0, 0);
                for (k in 0...p + 1) {
                    var point = P[uspan - p + k][vspan - q + l][wspan - r + m].clone();
                    var w = point.w;
                    point.x *= w;
                    point.y *= w;
                    point.z *= w;
                    temp[m][l].add(point.multiplyScalar(Nu[k]));
                }
            }
        }
        var Sw = new Vector4(0, 0, 0, 0);
        for (m in 0...r + 1) {
            for (l in 0...q + 1) {
                Sw.add(temp[m][l].multiplyScalar(Nw[m]).multiplyScalar(Nv[l]));
            }
        }
        Sw.divideScalar(Sw.w);
        target.set(Sw.x, Sw.y, Sw.z);
    }
}