import h3d.Mesh;
import h3d.BufferAttribute;
import h3d.BufferGeometry;
import h3d.Color;
import h3d.DynamicDrawUsage;
import h3d.Sphere;
import h3d.Vector3;

class MarchingCubes extends Mesh {
    public var enableUvs:Bool;
    public var enableColors:Bool;
    public var resolution:Int;
    public var maxPolyCount:Int;
    public var positionArray:Float32Array;
    public var normalArray:Float32Array;
    public var uvArray:Float32Array;
    public var colorArray:Float32Array;
    public var field:Float32Array;
    public var normal_cache:Float32Array;
    public var palette:Float32Array;
    public var count:Int;
    public var size:Int;
    public var size2:Int;
    public var size3:Int;
    public var halfsize:Int;
    public var delta:Float;
    public var yd:Int;
    public var zd:Int;
    public var isolation:Float;
    public var vlist:Float32Array;
    public var nlist:Float32Array;
    public var clist:Float32Array;
    public var scope:MarchingCubes;

    public function new(resolution:Int, material:Dynamic, enableUvs:Bool = false, enableColors:Bool = false, maxPolyCount:Int = 10000) {
        super(new BufferGeometry(), material);
        this.enableUvs = enableUvs;
        this.enableColors = enableColors;
        this.init(resolution);
        this.isMarchingCubes = true;

        this.scope = this;

        // temp buffers used in polygonize
        vlist = new Float32Array(12 * 3);
        nlist = new Float32Array(12 * 3);
        clist = new Float32Array(12 * 3);

        // parameters
        this.isolation = 80.0;

        // size of field, 32 is pushing it in Javascript :)
        this.size = resolution;
        this.size2 = this.size * this.size;
        this.size3 = this.size2 * this.size;
        this.halfsize = this.size / 2.0;

        // deltas
        this.delta = 2.0 / this.size;
        this.yd = this.size;
        this.zd = this.size2;

        this.field = new Float32Array(this.size3);
        this.normal_cache = new Float32Array(this.size3 * 3);
        this.palette = new Float32Array(this.size3 * 3);

        //

        this.count = 0;

        const maxVertexCount = maxPolyCount * 3;

        this.positionArray = new Float32Array(maxVertexCount * 3);
        var positionAttribute = new BufferAttribute(this.positionArray, 3);
        positionAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute("position", positionAttribute);

        this.normalArray = new Float32Array(maxVertexCount * 3);
        var normalAttribute = new BufferAttribute(this.normalArray, 3);
        normalAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute("normal", normalAttribute);

        if (this.enableUvs) {
            this.uvArray = new Float32Array(maxVertexCount * 2);
            var uvAttribute = new BufferAttribute(this.uvArray, 2);
            uvAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute("uv", uvAttribute);
        }

        if (this.enableColors) {
            this.colorArray = new Float32Array(maxVertexCount * 3);
            var colorAttribute = new BufferAttribute(this.colorArray, 3);
            colorAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute("color", colorAttribute);
        }

        geometry.boundingSphere = new Sphere(new Vector3(), 1);
    }

    public function init(resolution:Int):Void {
        this.resolution = resolution;

        // parameters

        this.isolation = 80.0;

        // size of field, 32 is pushing it in Javascript :)

        this.size = resolution;
        this.size2 = this.size * this.size;
        this.size3 = this.size2 * this.size;
        this.halfsize = this.size / 2.0;

        // deltas

        this.delta = 2.0 / this.size;
        this.yd = this.size;
        this.zd = this.size2;

        this.field = new Float32Array(this.size3);
        this.normal_cache = new Float32Array(this.size3 * 3);
        this.palette = new Float32Array(this.size3 * 3);

        //

        this.count = 0;

        const maxVertexCount = maxPolyCount * 3;

        this.positionArray = new Float32Array(maxVertexCount * 3);
        var positionAttribute = new BufferAttribute(this.positionArray, 3);
        positionAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute("position", positionAttribute);

        this.normalArray = new Float32Array(maxVertexCount * 3);
        var normalAttribute = new BufferAttribute(this.normalArray, 3);
        normalAttribute.setUsage(DynamicDrawUsage);
        geometry.setAttribute("normal", normalAttribute);

        if (this.enableUvs) {
            this.uvArray = new Float32Array(maxVertexCount * 2);
            var uvAttribute = new BufferAttribute(this.uvArray, 2);
            uvAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute("uv", uvAttribute);
        }

        if (this.enableColors) {
            this.colorArray = new Float32Array(maxVertexCount * 3);
            var colorAttribute = new BufferAttribute(this.colorArray, 3);
            colorAttribute.setUsage(DynamicDrawUsage);
            geometry.setAttribute("color", colorAttribute);
        }

        geometry.boundingSphere = new Sphere(new Vector3(), 1);
    }

