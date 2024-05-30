/**
 * Octahedron and Quantization encodings based on work by:
 *
 * @link https://github.com/tsherif/mesh-quantization-example
 *
 */

import js.three.BufferAttribute;
import js.three.Matrix3;
import js.three.Matrix4;
import js.three.Vector3;
import js.three.PackedPhongMaterial;

/**
 * Make the input mesh.geometry's normal attribute encoded and compressed by 3 different methods.
 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the normal data.
 *
 * @param {js.three.Mesh} mesh
 * @param {String} encodeMethod		"DEFAULT" || "OCT1Byte" || "OCT2Byte" || "ANGLES"
 *
 */
function compressNormals(mesh: js.three.Mesh, encodeMethod: String) {
    if (mesh.geometry == null) {
        trace("Mesh must contain geometry. ");
    }

    var normal = mesh.geometry.attributes.normal;

    if (normal == null) {
        trace("Geometry must contain normal attribute. ");
    }

    if (normal.isPacked) {
        return;
    }

    if (normal.itemSize != 3) {
        trace("normal.itemSize is not 3, which cannot be encoded. ");
    }

    var array = normal.array;
    var count = normal.count;

    var result: Dynamic<js.Uint8Array|js.Int8Array|js.Int16Array>;
    if (encodeMethod == "DEFAULT") {
        // TODO: Add 1 byte to the result, making the encoded length to be 4 bytes.
        result = new js.Uint8Array(count * 3);

        var idx = 0;
        while (idx < array.length) {
            var encoded = defaultEncode(array[idx], array[idx + 1], array[idx + 2], 1);

            result[idx + 0] = encoded[0];
            result[idx + 1] = encoded[1];
            result[idx + 2] = encoded[2];

            idx += 3;
        }

        mesh.geometry.setAttribute("normal", new BufferAttribute(result, 3, true));
        mesh.geometry.attributes.normal.bytes = Std.int(result.length) * 1;
    } else if (encodeMethod == "OCT1Byte") {
        /**
        * It is not recommended to use 1-byte octahedron normals encoding unless you want to extremely reduce the memory usage
        * As it makes vertex data not aligned to a 4 byte boundary which may harm some WebGL implementations and sometimes the normal distortion is visible
        * Please refer to @zeux 's comments in https://github.com/mrdoob/three.js/pull/18208
        */

        result = new js.Int8Array(count * 2);

        var idx = 0;
        while (idx < array.length) {
            var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 1);

            result[idx / 3 * 2 + 0] = encoded[0];
            result[idx / 3 * 2 + 1] = encoded[1];

            idx += 3;
        }

        mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
        mesh.geometry.attributes.normal.bytes = Std.int(result.length) * 1;
    } else if (encodeMethod == "OCT2Byte") {
        result = new js.Int16Array(count * 2);

        var idx = 0;
        while (idx < array.length) {
            var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 2);

            result[idx / 3 * 2 + 0] = encoded[0];
            result[idx / 3 * 2 + 1] = encoded[1];

            idx += 3;
        }

        mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
        mesh.geometry.attributes.normal.bytes = Std.int(result.length) * 2;
    } else if (encodeMethod == "ANGLES") {
        result = new js.Uint16Array(count * 2);

        var idx = 0;
        while (idx < array.length) {
            var encoded = anglesEncode(array[idx], array[idx + 1], array[idx + 2]);

            result[idx / 3 * 2 + 0] = encoded[0];
            result[idx / 3 * 2 + 1] = encoded[1];

            idx += 3;
        }

        mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
        mesh.geometry.attributes.normal.bytes = Std.int(result.length) * 2;
    } else {
        trace("Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`. ");
    }

    mesh.geometry.attributes.normal.needsUpdate = true;
    mesh.geometry.attributes.normal.isPacked = true;
    mesh.geometry.attributes.normal.packingMethod = encodeMethod;

    // modify material
    if (!(mesh.material instanceof PackedPhongMaterial)) {
        mesh.material = new PackedPhongMaterial().copy(mesh.material);
    }

    if (encodeMethod == "ANGLES") {
        mesh.material.defines.USE_PACKED_NORMAL = 0;
    }

    if (encodeMethod == "OCT1Byte") {
        mesh.material.defines.USE_PACKED_NORMAL = 1;
    }

    if (encodeMethod == "OCT2Byte") {
        mesh.material.defines.USE_PACKED_NORMAL = 1;
    }

    if (encodeMethod == "DEFAULT") {
        mesh.material.defines.USE_PACKED_NORMAL = 2;
    }
}


