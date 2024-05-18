package three.js.examples.jsm.libs;

/**
 * SurfaceNets in Haxe
 *
 * Written by Mikola Lysenko (C) 2012
 *
 * MIT License
 *
 * Based on: S.F. Gibson, 'Constrained Elastic Surface Nets'. (1998) MERL Tech Report.
 * from https://github.com/mikolalysenko/isosurface/tree/master
 */
class SurfaceNet {
    public static function surfaceNet(dims:Array<Int>, potential:Float->Float->Float->Float, bounds:Array<Array<Float>> = null):{positions:Array<Array<Float>>, cells:Array<Array<Int>>} {
        // Precompute edge table, like Paul Bourke does.
        // This saves a bit of time when computing the centroid of each boundary cell
        var cube_edges:Array<Int> = [for (i in 0...24) 0];
        var edge_table:Array<Int> = [for (i in 0...256) 0];
        {
            // Initialize the cube_edges table
            // This is just the vertex number of each cube
            var k:Int = 0;
            for (i in 0...8) {
                for (j in 1...5) {
                    var p:Int = i ^ j;
                    if (i <= p) {
                        cube_edges[k++] = i;
                        cube_edges[k++] = p;
                    }
                }
            }

            // Initialize the intersection table.
            //  This is a 2^(cube configuration) ->  2^(edge configuration) map
            //  There is one entry for each possible cube configuration, and the output is a 12-bit vector enumerating all edges crossing the 0-level.
            for (i in 0...256) {
                var em:Int = 0;
                for (j in 0...24) {
                    var a:Bool = (i & (1 << cube_edges[j])) != 0;
                    var b:Bool = (i & (1 << cube_edges[j + 1])) != 0;
                    em |= (a != b) ? (1 << (j >> 1)) : 0;
                }
                edge_table[i] = em;
            }
        }

        // Internal buffer, this may get resized at run time
        var buffer:Array<Int> = [for (i in 0...4096) 0];
        {
            for (i in 0...buffer.length) {
                buffer[i] = 0;
            }
        }

        if (bounds == null) {
            bounds = [[0, 0, 0], dims];
        }

        var scale:Array<Float> = [0, 0, 0];
        var shift:Array<Float> = [0, 0, 0];
        for (i in 0...3) {
            scale[i] = (bounds[1][i] - bounds[0][i]) / dims[i];
            shift[i] = bounds[0][i];
        }

        var vertices:Array<Array<Float>> = [];
        var faces:Array<Array<Int>> = [];
        var n:Int = 0;
        var x:Array<Int> = [0, 0, 0];
        var R:Array<Int> = [1, dims[0] + 1, (dims[0] + 1) * (dims[1] + 1)];
        var grid:Array<Float> = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        var buf_no:Int = 1;

        // Resize buffer if necessary
        if (R[2] * 2 > buffer.length) {
            var ol:Int = buffer.length;
            buffer.length = R[2] * 2;
            while (ol < buffer.length) {
                buffer[ol++] = 0;
            }
        }

        // March over the voxel grid
        for (x[2] = 0; x[2] < dims[2] - 1; ++x[2], n += dims[0], buf_no ^= 1, R[2] = -R[2]) {

            // m is the pointer into the buffer we are going to use.
            // This is slightly obtuse because haxe does not have good support for packed data structures, so we must use arrays :(
            // The contents of the buffer will be the indices of the vertices on the previous x/y slice of the volume
            var m:Int = 1 + (dims[0] + 1) * (1 + buf_no * (dims[1] + 1));

            for (x[1] = 0; x[1] < dims[1] - 1; ++x[1], ++n, m += 2) {
                for (x[0] = 0; x[0] < dims[0] - 1; ++x[0], ++n, ++m) {

                    // Read in 8 field values around this vertex and store them in an array
                    // Also calculate 8-bit mask, like in marching cubes, so we can speed up sign checks later
                    var mask:Int = 0;
                    var g:Int = 0;
                    for (k in 0...2) {
                        for (j in 0...2) {
                            for (i in 0...2) {
                                var p:Float = potential(
                                    scale[0] * (x[0] + i) + shift[0],
                                    scale[1] * (x[1] + j) + shift[1],
                                    scale[2] * (x[2] + k) + shift[2]
                                );
                                grid[g++] = p;
                                mask |= (p < 0) ? (1 << g) : 0;
                            }
                        }
                    }

                    // Check for early termination if cell does not intersect boundary
                    if (mask === 0 || mask === 0xff) {
                        continue;
                    }

                    // Sum up edge intersections
                    var edge_mask:Int = edge_table[mask];
                    var v:Array<Float> = [0.0, 0.0, 0.0];
                    var e_count:Int = 0;

                    // For every edge of the cube...
                    for (i in 0...12) {

                        // Use edge mask to check if it is crossed
                        if (!(edge_mask & (1 << i))) {
                            continue;
                        }

                        // If it did, increment number of edge crossings
                        ++e_count;

                        // Now find the point of intersection
                        var e0:Int = cube_edges[i << 1];
                        var e1:Int = cube_edges[(i << 1) + 1];
                        var g0:Float = grid[e0];
                        var g1:Float = grid[e1];
                        var t:Float = g0 - g1; // Compute point of intersection
                        if (Math.abs(t) > 1e-6) {
                            t = g0 / t;
                        } else {
                            continue;
                        }

                        // Interpolate vertices and add up intersections (this can be done without multiplying)
                        for (j in 0...3) {
                            var a:Bool = (e0 & (1 << j)) != 0;
                            var b:Bool = (e1 & (1 << j)) != 0;
                            if (a != b) {
                                v[j] += a ? 1.0 - t : t;
                            } else {
                                v[j] += a ? 1.0 : 0;
                            }
                        }
                    }

                    // Now we just average the edge intersections and add them to coordinate
                    var s:Float = 1.0 / e_count;
                    for (i in 0...3) {
                        v[i] = scale[i] * (x[i] + s * v[i]) + shift[i];
                    }

                    // Add vertex to buffer, store pointer to vertex index in buffer
                    buffer[m] = vertices.length;
                    vertices.push(v);

                    // Now we need to add faces together, to do this we just loop over 3 basis components
                    for (i in 0...3) {

                        // The first three entries of the edge_mask count the crossings along the edge
                        if (!(edge_mask & (1 << i))) {
                            continue;
                        }

                        // i = axes we are point along.  iu, iv = orthogonal axes
                        var iu:Int = (i + 1) % 3;
                        var iv:Int = (i + 2) % 3;

                        // If we are on a boundary, skip it
                        if (x[iu] === 0 || x[iv] === 0) {
                            continue;
                        }

                        // Otherwise, look up adjacent edges in buffer
                        var du:Int = R[iu];
                        var dv:Int = R[iv];

                        // Remember to flip orientation depending on the sign of the corner.
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

            // All done!  Return the result
            return {positions: vertices, cells: faces};
        }
    }
}