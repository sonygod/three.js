import three.Vector3;
import three.Vector4;

class NURBSUtils {
    static public function findSpan(p:Int, u:Float, U:Array<Float>):Int {
        var n:Int = U.length - p - 1;

        if (u >= U[n]) {
            return n - 1;
        }

        if (u <= U[p]) {
            return p;
        }

        var low:Int = p;
        var high:Int = n;
        var mid:Int = Std.int((low + high) / 2);

        while (u < U[mid] || u >= U[mid + 1]) {
            if (u < U[mid]) {
                high = mid;
            } else {
                low = mid;
            }

            mid = Std.int((low + high) / 2);
        }

        return mid;
    }

    static public function calcBasisFunctions(span:Int, u:Float, p:Int, U:Array<Float>):Array<Float> {
        var N:Array<Float> = [];
        var left:Array<Float> = [];
        var right:Array<Float> = [];
        N[0] = 1.0;

        for (var j:Int = 1; j <= p; ++j) {
            left[j] = u - U[span + 1 - j];
            right[j] = U[span + j] - u;

            var saved:Float = 0.0;

            for (var r:Int = 0; r < j; ++r) {
                var rv:Float = right[r + 1];
                var lv:Float = left[j - r];
                var temp:Float = N[r] / (rv + lv);
                N[r] = saved + rv * temp;
                saved = lv * temp;
            }

            N[j] = saved;
        }

        return N;
    }

    static public function calcBSplinePoint(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float):Vector4 {
        var span:Int = findSpan(p, u, U);
        var N:Array<Float> = calcBasisFunctions(span, u, p, U);
        var C:Vector4 = new Vector4(0, 0, 0, 0);

        for (var j:Int = 0; j <= p; ++j) {
            var point:Vector4 = P[span - p + j];
            var Nj:Float = N[j];
            var wNj:Float = point.w * Nj;
            C.x += point.x * wNj;
            C.y += point.y * wNj;
            C.z += point.z * wNj;
            C.w += point.w * Nj;
        }

        return C;
    }

    static public function calcBasisFunctionDerivatives(span:Int, u:Float, p:Int, n:Int, U:Array<Float>):Array<Array<Float>> {
        var zeroArr:Array<Float> = [];
        for (var i:Int = 0; i <= p; ++i)
            zeroArr[i] = 0.0;

        var ders:Array<Array<Float>> = [];

        for (var i:Int = 0; i <= n; ++i)
            ders[i] = zeroArr.slice(0);

        var ndu:Array<Array<Float>> = [];

        for (var i:Int = 0; i <= p; ++i)
            ndu[i] = zeroArr.slice(0);

        ndu[0][0] = 1.0;

        var left:Array<Float> = zeroArr.slice(0);
        var right:Array<Float> = zeroArr.slice(0);

        for (var j:Int = 1; j <= p; ++j) {
            left[j] = u - U[span + 1 - j];
            right[j] = U[span + j] - u;

            var saved:Float = 0.0;

            for (var r:Int = 0; r < j; ++r) {
                var rv:Float = right[r + 1];
                var lv:Float = left[j - r];
                ndu[j][r] = rv + lv;

                var temp:Float = ndu[r][j - 1] / ndu[j][r];
                ndu[r][j] = saved + rv * temp;
                saved = lv * temp;
            }

            ndu[j][j] = saved;
        }

        for (var j:Int = 0; j <= p; ++j) {
            ders[0][j] = ndu[j][p];
        }

        for (var r:Int = 0; r <= p; ++r) {
            var s1:Int = 0;
            var s2:Int = 1;

            var a:Array<Array<Float>> = [];
            for (var i:Int = 0; i <= p; ++i) {
                a[i] = zeroArr.slice(0);
            }

            a[0][0] = 1.0;

            for (var k:Int = 1; k <= n; ++k) {
                var d:Float = 0.0;
                var rk:Int = r - k;
                var pk:Int = p - k;

                if (r >= k) {
                    a[s2][0] = a[s1][0] / ndu[pk + 1][rk];
                    d = a[s2][0] * ndu[rk][pk];
                }

                var j1:Int = (rk >= -1) ? 1 : -rk;
                var j2:Int = (r - 1 <= pk) ? k - 1 : p - r;

                for (var j:Int = j1; j <= j2; ++j) {
                    a[s2][j] = (a[s1][j] - a[s1][j - 1]) / ndu[pk + 1][rk + j];
                    d += a[s2][j] * ndu[rk + j][pk];
                }

                if (r <= pk) {
                    a[s2][k] = -a[s1][k - 1] / ndu[pk + 1][r];
                    d += a[s2][k] * ndu[r][pk];
                }

                ders[k][r] = d;

                var j:Int = s1;
                s1 = s2;
                s2 = j;
            }
        }

        var r:Int = p;

        for (var k:Int = 1; k <= n; ++k) {
            for (var j:Int = 0; j <= p; ++j) {
                ders[k][j] *= r;
            }

            r *= p - k;
        }

        return ders;
    }

