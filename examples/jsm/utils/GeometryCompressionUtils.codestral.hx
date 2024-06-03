import three.BufferAttribute;
import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import utils.PackedPhongMaterial;

class GeometryCompressionUtils {

    static function compressNormals(mesh:Mesh, encodeMethod:String) {
        if (mesh.geometry == null) {
            trace("Mesh must contain geometry.");
            return;
        }

        var normal = mesh.geometry.attributes.normal;

        if (normal == null) {
            trace("Geometry must contain normal attribute.");
            return;
        }

        if (normal.isPacked) return;

        if (normal.itemSize != 3) {
            trace("normal.itemSize is not 3, which cannot be encoded.");
            return;
        }

        var array = normal.array;
        var count = normal.count;

        var result:Array<Int>;
        switch (encodeMethod) {
            case "DEFAULT":
                result = new Array<Int>();

                for (var idx = 0; idx < array.length; idx += 3) {
                    var encoded = defaultEncode(array[idx], array[idx + 1], array[idx + 2], 1);

                    result[idx + 0] = encoded[0];
                    result[idx + 1] = encoded[1];
                    result[idx + 2] = encoded[2];
                }

                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 3, true));
                mesh.geometry.attributes.normal.bytes = result.length * 1;
                break;

            case "OCT1Byte":
                result = new Array<Int>();