/**
 * Make the input mesh.geometry's position attribute encoded and compressed.
 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the position data.
 *
 * @param {js.three.Mesh} mesh
 *
 */
function compressPositions(mesh: js.three.Mesh) {
    if (mesh.geometry == null) {
        trace("Mesh must contain geometry. ");
    }

    var position = mesh.geometry.attributes.position;

    if (position == null) {
        trace("Geometry must contain position attribute. ");
    }

    if (position.isPacked) {
        return;
    }

    if (position.itemSize != 3) {
        trace("position.itemSize is not 3, which cannot be packed. ");
    }

    var array = position.array;
    var encodingBytes = 2;

    var result = quantizedEncode(array, encodingBytes);

    var quantized = result.quantized;
    var decodeMat = result.decodeMat;

    // IMPORTANT: calculate original geometry bounding info first, before updating packed positions
    if (mesh.geometry.boundingBox == null) {
        mesh.geometry.computeBoundingBox();
    }

    if (mesh.geometry.boundingSphere == null) {
        mesh.geometry.computeBoundingSphere();
    }

    mesh.geometry.setAttribute("position", new BufferAttribute(quantized, 3));
    mesh.geometry.attributes.position.isPacked = true;
    mesh.geometry.attributes.position.needsUpdate = true;
    mesh.geometry.attributes.position.bytes = Std.int(quantized.length) * encodingBytes;

    // modify material
    if (!(mesh.material instanceof PackedPhongMaterial)) {
        mesh.material = new PackedPhongMaterial().copy(mesh.material);
    }

    mesh.material.defines.USE_PACKED_POSITION = 0;

    mesh.material.uniforms.quantizeMatPos.value = decodeMat;
    mesh.material.uniforms.quantizeMatPos.needsUpdate = true;
}

/**
 * Make the input mesh.geometry's uv attribute encoded and compressed.
 * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the uv data.
 *
 * @param {js.three.Mesh} mesh
 *
 */