    static public function calcBSplineDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector4> {
        var du:Int = nd < p ? nd : p;
        var CK:Array<Vector4> = [];
        var span:Int = findSpan(p, u, U);
        var nders:Array<Array<Float>> = calcBasisFunctionDerivatives(span, u, p, du, U);
        var Pw:Array<Vector4> = [];

        for (var i:Int = 0; i < P.length; ++i) {
            var point:Vector4 = P[i].clone();
            var w:Float = point.w;

            point.x *= w;
            point.y *= w;
            point.z *= w;

            Pw[i] = point;
        }

        for (var k:Int = 0; k <= du; ++k) {
            var point:Vector4 = Pw[span - p].clone().multiplyScalar(nders[k][0]);

            for (var j:Int = 1; j <= p; ++j) {
                point.add(Pw[span - p + j].clone().multiplyScalar(nders[k][j]));
            }

            CK[k] = point;
        }

        for (var k:Int = du + 1; k <= nd + 1; ++k) {
            CK[k] = new Vector4(0, 0, 0);
        }

        return CK;
    }

    static public function calcKoverI(k:Int, i:Int):Float {
        var nom:Float = 1;

        for (var j:Int = 2; j <= k; ++j) {
            nom *= j;
        }

        var denom:Float = 1;

        for (var j:Int = 2; j <= i; ++j) {
            denom *= j;
        }

        for (var j:Int = 2; j <= k - i; ++j) {
            denom *= j;
        }

        return nom / denom;
    }

    static public function calcRationalCurveDerivatives(Pders:Array<Vector4>):Array<Vector3> {
        var nd:Int = Pders.length;
        var Aders:Array<Vector3> = [];
        var wders:Array<Float> = [];

        for (var i:Int = 0; i < nd; ++i) {
            var point:Vector4 = Pders[i];
            Aders[i] = new Vector3(point.x, point.y, point.z);
            wders[i] = point.w;
        }

        var CK:Array<Vector3> = [];

        for (var k:Int = 0; k < nd; ++k) {
            var v:Vector3 = Aders[k].clone();

            for (var i:Int = 1; i <= k; ++i) {
                v.sub(CK[k - i].clone().multiplyScalar(calcKoverI(k, i) * wders[i]));
            }

            CK[k] = v.divideScalar(wders[0]);
        }

        return CK;
    }

    static public function calcNURBSDerivatives(p:Int, U:Array<Float>, P:Array<Vector4>, u:Float, nd:Int):Array<Vector3> {
        var Pders:Array<Vector4> = calcBSplineDerivatives(p, U, P, u, nd);
        return calcRationalCurveDerivatives(Pders);
    }

    static public function calcSurfacePoint(p:Int, q:Int, U:Array<Float>, V:Array<Float>, P:Array<Array<Vector4>>, u:Float, v:Float, target:Vector3):Void {
        var uspan:Int = findSpan(p, u, U);
        var vspan:Int = findSpan(q, v, V);
        var Nu:Array<Float> = calcBasisFunctions(uspan, u, p, U);
        var Nv:Array<Float> = calcBasisFunctions(vspan, v, q, V);
        var temp:Array<Vector4> = [];

        for (var l:Int = 0; l <= q; ++l) {
            temp[l] = new Vector4(0, 0, 0, 0);
            for (var k:Int = 0; k <= p; ++k) {
                var point:Vector4 = P[uspan - p + k][vspan - q + l].clone();
                var w:Float = point.w;
                point.x *= w;
                point.y *= w;
                point.z *= w;
                temp[l].add(point.multiplyScalar(Nu[k]));
            }
        }

        var Sw:Vector4 = new Vector4(0, 0, 0, 0);
        for (var l:Int = 0; l <= q; ++l) {
            Sw.add(temp[l].multiplyScalar(Nv[l]));
        }

        Sw.divideScalar(Sw.w);
        target.set(Sw.x, Sw.y, Sw.z);
    }

    static public function calcVolumePoint(p:Int, q:Int, r:Int, U:Array<Float>, V:Array<Float>, W:Array<Float>, P:Array<Array<Array<Vector4>>>, u:Float, v:Float, w:Float, target:Vector3):Void {
        var uspan:Int = findSpan(p, u, U);
        var vspan:Int = findSpan(q, v, V);
        var wspan:Int = findSpan(r, w, W);
        var Nu:Array<Float> = calcBasisFunctions(uspan, u, p, U);
        var Nv:Array<Float> = calcBasisFunctions(vspan, v, q, V);
        var Nw:Array<Float> = calcBasisFunctions(wspan, w, r, W);
        var temp:Array<Array<Vector4>> = [];

        for (var m:Int = 0; m <= r; ++m) {
            temp[m] = [];

            for (var l:Int = 0; l <= q; ++l) {
                temp[m][l] = new Vector4(0, 0, 0, 0);
                for (var k:Int = 0; k <= p; ++k) {
                    var point:Vector4 = P[uspan - p + k][vspan - q + l][wspan - r + m].clone();
                    var w:Float = point.w;
                    point.x *= w;
                    point.y *= w;
                    point.z *= w;
                    temp[m][l].add(point.multiplyScalar(Nu[k]));
                }
            }
        }
        var Sw:Vector4 = new Vector4(0, 0, 0, 0);
        for (var m:Int = 0; m <= r; ++m) {
            for (var l:Int = 0; l <= q; ++l) {
                Sw.add(temp[m][l].multiplyScalar(Nw[m]).multiplyScalar(Nv[l]));
            }
        }

        Sw.divideScalar(Sw.w);
        target.set(Sw.x, Sw.y, Sw.z);
    }
}