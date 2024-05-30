/**
 * SurfaceNets in Haxe
 *
 * Written by Mikola Lysenko (C) 2012
 *
 * MIT License
 *
 * Based on: S.F. Gibson, 'Constrained Elastic Surface Nets'. (1998) MERL Tech Report.
 * from https://github.com/mikolalysenko/isosurface/tree/master
 *
 */

function surfaceNet(dims:Int[], potential:F32Function3, bounds:F32Array3):SurfaceNet {
    //Precompute edge table, like Paul Bourke does.
    // This saves a bit of time when computing the centroid of each boundary cell
    var cube_edges = [0, 1, 1, 3, 1, 2, 2, 3, 0, 2, 0, 3];
    var edge_table = new IntArray(256);
    {
        //Initialize the intersection table.
        //  This is a 2^(cube configuration) ->  2^(edge configuration) map
        //  There is one entry for each possible cube configuration, and the output is a 12-bit vector enumerating all edges crossing the 0-level.
        for (i in 0...256) {
            var em = 0;
            for (j in 0...24) {
                var a = (i >> cube_edges[j]) & 1;
                var b = (i >> cube_edges[j + 1]) & 1;
                em |= (a != b) ? (1 << (j >> 1)) : 0;
            }
            edge_table[i] = em;
        }
    }

    //Internal buffer, this may get resized at run time
    var buffer = new IntArray(4096);
    {
        for (i in 0...buffer.length) {
            buffer[i] = 0;
        }
    }

    if (bounds == null) {
        bounds = [[0, 0, 0], dims];
    }

    var scale = [0, 0, 0];
    var shift = [0, 0, 0];
    for (i in 0...3) {
        scale[i] = (bounds[1][i] - bounds[0][i]) / dims[i];
        shift[i] = bounds[0][i];
    }

    var vertices = [];
    var faces = [];
    var n = 0;
    var x = [0, 0, 0];
    var R = [1, (dims[0] + 1), (dims[0] + 1) * (dims[1] + 1)];
    var grid = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    var buf_no = 1;

    //Resize buffer if necessary
    if (R[2] * 2 > buffer.length) {
        var ol = buffer.length;
        buffer.length = R[2] * 2;
        while (ol < buffer.length) {
            buffer[ol++] = 0;
        }
    }

    //March over the voxel grid
    for (x[2] = 0; x[2] < dims[2] - 1; ++x[2], n += dims[0], buf_no ^= 1, R[2] = -R[2]) {
        //m is the pointer into the buffer we are going to use.
        //This is slightly obtuse because javascript does not have good support for packed data structures, so we must use typed arrays :(
        //The contents of the buffer will be the indices of the vertices on the previous x/y slice of the volume
        var m = 1 + (dims[0] + 1) * (1 + buf_no * (dims[1] + 1));

        for (x[1] = 0; x[1] < dims[1] - 1; ++x[1], ++n, m += 2) {
            for (x[0] = 0; x[0] < dims[0] - 1; ++x[0], ++n, ++m) {
                //Read in 8 field values around this vertex and store them in an array
                //Also calculate 8-bit mask, like in marching cubes, so we can speed up sign checks later
                var mask = 0;
                var g = 0;
                for (k in 0...2) {
                    for (j in 0...2) {
                        for (i in 0...2) {
                            var p = potential(scale[0] * (x[0] + i) + shift[0], scale[1] * (x[1] + j) + shift[1], scale[2] * (x[2] + k) + shift[2]);
                            grid[g] = p;
                            mask |= (p < 0) ? (1 << g) : 0;
                            ++g;
                        }
                    }
                }

                //Check for early termination if cell does not intersect boundary
                if (mask == 0 || mask == 0xff) {
                    continue;
                }

                //Sum up edge intersections
                var edge_mask = edge_table[mask];
                var v = [0.0, 0.0, 0.0];
                var e_count = 0;

                //For every edge of the cube...
                for (i in 0...12) {
                    //Use edge mask to check if it is crossed
                    if ((edge_mask & (1 << i)) == 0) {
                        continue;
                    }

                    //If it did, increment number of edge crossings
                    ++e_count;

                    //Now find the point of intersection
                    var e0 = cube_edges[i << 1];
                    var e1 = cube_edges[(i << 1) + 1];
                    var g0 = grid[e0];
                    var g1 = grid[e1];
                    var t = g0 - g1;

                    //Compute point of intersection
                    if (Math.abs(t) > 1e-6) {
                        t = g0 / t;
                    } else {
                        continue;
                    }

                    //Interpolate vertices and add up intersections (this can be done without multiplying)
                    for (j = 0, k = 1; j < 3; ++j, k <<= 1) {
                        var a = e0 & k;
                        var b = e1 & k;
                        if (a != b) {
                            v[j] += a ? 1.0 - t : t;
                        } else {
                            v[j] += a ? 1.0 : 0;
                        }
                    }
                }

                //Now we just average the edge intersections and add them to coordinate
                var s = 1.0 / e_count;
                for (i in 0...3) {
                    v[i] = scale[i] * (x[i] + s * v[i]) + shift[i];
                }

                //Add vertex to buffer, store pointer to vertex index in buffer
                buffer[m] = vertices.length;
                vertices.push(v);

                //Now we need to add faces together, to do this we just loop over 3 basis components
                for (i in 0...3) {
                    //The first three entries of the edge_mask count the crossings along the edge
                    if ((edge_mask & (1 << i)) == 0) {
                        continue;
                    }

                    // i = axes we are point along.  iu, iv = orthogonal axes
                    var iu = (i + 1) % 3;
                    var iv = (i + 2) % 3;

                    //If we are on a boundary, skip it
                    if (x[iu] == 0 || x[iv] == 0) {
                        continue;
                    }

                    //Otherwise, look up adjacent edges in buffer
                    var du = R[iu];
                    var dv = R[iv];

                    //Remember to flip orientation depending on the sign of the corner.
                    if ((mask & 1) != 0) {
                        faces.push([buffer[m], buffer[m - du], buffer[m - dv]]);
                        faces.push([buffer[m - dv], buffer[m - du], buffer[m - du - dv]]);
                    } else {
                        faces.push([buffer[m], buffer[m - dv], buffer[m - du]]);
                        faces.push([buffer[m - du], buffer[m - dv], buffer[m - du - dv]]);
                    }
                }
            }
        }
    }

    //All done!  Return the result
    return { positions: vertices, cells: faces };
}

typedef SurfaceNet = {
    positions: F32Array2,
    cells: IntArray2
}

typedef F32Function3 = @:autoBuild @:autoBuildCache Function<(x:F32, y:F32, z:F32)->F32>;

typedef F32Array3 = Array<Array<Array<F32>>>;