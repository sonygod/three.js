import three.js.examples.jsm.utils.PackedPhongMaterial;
import three.js.examples.jsm.utils.GeometryCompressionUtils;

class Main {
    static function main() {
        var mesh = new three.Mesh();
        var encodeMethod = "DEFAULT";

        GeometryCompressionUtils.compressNormals(mesh, encodeMethod);
        GeometryCompressionUtils.compressPositions(mesh);
        GeometryCompressionUtils.compressUvs(mesh);
    }
}

class GeometryCompressionUtils {
    public static function compressNormals(mesh:three.Mesh, encodeMethod:String) {
        if (!mesh.geometry) {
            trace("Mesh must contain geometry.");
        }

        var normal = mesh.geometry.attributes.normal;

        if (!normal) {
            trace("Geometry must contain normal attribute.");
        }

        if (normal.isPacked) return;

        if (normal.itemSize != 3) {
            trace("normal.itemSize is not 3, which cannot be encoded.");
        }

        var array = normal.array;
        var count = normal.count;

        var result;
        if (encodeMethod == "DEFAULT") {
            result = new Uint8Array(count * 3);

            for (idx in 0...array.length by 3) {
                var encoded = defaultEncode(array[idx], array[idx + 1], array[idx + 2], 1);

                result[idx + 0] = encoded[0];
                result[idx + 1] = encoded[1];
                result[idx + 2] = encoded[2];
            }

            mesh.geometry.setAttribute("normal", new three.BufferAttribute(result, 3, true));
            mesh.geometry.attributes.normal.bytes = result.length * 1;

        } else if (encodeMethod == "OCT1Byte") {
            result = new Int8Array(count * 2);

            for (idx in 0...array.length by 3) {
                var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 1);

                result[idx / 3 * 2 + 0] = encoded[0];
                result[idx / 3 * 2 + 1] = encoded[1];
            }

            mesh.geometry.setAttribute("normal", new three.BufferAttribute(result, 2, true));
            mesh.geometry.attributes.normal.bytes = result.length * 1;

        } else if (encodeMethod == "OCT2Byte") {
            result = new Int16Array(count * 2);

            for (idx in 0...array.length by 3) {
                var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 2);

                result[idx / 3 * 2 + 0] = encoded[0];
                result[idx / 3 * 2 + 1] = encoded[1];
            }

