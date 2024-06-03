import js.Array;
import js.Math;
import js.Boot;

class SurfaceNet {
    static function surfaceNet(dims: Array<Int>, potential: Function, bounds: Array<Array<Float>> = null): Dynamic {
        var cube_edges = new js.lib.Int32Array(24);
        var edge_table = new js.lib.Int32Array(256);

        var k = 0;
        for(var i = 0; i < 8; ++i) {
            for(var j = 1; j <= 4; j <<= 1) {
                var p = i ^ j;
                if(i <= p) {
                    cube_edges[k++] = i;
                    cube_edges[k++] = p;
                }
            }
        }

        for(var i = 0; i < 256; ++i) {
            var em = 0;
            for(var j = 0; j < 24; j += 2) {
                var a = (i & (1 << cube_edges[j])) != 0;
                var b = (i & (1 << cube_edges[j + 1])) != 0;
                em |= a != b ? (1 << (j >> 1)) : 0;
            }
            edge_table[i] = em;
        }

        var buffer = Array<Int>();
        for(var i = 0; i < 4096; ++i) {
            buffer.push(0);
        }

        if(bounds == null) {
            bounds = [ [0.0, 0.0, 0.0], [dims[0].toFloat(), dims[1].toFloat(), dims[2].toFloat()] ];
        }

        var scale = [0.0, 0.0, 0.0];
        var shift = [0.0, 0.0, 0.0];
        for(var i = 0; i < 3; ++i) {
            scale[i] = (bounds[1][i] - bounds[0][i]) / dims[i];
            shift[i] = bounds[0][i];
        }

        var vertices = Array<Array<Float>>();
        var faces = Array<Array<Int>>();
        var n = 0;
        var x = [0, 0, 0];
        var R = [1, (dims[0] + 1), (dims[0] + 1) * (dims[1] + 1)];
        var grid = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        var buf_no = 1;

        if(R[2] * 2 > buffer.length) {
            var ol = buffer.length;
            buffer.length = R[2] * 2;
            while(ol < buffer.length) {
                buffer[ol++] = 0;
            }
        }

        for(x[2] = 0; x[2] < dims[2] - 1; ++x[2], n += dims[0], buf_no ^= 1, R[2] = -R[2]) {
            var m = 1 + (dims[0] + 1) * (1 + buf_no * (dims[1] + 1));

            for(x[1] = 0; x[1] < dims[1] - 1; ++x[1], ++n, m += 2)
            for(x[0] = 0; x[0] < dims[0] - 1; ++x[0], ++n, ++m) {
                var mask = 0;
                var g = 0;
                for(var k = 0; k < 2; ++k)
                for(var j = 0; j < 2; ++j)
                for(var i = 0; i < 2; ++i, ++g) {
                    var p = potential(
                        scale[0] * (x[0] + i) + shift[0],
                        scale[1] * (x[1] + j) + shift[1],
                        scale[2] * (x[2] + k) + shift[2]);
                    grid[g] = p;
                    mask |= (p < 0) ? (1 << g) : 0;
                }

                if(mask == 0 || mask == 0xff) {
                    continue;
                }

                var edge_mask = edge_table[mask];
                var v = [0.0, 0.0, 0.0];
                var e_count = 0;

                for(var i = 0; i < 12; ++i) {
                    if((edge_mask & (1 << i)) == 0) {
                        continue;
                    }

                    ++e_count;

                    var e0 = cube_edges[i << 1];
                    var e1 = cube_edges[(i << 1) + 1];
                    var g0 = grid[e0];
                    var g1 = grid[e1];
                    var t = g0 - g1;
                    if(Math.abs(t) > 1e-6) {
                        t = g0 / t;
                    } else {
                        continue;
                    }

                    for(var j = 0, k = 1; j < 3; ++j, k <<= 1) {
                        var a = e0 & k;
                        var b = e1 & k;
                        if(a != b) {
                            v[j] += a != 0 ? 1.0 - t : t;
                        } else {
                            v[j] += a != 0 ? 1.0 : 0;
                        }
                    }
                }

                var s = 1.0 / e_count;
                for(var i = 0; i < 3; ++i) {
                    v[i] = scale[i] * (x[i] + s * v[i]) + shift[i];
                }

                buffer[m] = vertices.length;
                vertices.push(v);

                for(var i = 0; i < 3; ++i) {
                    if((edge_mask & (1 << i)) == 0) {
                        continue;
                    }

                    var iu = (i + 1) % 3;
                    var iv = (i + 2) % 3;

                    if(x[iu] == 0 || x[iv] == 0) {
                        continue;
                    }

                    var du = R[iu];
                    var dv = R[iv];

                    if(mask & 1) {
                        faces.push([buffer[m], buffer[m - du], buffer[m - dv]]);
                        faces.push([buffer[m - dv], buffer[m - du], buffer[m - du - dv]]);
                    } else {
                        faces.push([buffer[m], buffer[m - dv], buffer[m - du]]);
                        faces.push([buffer[m - du], buffer[m - dv], buffer[m - du - dv]]);
                    }
                }
            }
        }

        return { positions: vertices, cells: faces };
    }
}