function compressUvs(mesh: js.three.Mesh) {
    if (mesh.geometry == null) {
        trace("Mesh must contain geometry property. ");
    }

    var uvs = mesh.geometry.attributes.uv;

    if (uvs == null) {
        trace("Geometry must contain uv attribute. ");
    }

    if (uvs.isPacked) {
        return;
    }

    var range = { min: Infinity, max: -Infinity };

    var array = uvs.array;

    var i = 0;
    while (i < array.length) {
        range.min = Math.min(range.min, array[i]);
        range.max = Math.max(range.max, array[i]);

        i += 1;
    }

    var result: Dynamic<js.Uint16Array|js.Dynamic>;

    if (range.min >= -1.0 && range.max <= 1.0) {
        // use default encoding method
        result = new js.Uint16Array(array.length);

        var i = 0;
        while (i < array.length) {
            var encoded = defaultEncode(array[i], array[i + 1], 0, 2);

            result[i] = encoded[0];
            result[i + 1] = encoded[1];

            i += 2;
        }

        mesh.geometry.setAttribute("uv", new BufferAttribute(result, 2, true));
        mesh.geometry.attributes.uv.isPacked = true;
        mesh.geometry.attributes.uv.needsUpdate = true;
        mesh.geometry.attributes.uv.bytes = Std.int(result.length) * 2;

        if (!(mesh.material instanceof PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        mesh.material.defines.USE_PACKED_UV = 0;
    } else {
        // use quantized encoding method
        result = quantizedEncodeUV(array, 2);

        mesh.geometry.setAttribute("uv", new BufferAttribute(result.quantized, 2));
        mesh.geometry.attributes.uv.isPacked = true;
        mesh.geometry.attributes.uv.needsUpdate = true;
        mesh.geometry.attributes.uv.bytes = Std.int(result.quantized.length) * 2;

        if (!(mesh.material instanceof PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        mesh.material.defines.USE_PACKED_UV = 1;

        mesh.material.uniforms.quantizeMatUV.value = result.decodeMat;
        mesh.material.uniforms.quantizeMatUV.needsUpdate = true;
    }
}


// Encoding functions

function defaultEncode(x: Float, y: Float, z: Float, bytes: Int) {
    if (bytes == 1) {
        var tmpx = Std.int(Math.round((x + 1) * 0.5 * 255));
        var tmpy = Std.int(Math.round((y + 1) * 0.5 * 255));
        var tmpz = Std.int(Math.round((z + 1) * 0.5 * 255));
        return new js.Uint8Array([tmpx, tmpy, tmpz]);
    } else if (bytes == 2) {
        var tmpx = Std.int(Math.round((x + 1) * 0.5 * 65535));
        var tmpy = Std.int(Math.round((y + 1) * 0.5 * 65535));
        var tmpz = Std.int(Math.round((z + 1) * 0.5 * 65535));
        return new js.Uint16Array([tmpx, tmpy, tmpz]);
    } else {
        trace("number of bytes must be 1 or 2");
    }
}

// for `Angles` encoding
function anglesEncode(x: Float, y: Float, z: Float) {
    var normal0 = Std.int(0.5 * (1.0 + Math.atan2(y, x) / Math.PI) * 65535);
    var normal1 = Std.int(0.5 * (1.0 + z) * 65535);
    return new js.Uint16Array([normal0, normal1]);
}

// for `Octahedron` encoding
function octEncodeBest(x: Float, y: Float, z: Float, bytes: Int) {
    var oct: Dynamic<js.Int8Array|js.Int16Array>;
    var dec: Float[];
    var best: Dynamic<js.Int8Array|js.Int16Array>;
    var currentCos: Float;
    var bestCos: Float;

    // Test various combinations of ceil and floor
    // to minimize rounding errors
    best = oct = octEncodeVec3(x, y, z, "floor", "floor");
    dec = octDecodeVec2(oct);
    bestCos = dot(x, y, z, dec);

    oct = octEncodeVec3(x, y, z, "ceil", "floor");
    dec = octDecodeVec2(oct);
    currentCos = dot(x, y, z, dec);

    if (currentCos > bestCos) {
        best = oct;
        bestCos = currentCos;
    }

    oct = octEncodeVec3(x, y, z, "floor", "ceil");
    dec = octDecodeVec2(oct);
    currentCos = dot(x, y, z, dec);

    if (currentCos > bestCos) {
        best = oct;
        bestCos = currentCos;
    }

    oct = octEncodeVec3(x, y, z, "ceil", "ceil");
    dec = octDecodeVec2(oct);
    currentCos = dot(x, y, z, dec);

    if (currentCos > bestCos) {
        best = oct;
    }

    return best;

    function octEncodeVec3(x0: Float, y0: Float, z0: Float, xfunc: String, yfunc: String) {
        var x = x0 / (Math.abs(x0) + Math.abs(y0) + Math.abs(z0));
        var y = y0 / (Math.abs(x0) + Math.abs(y0) + Math.abs(z0));

        if (z < 0) {
            var tempx = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
            var tempy = (1 - Math.abs(x)) * (y >= 0 ? 1 : -1);

            x = tempx;
            y = tempy;

            var diff = 1 - Math.abs(x) - Math.abs(y);
            if (diff > 0) {
                diff += 0.001;
                x += x > 0 ? diff / 2 : -diff / 2;
                y += y > 0 ? diff / 2 : -diff / 2;
            }
        }

        if (bytes == 1) {
            return new js.Int8Array([
                Math[xfunc](x * 127.5 + (x < 0 ? 1 : 0)),
                Math[yfunc](y * 127.5 + (y < 0 ? 1 : 0))
            ]);
        }

        if (bytes == 2) {
            return new js.Int16Array([
                Math[xfunc](x * 32767.5 + (x < 0 ? 1 : 0)),
                Math[yfunc](y * 32767.5 + (y < 0 ? 1 : 0))
            ]);
        }
    }

    function octDecodeVec2(oct: Dynamic<js.Int8Array|js.Int16Array>) {
        var x = oct[0];
        var y = oct[1];

        if (bytes == 1) {
            x /= x < 0 ? 127 : 128;
            y /= y < 0 ? 127 : 128;
        } else if (bytes == 2) {
            x /= x < 0 ? 32767 : 32768;
            y /= y < 0 ? 32767 : 32768;
        }

        var z = 1 - Math.abs(x) - Math.abs(y);

        if (z < 0) {
            var tmpx = x;
            x = (1 - Math.abs(y)) * (x >= 0 ? 1 : -1);
            y = (1 - Math.abs(tmpx)) * (y >= 0 ? 1 : -1);
        }

        var length = Math.sqrt(x * x + y * y + z * z);

        return [
            x / length,
            y / length,
            z / length
        ];
    }

    function dot(x: Float, y: Float, z: Float, vec3: Float[]) {
        return x * vec3[0] + y * vec3[1] + z * vec3[2];
    }
}

function quantizedEncode(array: Float[], bytes: Int) {
    var quantized: Dynamic<js.Uint8Array|js.Uint16Array>;
    var segments: Int;

    if (bytes == 1) {
        quantized = new js.Uint8haseArray(array.length);
        segments = 255;
    } else if (bytes == 2) {
        quantized = new js.Uint16Array(array.length);
        segments = 65535;
    } else {
        trace("number of bytes error! ");
    }

    var decodeMat = new Matrix4();

    var min = new Float32Array(3);
    var max = new Float32Array(3);

    min[0] = min[1] = min[2] = Number.MAX_VALUE;
    max[0] = max[1] = max[2] = -Number.MAX_VALUE;

    var i = 0;
    while (i < array.length) {
        min[0] = Math.min(min[0], array[i + 0]);
        min[1] = Math.min(min[1], array[i + 1]);
        min[2] = Math.min(min[2], array[i + 2]);
        max[0] = Math.max(max[0], array[i + 0]);
        max[1] = Math.max(max[1], array[i + 1]);
        max[2] = Math.max(max[2], array[i + 2]);

        i += 3;
    }

    decodeMat.scale(new Vector3(
        (max[0] - min[0]) / segments,
        (max[1] - min[1]) / segments,
        (max[2] - min[2]) / segments
    ));

    decodeMat.elements[12] = min[0];
    decodeMat.elements[13] = min[1];
    decodeMat.elements[14] = min[2];

    decodeMat.transpose();

    var multiplier = new Float32Array([
        max[0] !== min[0] ? segments / (max[0] - min[0]) : 0,
        max[1] !== min[1] ? segments / (max[1] - min[1]) : 0,
        max[2] !== min[2] ? segments / (max[2] - min[2]) : 0
    ]);

    var i = 0;
    while (i < array.length) {
        quantized[i + 0] = Std.int(Math.floor((array[i + 0] - min[0]) * multiplier[0]));
        quantized[i + 1] = Std.int(Math.floor((array[i + 1] - min[1]) * multiplier[1]));
        quantized[i + 2] = Std.int(Math.floor((array[i + 2] - min[2]) * multiplier[2]));

        i += 3;
    }

    return {
        quantized: quantized,
        decodeMat: decodeMat
    };
}

function quantizedEncodeUV(array: Float[], bytes: Int) {
    var quantized: Dynamic<js.Uint8Array|js.Uint16Array>;
    var segments: Int;

    if (bytes == 1) {
        quantized = new js.Uint8Array(array.length);
        segments = 255;
    } else if (bytes == 2) {
        quantized = new js.Uint16Array(array.length);
        segments = 65535;
    } else {
        trace("number of bytes error! ");
    }

    var decodeMat = new Matrix3();

    var min = new Float32Array(2);
    var max = new Float32Array(2);

    min[0] = min[1] = Number.MAX_VALUE;
    max[0] = max[1] = -Number.MAX_VALUE;

    var i = 0;
    while (i < array.length) {
        min[0] = Math.min(min[0], array[i + 0]);
        min[1] = Math.min(min[1], array[i + 1]);
        max[0] = Math.max(max[0], array[i + 0]);
        max[1] = Math.max(max[1], array[i + 1]);

        i += 2;
    }

    decodeMat.scale(
        (max[0] - min[0]) / segments,
        (max[1] - min[1]) / segments
    );

    decodeMat.elements[6] = min[0];
    decodeMat.elements[7] = min[1];

    decodeMat.transpose();

    var multiplier = new Float32Array([
        max[0] !== min[0] ? segments / (max[0] - min[0]) : 0,
        max[1] !== min[1] ? segments / (max[1] - min[1]) : 0
    ]);

    var i = 0;
    while (i < array.length) {
        quantized[i + 0] = Std.int(Math.floor((array[i + 0] - min[0]) * multiplier[0]));
        quantized[i + 1] = Std.int(Math.floor((array[i + 1] - min[1]) * multiplier[1]));

        i += 2;
    }

    return {
        quantized: quantized,
        decodeMat: decodeMat
    };
}

class NormalCompressor {
    public static function compressNormals(mesh: js.three.Mesh, encodeMethod: String) {
        compressNormals(mesh, encodeMethod);
    }

    public static function compressPositions(mesh: js.three.Mesh) {
        compressPositions(mesh);
    }

    public static function compressUvs(mesh: js.three.Mesh) {
        compressUvs(mesh);
    }
}