                for (var idx = 0; idx < array.length; idx += 3) {
                    var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 1);

                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }

                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 1;
                break;

            case "OCT2Byte":
                result = new Array<Int>();

                for (var idx = 0; idx < array.length; idx += 3) {
                    var encoded = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 2);

                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }

                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 2;
                break;

            case "ANGLES":
                result = new Array<Int>();

                for (var idx = 0; idx < array.length; idx += 3) {
                    var encoded = anglesEncode(array[idx], array[idx + 1], array[idx + 2]);

                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }

                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 2;
                break;

            default:
                trace("Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`.");
                return;
        }

        mesh.geometry.attributes.normal.needsUpdate = true;
        mesh.geometry.attributes.normal.isPacked = true;
        mesh.geometry.attributes.normal.packingMethod = encodeMethod;

        if (!(mesh.material is PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        switch (encodeMethod) {
            case "ANGLES":
                mesh.material.defines["USE_PACKED_NORMAL"] = 0;
                break;

            case "OCT1Byte":
            case "OCT2Byte":
                mesh.material.defines["USE_PACKED_NORMAL"] = 1;
                break;

            case "DEFAULT":
                mesh.material.defines["USE_PACKED_NORMAL"] = 2;
                break;
        }
    }

    static function compressPositions(mesh:Mesh) {
        if (mesh.geometry == null) {
            trace("Mesh must contain geometry.");
            return;
        }

        var position = mesh.geometry.attributes.position;

        if (position == null) {
            trace("Geometry must contain position attribute.");
            return;
        }

        if (position.isPacked) return;

        if (position.itemSize != 3) {
            trace("position.itemSize is not 3, which cannot be packed.");
            return;
        }

        var array = position.array;
        var encodingBytes = 2;

        var result = quantizedEncode(array, encodingBytes);

        var quantized = result.quantized;
        var decodeMat = result.decodeMat;

        if (mesh.geometry.boundingBox == null) mesh.geometry.computeBoundingBox();
        if (mesh.geometry.boundingSphere == null) mesh.geometry.computeBoundingSphere();

        mesh.geometry.setAttribute("position", new BufferAttribute(quantized, 3));
        mesh.geometry.attributes.position.isPacked = true;
        mesh.geometry.attributes.position.needsUpdate = true;
        mesh.geometry.attributes.position.bytes = quantized.length * encodingBytes;

        if (!(mesh.material is PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        mesh.material.defines["USE_PACKED_POSITION"] = 0;

        mesh.material.uniforms["quantizeMatPos"].value = decodeMat;
        mesh.material.uniforms["quantizeMatPos"].needsUpdate = true;
    }

    static function compressUvs(mesh:Mesh) {
        if (mesh.geometry == null) {
            trace("Mesh must contain geometry property.");
            return;
        }

        var uvs = mesh.geometry.attributes.uv;

        if (uvs == null) {
            trace("Geometry must contain uv attribute.");
            return;
        }

        if (uvs.isPacked) return;

        var range = { min: Float.POSITIVE_INFINITY, max: Float.NEGATIVE_INFINITY };

        var array = uvs.array;

        for (var i = 0; i < array.length; i++) {
            range.min = Math.min(range.min, array[i]);
            range.max = Math.max(range.max, array[i]);
        }

        var result:Array<Int>;

        if (range.min >= -1.0 && range.max <= 1.0) {
            result = new Array<Int>();

            for (var i = 0; i < array.length; i += 2) {
                var encoded = defaultEncode(array[i], array[i + 1], 0, 2);

                result[i] = encoded[0];
                result[i + 1] = encoded[1];
            }

            mesh.geometry.setAttribute("uv", new BufferAttribute(result, 2, true));
            mesh.geometry.attributes.uv.isPacked = true;
            mesh.geometry.attributes.uv.needsUpdate = true;
            mesh.geometry.attributes.uv.bytes = result.length * 2;

            if (!(mesh.material is PackedPhongMaterial)) {
                mesh.material = new PackedPhongMaterial().copy(mesh.material);
            }

            mesh.material.defines["USE_PACKED_UV"] = 0;
        } else {
            result = quantizedEncodeUV(array, 2);

            mesh.geometry.setAttribute("uv", new BufferAttribute(result.quantized, 2));
            mesh.geometry.attributes.uv.isPacked = true;
            mesh.geometry.attributes.uv.needsUpdate = true;
            mesh.geometry.attributes.uv.bytes = result.quantized.length * 2;

            if (!(mesh.material is PackedPhongMaterial)) {
                mesh.material = new PackedPhongMaterial().copy(mesh.material);
            }

            mesh.material.defines["USE_PACKED_UV"] = 1;

            mesh.material.uniforms["quantizeMatUV"].value = result.decodeMat;
            mesh.material.uniforms["quantizeMatUV"].needsUpdate = true;
        }
    }

    // Encoding functions

    static function defaultEncode(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        if (bytes == 1) {
            var tmpx = Math.round((x + 1) * 0.5 * 255);
            var tmpy = Math.round((y + 1) * 0.5 * 255);
            var tmpz = Math.round((z + 1) * 0.5 * 255);
            return [tmpx, tmpy, tmpz];
        } else if (bytes == 2) {
            var tmpx = Math.round((x + 1) * 0.5 * 65535);
            var tmpy = Math.round((y + 1) * 0.5 * 65535);
            var tmpz = Math.round((z + 1) * 0.5 * 65535);
            return [tmpx, tmpy, tmpz];
        } else {
            trace("number of bytes must be 1 or 2");
            return [];
        }
    }

    static function anglesEncode(x:Float, y:Float, z:Float):Array<Int> {
        var normal0 = Std.parseInt(0.5 * (1.0 + Math.atan2(y, x) / Math.PI) * 65535);
        var normal1 = Std.parseInt(0.5 * (1.0 + z) * 65535);
        return [normal0, normal1];
    }

    static function octEncodeBest(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        var oct:Array<Int>, dec:Array<Float>, best:Array<Int>, currentCos:Float, bestCos:Float;

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

        function octEncodeVec3(x0:Float, y0:Float, z0:Float, xfunc:String, yfunc:String):Array<Int> {
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
                return [
                    Std.parseInt(Std.parseFloat(x * 127.5 + (x < 0 ? 1 : 0))),
                    Std.parseInt(Std.parseFloat(y * 127.5 + (y < 0 ? 1 : 0)))
                ];
            }

            if (bytes == 2) {
                return [
                    Std.parseInt(Std.parseFloat(x * 32767.5 + (x < 0 ? 1 : 0))),
                    Std.parseInt(Std.parseFloat(y * 32767.5 + (y < 0 ? 1 : 0)))
                ];
            }

            return [];
        }

        function octDecodeVec2(oct:Array<Int>):Array<Float> {
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

        function dot(x:Float, y:Float, z:Float, vec3:Array<Float>):Float {
            return x * vec3[0] + y * vec3[1] + z * vec3[2];
        }
    }

    static function quantizedEncode(array:Array<Float>, bytes:Int):Dynamic {
        var quantized:Array<Int>, segments:Int;

        if (bytes == 1) {
            quantized = new Array<Int>();
            segments = 255;
        } else if (bytes == 2) {
            quantized = new Array<Int>();
            segments = 65535;
        } else {
            trace("number of bytes error!");
            return null;
        }

        var decodeMat = new Matrix4();

        var min = new Array<Float>([Float.MAX_VALUE, Float.MAX_VALUE, Float.MAX_VALUE]);
        var max = new Array<Float>([-Float.MAX_VALUE, -Float.MAX_VALUE, -Float.MAX_VALUE]);

        for (var i = 0; i < array.length; i += 3) {
            min[0] = Math.min(min[0], array[i + 0]);
            min[1] = Math.min(min[1], array[i + 1]);
            min[2] = Math.min(min[2], array[i + 2]);
            max[0] = Math.max(max[0], array[i + 0]);
            max[1] = Math.max(max[1], array[i + 1]);
            max[2] = Math.max(max[2], array[i + 2]);
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

        var multiplier = new Array<Float>([
            max[0] !== min[0] ? segments / (max[0] - min[0]) : 0,
            max[1] !== min[1] ? segments / (max[1] - min[1]) : 0,
            max[2] !== min[2] ? segments / (max[2] - min[2]) : 0
        ]);

        for (var i = 0; i < array.length; i += 3) {
            quantized[i + 0] = Std.parseInt((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Std.parseInt((array[i + 1] - min[1]) * multiplier[1]);
            quantized[i + 2] = Std.parseInt((array[i + 2] - min[2]) * multiplier[2]);
        }

        return {
            quantized: quantized,
            decodeMat: decodeMat
        };
    }

    static function quantizedEncodeUV(array:Array<Float>, bytes:Int):Dynamic {
        var quantized:Array<Int>, segments:Int;

        if (bytes == 1) {
            quantized = new Array<Int>();
            segments = 255;
        } else if (bytes == 2) {
            quantized = new Array<Int>();
            segments = 65535;
        } else {
            trace("number of bytes error!");
            return null;
        }

        var decodeMat = new Matrix3();

        var min = new Array<Float>([Float.MAX_VALUE, Float.MAX_VALUE]);
        var max = new Array<Float>([-Float.MAX_VALUE, -Float.MAX_VALUE]);

        for (var i = 0; i < array.length; i += 2) {
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

        var multiplier = new Array<Float>([
            max[0] !== min[0] ? segments / (max[0] - min[0]) : 0,
            max[1] !== min[1] ? segments / (max[1] - min[1]) : 0
        ]);

        for (var i = 0; i < array.length; i += 2) {
            quantized[i + 0] = Std.parseInt((array[i + 0] - min[0]) * multiplier[0]);
            quantized[i + 1] = Std.parseInt((array[i + 1] - min[1]) * multiplier[1]);
        }

        return {
            quantized: quantized,
            decodeMat: decodeMat
        };
    }
}