            mesh.geometry.setAttribute("normal", new three.BufferAttribute(result, 2, true));
            mesh.geometry.attributes.normal.bytes = result.length * 2;

        } else if (encodeMethod == "ANGLES") {
            result = new Uint16Array(count * 2);

            for (idx in 0...array.length by 3) {
                var encoded = anglesEncode(array[idx], array[idx + 1], array[idx + 2]);

                result[idx / 3 * 2 + 0] = encoded[0];
                result[idx / 3 * 2 + 1] = encoded[1];
            }

            mesh.geometry.setAttribute("normal", new three.BufferAttribute(result, 2, true));
            mesh.geometry.attributes.normal.bytes = result.length * 2;

        } else {
            trace("Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`.");
        }

        mesh.geometry.attributes.normal.needsUpdate = true;
        mesh.geometry.attributes.normal.isPacked = true;
        mesh.geometry.attributes.normal.packingMethod = encodeMethod;

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

    public static function compressPositions(mesh:three.Mesh) {
        if (!mesh.geometry) {
            trace("Mesh must contain geometry.");
        }

        var position = mesh.geometry.attributes.position;

        if (!position) {
            trace("Geometry must contain position attribute.");
        }

        if (position.isPacked) return;

        if (position.itemSize != 3) {
            trace("position.itemSize is not 3, which cannot be packed.");
        }

        var array = position.array;
        var encodingBytes = 2;

        var result = quantizedEncode(array, encodingBytes);

        var quantized = result.quantized;
        var decodeMat = result.decodeMat;

        // IMPORTANT: calculate original geometry bounding info first, before updating packed positions
        if (mesh.geometry.boundingBox == null) mesh.geometry.computeBoundingBox();
        if (mesh.geometry.boundingSphere == null) mesh.geometry.computeBoundingSphere();

        mesh.geometry.setAttribute("position", new three.BufferAttribute(quantized, 3));
        mesh.geometry.attributes.position.isPacked = true;
        mesh.geometry.attributes.position.needsUpdate = true;
        mesh.geometry.attributes.position.bytes = quantized.length * encodingBytes;

        if (!(mesh.material instanceof PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        mesh.material.defines.USE_PACKED_POSITION = 0;

        mesh.material.uniforms.quantizeMatPos.value = decodeMat;
        mesh.material.uniforms.quantizeMatPos.needsUpdate = true;
    }

    public static function compressUvs(mesh:three.Mesh) {
        if (!mesh.geometry) {
            trace("Mesh must contain geometry property.");
        }

        var uvs = mesh.geometry.attributes.uv;

        if (!uvs) {
            trace("Geometry must contain uv attribute.");
        }

        if (uvs.isPacked) return;

        var range = { min: Infinity, max: -Infinity };

        var array = uvs.array;

        for (i in 0...array.length) {
            range.min = Math.min(range.min, array[i]);
            range.max = Math.max(range.max, array[i]);
        }

        var result;

        if (range.min >= -1.0 && range.max <= 1.0) {
            result = new Uint16Array(array.length);

            for (i in 0...array.length by 2) {
                var encoded = defaultEncode(array[i], array[i + 1], 0, 2);

                result[i] = encoded[0];
                result[i + 1] = encoded[1];
            }

            mesh.geometry.setAttribute("uv", new three.BufferAttribute(result, 2, true));
            mesh.geometry.attributes.uv.isPacked = true;
            mesh.geometry.attributes.uv.needsUpdate = true;
            mesh.geometry.attributes.uv.bytes = result.length * 2;

            if (!(mesh.material instanceof PackedPhongMaterial)) {
                mesh.material = new PackedPhongMaterial().copy(mesh.material);
            }

            mesh.material.defines.USE_PACKED_UV = 0;

        } else {
            result = quantizedEncodeUV(array, 2);

            mesh.geometry.setAttribute("uv", new three.BufferAttribute(result.quantized, 2));
            mesh.geometry.attributes.uv.isPacked = true;
            mesh.geometry.attributes.uv.needsUpdate = true;
            mesh.geometry.attributes.uv.bytes = result.quantized.length * 2;

            if (!(mesh.material instanceof PackedPhongMaterial)) {
                mesh.material = new PackedPhongMaterial().copy(mesh.material);
            }

            mesh.material.defines.USE_PACKED_UV = 1;

            mesh.material.uniforms.quantizeMatUV.value = result.decodeMat;
            mesh.material.uniforms.quantizeMatUV.needsUpdate = true;
        }
    }

    // Encoding functions

    private static function defaultEncode(x:Float, y:Float, z:Float, bytes:Int) {
        if (bytes == 1) {
            var tmpx = Math.round((x + 1) * 0.5 * 255);
            var tmpy = Math.round((y + 1) * 0.5 * 255);
            var tmpz = Math.round((z + 1) * 0.5 * 255);
            return new Uint8Array([tmpx, tmpy, tmpz]);

        } else if (bytes == 2) {
            var tmpx = Math.round((x + 1) * 0.5 * 65535);
            var tmpy = Math.round((y + 1) * 0.5 * 65535);
            var tmpz = Math.round((z + 1) * 0.5 * 65535);
            return new Uint16Array([tmpx, tmpy, tmpz]);

        } else {
            trace("number of bytes must be 1 or 2");
        }
    }

    // for `Angles` encoding
    private static function anglesEncode(x:Float, y:Float, z:Float) {
        var normal0 = parseInt(0.5 * (1.0 + Math.atan2(y, x) / Math.PI) * 65535);
        var normal1 = parseInt(0.5 * (1.0 + z) * 65535);
        return new Uint16Array([normal0, normal1]);
    }

    // for `Octahedron` encoding
    private static function octEncodeBest(x:Float, y:Float, z:Float, bytes:Int) {
        var oct, dec, best, currentCos, bestCos;

        // Test various combinations of ceil and floor
        // to minimize rounding errors
        best = oct = octEncodeVec3(x, y, z, 'floor', 'floor');
        dec = octDecodeVec2(oct);
        bestCos = dot(x, y, z, dec);

        oct = octEncodeVec3(x, y, z, 'ceil', 'floor');
        dec = octDecodeVec2(oct);
        currentCos = dot(x, y, z, dec);

        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }

        oct = octEncodeVec3(x, y, z, 'floor', 'ceil');
        dec = octDecodeVec2(oct);
        currentCos = dot(x, y, z, dec);

        if (currentCos > bestCos) {
            best = oct;
            bestCos = currentCos;
        }

        oct = octEncodeVec3(x, y, z, 'ceil', 'ceil');
        dec = octDecodeVec2(oct);
        currentCos = dot(x, y, z, dec);

        if (currentCos > bestCos) {
            best = oct;
        }

        return best;

        function octEncodeVec3(x0:Float, y0:Float, z0:Float, xfunc:String, yfunc:String) {
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
                return new Int8Array([
                    Math[xfunc](x * 127.5 + (x < 0 ? 1 : 0)),
                    Math[yfunc](y * 127.5 + (y < 0 ? 1 : 0))
                ]);

            } else if (bytes == 2) {
                return new Int16Array([
                    Math[xfunc](x * 32767.5 + (x < 0 ? 1 : 0)),
                    Math[yfunc](y * 32767.5 + (y < 0 ? 1 : 0))
                ]);

            }
        }

        function octDecodeVec2(oct:Array<Int>) {
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

        function dot(x:Float, y:Float, z:Float, vec3:Array<Float>) {
            return x * vec3[0] + y * vec3[1] + z * vec3[2];
        }
    }

    private static function quantizedEncode(array:Array<Float>, bytes:Int) {
        var quantized, segments;

        if (bytes == 1) {
            quantized = new Uint8Array(array.length);
            segments = 255;

        } else if (bytes == 2) {
            quantized = new Uint16Array(array.length);
            segments = 65535;

        } else {
            trace("number of bytes error!");
        }

        var decodeMat = new three.Matrix4();

        var min = new Float32Array(3);
        var max = new Float32Array(3);

        min[0] = min[1] = min[2] = Number.MAX_VALUE;
        max[0] = max[1] = max[2] = -Number.MAX_VALUE;

        for (i in 0...array.length by 3) {
            min[0] = Math.min(min[0], array[i + 0]);
            min[1] = Math.min(min[1], array[i + 1]);
            min[2] = Math.min(min[2], array[i + 2]);
            max[0] = Math.max(max[0], array[i + 0]);
            max[1] = Math.max(max[1], array[i + 1]);
            max[2] = Math.max(max[2], array[i + 2]);
        }

        decodeMat.scale(new three.Vector3(
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

        for (i in 0...array.length by 3) {
            quantized[i + 0] = Math.floor((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Math.floor((array[i + 1] - min[1]) * multiplier[1]);
            quantized[i + 2] = Math.floor((array[i + 2] - min[2]) * multiplier[2]);
        }

        return {
            quantized: quantized,
            decodeMat: decodeMat
        };
    }

    private static function quantizedEncodeUV(array:Array<Float>, bytes:Int) {
        var quantized, segments;

        if (bytes == 1) {
            quantized = new Uint8Array(array.length);
            segments = 255;

        } else if (bytes == 2) {
            quantized = new Uint16Array(array.length);
            segments = 65535;

        } else {
            trace("number of bytes error!");
        }

        var decodeMat = new three.Matrix3();

        var min = new Float32Array(2);
        var max = new Float32Array(2);

        min[0] = min[1] = Number.MAX_VALUE;
        max[0] = max[1] = -Number.MAX_VALUE;

        for (i in 0...array.length by 2) {
            min[0] = Math.min(min[0], array[i + 0]);
            min[1] = Math.min(min[1], array[i + 1]);
            max[0] = Math.max(max[0], array[i + 0]);
            max[1] = Math.max(max[1], array[i + 1]);
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

        for (i in 0...array.length by 2) {
            quantized[i + 0] = Math.floor((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Math.floor((array[i + 1] - min[1]) * multiplier[1]);
        }

        return {
            quantized: quantized,
            decodeMat: decodeMat
        };
    }
}