    public function lerp(a:Float, b:Float, t:Float):Float {
        return a + (b - a) * t;
    }

    public function VIntX(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        const mu = (isol - valp1) / (valp2 - valp1);
        const nc = this.normal_cache;

        vlist[offset + 0] = x + mu * this.delta;
        vlist[offset + 1] = y;
        vlist[offset + 2] = z;

        nlist[offset + 0] = this.lerp(nc[q + 0], nc[q + 3], mu);
        nlist[offset + 1] = this.lerp(nc[q + 1], nc[q + 4], mu);
        nlist[offset + 2] = this.lerp(nc[q + 2], nc[q + 5], mu);

        clist[offset + 0] = this.lerp(this.palette[c_offset1 * 3 + 0], this.palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = this.lerp(this.palette[c_offset1 * 3 + 1], this.palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = this.lerp(this.palette[c_offset1 * 3 + 2], this.palette[c_offset2 * 3 + 2], mu);
    }

    public function VIntY(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        const mu = (isol - valp1) / (valp2 - valp1);
        const nc = this.normal_cache;

        vlist[offset + 0] = x;
        vlist[offset + 1] = y + mu * this.delta;
        vlist[offset + 2] = z;

        const q2 = q + this.yd * 3;

        nlist[offset + 0] = this.lerp(nc[q + 0], nc[q2 + 0], mu);
        nlist[offset + 1] = this.lerp(nc[q + 1], nc[q2 + 1], mu);
        nlist[offset + 2] = this.lerp(nc[q + 2], nc[q2 + 2], mu);

        clist[offset + 0] = this.lerp(this.palette[c_offset1 * 3 + 0], this.palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = this.lerp(this.palette[c_offset1 * 3 + 1], this.palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = this.lerp(this.palette[c_offset1 * 3 + 2], this.palette[c_offset2 * 3 + 2], mu);
    }

    public function VIntZ(q:Int, offset:Int, isol:Float, x:Float, y:Float, z:Float, valp1:Float, valp2:Float, c_offset1:Int, c_offset2:Int):Void {
        const mu = (isol - valp1) / (valp2 - valp1);
        const nc = this.normal_cache;

        vlist[offset + 0] = x;
        vlist[offset + 1] = y;
        vlist[offset + 2] = z + mu * this.delta;

        const q2 = q + this.zd * 3;

        nlist[offset + 0] = this.lerp(nc[q + 0], nc[q2 + 0], mu);
        nlist[offset + 1] = this.lerp(nc[q + 1], nc[q2 + 1], mu);
        nlist[offset + 2] = this.lerp(nc[q + 2], nc[q2 + 2], mu);

        clist[offset + 0] = this.lerp(this.palette[c_offset1 * 3 + 0], this.palette[c_offset2 * 3 + 0], mu);
        clist[offset + 1] = this.lerp(this.palette[c_offset1 * 3 + 1], this.palette[c_offset2 * 3 + 1], mu);
        clist[offset + 2] = this.lerp(this.palette[c_offset1 * 3 + 2], this.palette[c_offset2 * 3 + 2], mu);
    }

    public function compNorm(q:Int):Void {
        const q3 = q * 3;

        if (this.normal_cache[q3] == 0.0) {
            this.normal_cache[q3 + 0] = this.field[q - 1] - this.field[q + 1];
            this.normal_cache[q3 + 1] = this.field[q - this.yd] - this.field[q + this.yd];
            this.normal_cache[q3 + 2] = this.field[q - this.zd] - this.field[q + this.zd];
        }
    }

    public function polygonize(fx:Float, fy:Float, fz:Float, q:Int, isol:Float):Int {
        // cache indices
        const q1 = q + 1;
        const qy = q + this.yd;
        const qz = q + this.zd;
        const q1y = q1 + this.yd;
        const q1z = q1 + this.zd;
        const qyz = q + this.yd + this.zd;
        const q1yz = q1 + this.yd + this.zd;

        var cubeindex = 0;
        const field0 = this.field[q];
        const field1 = this.field[q1];
        const field2 = this.field[qy];
        const field3 = this.field[q1y];
        const field4 = this.field[qz];
        const field5 = this.field[q1z];
        const field6 = this.field[qyz];
        const field7 = this.field[q1yz];

        if (field0 < isol) cubeindex |= 1;
        if (field1 < isol) cubeindex |= 2;
        if (field2 < isol) cubeindex |= 8;
        if (field3 < isol) cubeindex |= 4;
        if (field4 < isol) cubeindex |= 16;
        if (field5 < isol) cubeindex |= 32;
        if (field6 < isol) cubeindex |= 128;
        if (field7 < isol) cubeindex |= 64;

        // if cube is entirely in/out of the surface - bail, nothing to draw

        const bits = edgeTable[cubeindex];
        if (bits == 0) return 0;

        const d = this.delta;
        const fx2 = fx + d;
        const fy2 = fy + d;
        const fz2 = fz + d;

        // top of the cube

        if (bits & 1) {
            this.compNorm(q);
            this.compNorm(q1);
            this.VIntX(q * 3, 0, isol, fx, fy, fz, field0, field1, q, q1);
        }

        if (bits & 2) {
            this.compNorm(q1);
            this.compNorm(q1y);
            this.VIntY(q1 * 3, 3, isol, fx2, fy, fz, field1, field3, q1, q1y);
        }

        if (bits & 4) {
            this.compNorm(qy);
            this.compNorm(q1y);
            this.VIntX(qy * 3, 6, isol, fx, fy2, fz, field2, field3, qy, q1y);
        }

        if (bits & 8) {
            this.compNorm(q);
            this.compNorm(qy);
            this.VIntY(q * 3, 9, isol, fx, fy, fz, field0, field2, q, qy);
        }

        // bottom of the cube

        if (bits & 16) {
            this.compNorm(qz);
            this.compNorm(q1z);
            this.VIntX(qz * 3, 12, isol, fx, fy, fz2, field4, field5, qz, q1z);
        }

        if (bits & 32) {
            this.compNorm(q1z);
            this.compNorm(q1yz);
            this.VIntY(q1z * 3, 15, isol, fx2, fy, fz2, field5, field7, q1z, q1yz);
        }

        if (bits & 64) {
            this.compNorm(qyz);
            this.compNorm(q1yz);
            this.VIntX(qyz * 3, 18, isol, fx, fy2, fz2, field6, field7, qyz, q1yz);
        }

        if (bits & 128) {
            this.compNorm(qz);
            this.compNorm(qyz);
            this.VIntY(qz * 3, 21, isol, fx, fy2, fz2, field4, field6, qz, qyz);
        }

        // vertical lines of the cube
        if (bits & 256) {
            this.compNorm(q);
            this.compNorm(qz);
            this.VIntZ(q * 3, 24, isol, fx, fy, fz, field0, field4, q, qz);
        }

        if (bits & 512) {
            this.compNorm(q1);
            this.compNorm(q1z);
            this.VIntZ(q1 * 3, 27, isol, fx2, fy, fz, field1, field5, q1, q1z);
        }

        if (bits & 1024) {
            this.compNorm(q1y);
            this.compNorm(q1yz);
            this.VIntZ(q1y * 3, 30, isol, fx2, fy2, fz, field3, field7, q1y, q1yz);
        }

        if (bits & 2048) {
            this.compNorm(qy);
            this.compNorm(qyz);
            this.VIntZ(qy * 3, 33, isol, fx, fy2, fz, field2, field6, qy, qyz);
        }

        cubeindex <<= 4; // re-purpose cubeindex into an offset into triTable

        var o