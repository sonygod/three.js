Here is the converted Haxe code:
```
package three.js.examples.jsm.objects;

import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DynamicDrawUsage;
import three.Mesh;
import three.Sphere;
import three.Vector3;

class MarchingCubes extends Mesh {
    public var isMarchingCubes:Bool = true;

    public function new(resolution:Int, material:Material, enableUvs:Bool = false, enableColors:Bool = false, maxPolyCount:Int = 10000) {
        super(new BufferGeometry(), material);

        init(resolution);
    }

    private var vlist:Array<Float> = new Array<Float>();
    private var nlist:Array<Float> = new Array<Float>();
    private var clist:Array<Float> = new Array<Float>();

    private var enableUvs:Bool;
    private var enableColors:Bool;

    private function init(resolution:Int):Void {
        this.resolution = resolution;

        isolation = 80.0;
        size = resolution;
        size2 = size * size;
        size3 = size2 * size;
        halfsize = size / 2.0;

        delta = 2.0 / size;
        yd = size;
        zd = size2;

        field = new Array<Float>(size3);
        normal_cache = new Array<Float>(size3 * 3);
        palette = new Array<Float>(size3 * 3);

        count = 0;

        maxVertexCount = maxPolyCount * 3;

        positionArray = new Array<Float>(maxVertexCount * 3);
        var positionAttribute = new BufferAttribute(positionArray, 3);
        positionAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute('position', positionAttribute);

        normalArray = new Array<Float>(maxVertexCount * 3);
        var normalAttribute = new BufferAttribute(normalArray, 3);
        normalAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute('normal', normalAttribute);

        if (enableUvs) {
            uvArray = new Array<Float>(maxVertexCount * 2);
            var uvAttribute = new BufferAttribute(uvArray, 2);
            uvAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute('uv', uvAttribute);
        }

        if (enableColors) {
            colorArray = new Array<Float>(maxVertexCount * 3);
            var colorAttribute = new BufferAttribute(colorArray, 3);
            colorAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute('color', colorAttribute);
        }

        geometry.boundingSphere = new Sphere(new Vector3(), 1);
    }

    private function lerp(a:Float, b:Float, t:Float):Float {
        return a + (b - a) * t;
    }

    private function VIntX(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        var mu:Float = (isol - valp1) / (valp2 - valp1);
        vlist[offset + 0] = x + mu * delta;
        vlist[offset + 1] = y;
        vlist[offset + 2] = z;

        nlist[offset + 0] = lerp(normal_cache[q + 0], normal_cache[q + 3], mu);
        nlist[offset + 1] = lerp(normal_cache[q + 1], normal_cache[q + 4], mu);
        nlist[offset + 2] = lerp(normal_cache[q + 2], normal_cache[q + 5], mu);

        clist[offset + 0] = lerp(palette[c_offset1 * 3 + 0], palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = lerp(palette[c_offset1 * 3 + 1], palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = lerp(palette[c_offset1 * 3 + 2], palette[c_offset2 * 3 + 2], mu);
    }

    private function VIntY(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        var mu:Float = (isol - valp1) / (valp2 - valp1);
        vlist[offset + 0] = x;
        vlist[offset + 1] = y + mu * delta;
        vlist[offset + 2] = z;

        const q2:Int = q + yd * 3;
        nlist[offset + 0] = lerp(normal_cache[q + 0], normal_cache[q2 + 0], mu);
        nlist[offset + 1] = lerp(normal_cache[q + 1], normal_cache[q2 + 1], mu);
        nlist[offset + 2] = lerp(normal_cache[q + 2], normal_cache[q2 + 2], mu);

        clist[offset + 0] = lerp(palette[c_offset1 * 3 + 0], palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = lerp(palette[c_offset1 * 3 + 1], palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = lerp(palette[c_offset1 * 3 + 2], palette[c_offset2 * 3 + 2], mu);
    }

    private function VIntZ(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        var mu:Float = (isol - valp1) / (valp2 - valp1);
        vlist[offset + 0] = x;
        vlist[offset + 1] = y;
        vlist[offset + 2] = z + mu * delta;

        const q2:Int = q + zd * 3;
        nlist[offset + 0] = lerp(normal_cache[q + 0], normal_cache[q2 + 0], mu);
        nlist[offset + 1] = lerp(normal_cache[q + 1], normal_cache[q2 + 1], mu);
        nlist[offset + 2] = lerp(normal_cache[q + 2], normal_cache[q2 + 2], mu);

        clist[offset + 0] = lerp(palette[c_offset1 * 3 + 0], palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = lerp(palette[c_offset1 * 3 + 1], palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = lerp(palette[c_offset1 * 3 + 2], palette[c_offset2 * 3 + 2], mu);
    }

    private function compNorm(q:Int):Void {
        const q3:Int = q * 3;
        if (normal_cache[q3] == 0.0) {
            normal_cache[q3 + 0] = field[q - 1] - field[q + 1];
            normal_cache[q3 + 1] = field[q - yd] - field[q + yd];
            normal_cache[q3 + 2] = field[q - zd] - field[q + zd];
        }
    }

    private function polygonize(fx:Float, fy:Float, fz:Float, q:Int, isol:Float):Int {
        // cache indices
        const q1:Int = q + 1,
            qy:Int = q + yd,
            qz:Int = q + zd,
            q1y:Int = q1 + yd,
            q1z:Int = q1 + zd,
            qyz:Int = q + yd + zd,
            q1yz:Int = q1 + yd + zd;

        var cubeindex:Int = 0;
        const field0:Float = field[q],
            field1:Float = field[q1],
            field2:Float = field[qy],
            field3:Float = field[q1y],
            field4:Float = field[qz],
            field5:Float = field[q1z],
            field6:Float = field[qyz],
            field7:Float = field[q1yz];

        if (field0 < isol) cubeindex |= 1;
        if (field1 < isol) cubeindex |= 2;
        if (field2 < isol) cubeindex |= 8;
        if (field3 < isol) cubeindex |= 4;
        if (field4 < isol) cubeindex |= 16;
        if (field5 < isol) cubeindex |= 32;
        if (field6 < isol) cubeindex |= 128;
        if (field7 < isol) cubeindex |= 64;

        // if cube is entirely in/out of the surface - bail, nothing to draw
        if (edgeTable[cubeindex] == 0) return 0;

        const d:Float = delta,
            fx2:Float = fx + d,
            fy2:Float = fy + d,
            fz2:Float = fz + d;

        // top of the cube
        if (edgeTable[cubeindex] & 1) {
            compNorm(q);
            compNorm(q1);
            VIntX(q * 3, 0, isol, fx, fy, fz, field0, field1, q, q1);
        }

        if (edgeTable[cubeindex] & 2) {
            compNorm(q1);
            compNorm(q1y);
            VIntY(q1 * 3, 3, isol, fx2, fy, fz, field1, field3, q1, q1y);
        }

        if (edgeTable[cubeindex] & 4) {
            compNorm(qy);
            compNorm(q1y);
            VIntX(qy * 3, 6, isol, fx, fy2, fz, field2, field3, qy, q1y);
        }

        if (edgeTable[cubeindex] & 8) {
            compNorm(q);
            compNorm(qy);
            VIntY(q * 3, 9, isol, fx, fy, fz, field0, field2, q, qy);
        }

        // bottom of the cube
        if (edgeTable[cubeindex] & 16) {
            compNorm(qz);
            compNorm(q1z);
            VIntX(qz * 3, 12, isol, fx, fy, fz2, field4, field5, qz, q1z);
        }

        if (edgeTable[cubeindex] & 32) {
            compNorm(q1z);
            compNorm(q1yz);
            VIntY(q1z * 3, 15, isol, fx2, fy, fz2, field5, field7, q1z, q1yz);
        }

        if (edgeTable[cubeindex] & 64) {
            compNorm(qyz);
            compNorm(q1yz);
            VIntX(qyz * 3, 18, isol, fx, fy2, fz2, field6, field7, qyz, q1yz);
        }

        if (edgeTable[cubeindex] & 128) {
            compNorm(qz);
            compNorm(qyz);
            VIntY(qz * 3, 21, isol, fx, fy, fz2, field4, field6, qz, qyz);
        }

        // vertical lines of the cube
        if (edgeTable[cubeindex] & 256) {
            compNorm(q);
            compNorm(qz);
            VIntZ(q * 3, 24, isol, fx, fy, fz, field0, field4, q, qz);
        }

        if (edgeTable[cubeindex] & 512) {
            compNorm(q1);
            compNorm(q1z);
            VIntZ(q1 * 3, 27, isol, fx2, fy, fz, field1, field5, q1, q1z);
        }

        if (edgeTable[cubeindex] & 1024) {
            compNorm(q1y);
            compNorm(q1yz);
            VIntZ(q1y * 3, 30, isol, fx2, fy2, fz, field3, field7, q1y, q1yz);
        }

        if (edgeTable[cubeindex] & 2048) {
            compNorm(qy);
            compNorm(qyz);
            VIntZ(qy * 3, 33, isol, fx, fy2, fz, field2, field6, qy, qyz);
        }

        cubeindex <<= 4; // re-purpose cubeindex into an offset into triTable

        var o1:Int, o2:Int, o3:Int, numtris:Int = 0, i:Int = 0;

        while (triTable[cubeindex + i] != -1) {
            o1 = cubeindex + i;
            o2 = o1 + 1;
            o3 = o1 + 2;

            posnormtriv(vlist, nlist, clist, 3 * triTable[o1], 3 * triTable[o2], 3 * triTable[o3]);

            i += 3;
            numtris++;
        }

        return numtris;
    }

    private function posnormtriv(pos:Array<Float>, norm:Array<Float>, colors:Array<Float>, o1:Int, o2:Int, o3:Int):Void {
        const c:Int = count * 3;

        pos[c + 0] = vlist[o1];
        pos[c + 1] = vlist[o1 + 1];
        pos[c + 2] = vlist[o1 + 2];

        pos[c + 3] = vlist[o2];
        pos[c + 4] = vlist[o2 + 1];
        pos[c + 5] = vlist[o2 + 2];

        pos[c + 6] = vlist[o3];
        pos[c + 7] = vlist[o3 + 1];
        pos[c + 8] = vlist[o3 + 2];

        // normals
        if (material.flatShading) {
            const nx:Float = (norm[o1 + 0] + norm[o2 + 0] + norm[o3 + 0]) / 3;
            const ny:Float = (norm[o1 + 1] + norm[o2 + 1] + norm[o3 + 1]) / 3;
            const nz:Float = (norm[o1 + 2] + norm[o2 + 2] + norm[o3 + 2]) / 3;

            normalArray[c + 0] = nx;
            normalArray[c + 1] = ny;
            normalArray[c + 2] = nz;

            normalArray[c + 3] = nx;
            normalArray[c + 4] = ny;
            normalArray[c + 5] = nz;

            normalArray[c + 6] = nx;
            normalArray[c + 7] = ny;
            normalArray[c + 8] = nz;

        } else {
            normalArray[c + 0] = norm[o1 + 0];
            normalArray[c + 1] = norm[o1 + 1];
            normalArray[c + 2] = norm[o1 + 2];

            normalArray[c + 3] = norm[o2 + 0];
            normalArray[c + 4] = norm[o2 + 1];
            normalArray[c + 5] = norm[o2 + 2];

            normalArray[c + 6] = norm[o3 + 0];
            normalArray[c + 7] = norm[o3 + 1];
            normalArray[c + 8] = norm[o3 + 2];
        }

        // uvs
        if (enableUvs) {
            const d:Int = count * 2;

            uvArray[d + 0] = pos[o1];
            uvArray[d + 1] = pos[o1 + 2];

            uvArray[d + 2] = pos[o2];
            uvArray[d + 3] = pos[o2 + 2];

            uvArray[d + 4] = pos[o3];
            uvArray[d + 5] = pos[o3 + 2];
        }

        // colors
        if (enableColors) {
            colorArray[c + 0] = colors[o1 + 0];
            colorArray[c + 1] = colors[o1 + 1];
            colorArray[c + 2] = colors[o1 + 2];

            colorArray[c + 3] = colors[o2 + 0];
            colorArray[c + 4] = colors[o2 + 1];
            colorArray[c + 5] = colors[o2 + 2];

            colorArray[c + 6] = colors[o3 + 0];
            color