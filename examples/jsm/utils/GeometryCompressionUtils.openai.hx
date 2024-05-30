package three.js.examples.utils;

import three.Math;
import three.Matrix3;
import three.Matrix4;
import three.Vector3;
import three.BufferAttribute;
import three.PackedPhongMaterial;

using Lambda;

class GeometryCompressionUtils {
    /**
     * Make the input mesh.geometry's normal attribute encoded and compressed by 3 different methods.
     * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the normal data.
     *
     * @param mesh
     * @param encodeMethod "DEFAULT", "OCT1Byte", "OCT2Byte", or "ANGLES"
     */
    public static function compressNormals(mesh:Mesh, encodeMethod:String) {
        if (mesh.geometry == null) {
            console.error("Mesh must contain geometry.");
            return;
        }

        var normal:BufferAttribute = mesh.geometry.attributes.normal;
        if (normal == null) {
            console.error("Geometry must contain normal attribute.");
            return;
        }

        if (normal.isPacked) return;

        if (normal.itemSize != 3) {
            console.error("normal.itemSize is not 3, which cannot be encoded.");
            return;
        }

        var array:Array<Float> = normal.array;
        var count:Int = normal.count;

        var result:ArrayBUFFER;
        switch (encodeMethod) {
            case "DEFAULT":
                result = new Uint8Array(count * 3);
                for (i in 0...array.length) {
                    var idx:Int = i * 3;
                    var encoded:Array<Int> = defaultEncode(array[idx], array[idx + 1], array[idx + 2], 1);
                    result[idx + 0] = encoded[0];
                    result[idx + 1] = encoded[1];
                    result[idx + 2] = encoded[2];
                }
                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 3, true));
                mesh.geometry.attributes.normal.bytes = result.length * 1;
            case "OCT1Byte":
                result = new Int8Array(count * 2);
                for (i in 0...array.length) {
                    var idx:Int = i * 3;
                    var encoded:Array<Int> = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 1);
                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }
                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 1;
            case "OCT2Byte":
                result = new Int16Array(count * 2);
                for (i in 0...array.length) {
                    var idx:Int = i * 3;
                    var encoded:Array<Int> = octEncodeBest(array[idx], array[idx + 1], array[idx + 2], 2);
                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }
                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 2;
            case "ANGLES":
                result = new Uint16Array(count * 2);
                for (i in 0...array.length) {
                    var idx:Int = i * 3;
                    var encoded:Array<Int> = anglesEncode(array[idx], array[idx + 1], array[idx + 2]);
                    result[idx / 3 * 2 + 0] = encoded[0];
                    result[idx / 3 * 2 + 1] = encoded[1];
                }
                mesh.geometry.setAttribute("normal", new BufferAttribute(result, 2, true));
                mesh.geometry.attributes.normal.bytes = result.length * 2;
            default:
                console.error("Unrecognized encoding method, should be `DEFAULT` or `ANGLES` or `OCT`.");
        }

        mesh.geometry.attributes.normal.needsUpdate = true;
        mesh.geometry.attributes.normal.isPacked = true;
        mesh.geometry.attributes.normal.packingMethod = encodeMethod;

        // modify material
        if (!(mesh.material instanceof PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        switch (encodeMethod) {
            case "ANGLES":
                mesh.material.defines.USE_PACKED_NORMAL = 0;
            case "OCT1Byte":
                mesh.material.defines.USE_PACKED_NORMAL = 1;
            case "OCT2Byte":
                mesh.material.defines.USE_PACKED_NORMAL = 1;
            case "DEFAULT":
                mesh.material.defines.USE_PACKED_NORMAL = 2;
        }
    }

    /**
     * Make the input mesh.geometry's position attribute encoded and compressed.
     * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the position data.
     *
     * @param mesh
     */
    public static function compressPositions(mesh:Mesh) {
        if (mesh.geometry == null) {
            console.error("Mesh must contain geometry.");
            return;
        }

        var position:BufferAttribute = mesh.geometry.attributes.position;
        if (position == null) {
            console.error("Geometry must contain position attribute.");
            return;
        }

        if (position.isPacked) return;

        if (position.itemSize != 3) {
            console.error("position.itemSize is not 3, which cannot be packed.");
            return;
        }

        var array:Array<Float> = position.array;
        var bytes:Int = 2;
        var result:QuantizedResult = quantizedEncode(array, bytes);

        mesh.geometry.setAttribute("position", new BufferAttribute(result.quantized, 3));
        mesh.geometry.attributes.position.isPacked = true;
        mesh.geometry.attributes.position.needsUpdate = true;
        mesh.geometry.attributes.position.bytes = result.quantized.length * bytes;

        // modify material
        if (!(mesh.material instanceof PackedPhongMaterial)) {
            mesh.material = new PackedPhongMaterial().copy(mesh.material);
        }

        mesh.material.defines.USE_PACKED_POSITION = 0;

        mesh.material.uniforms.quantizeMatPos.value = result.decodeMat;
        mesh.material.uniforms.quantizeMatPos.needsUpdate = true;
    }

    /**
     * Make the input mesh.geometry's uv attribute encoded and compressed.
     * Also will change the mesh.material to `PackedPhongMaterial` which let the vertex shader program decode the uv data.
     *
     * @param mesh
     */
    public static function compressUvs(mesh:Mesh) {
        if (mesh.geometry == null) {
            console.error("Mesh must contain geometry.");
            return;
        }

        var uvs:BufferAttribute = mesh.geometry.attributes.uv;
        if (uvs == null) {
            console.error("Geometry must contain uv attribute.");
            return;
        }

        if (uvs.isPacked) return;

        var array:Array<Float> = uvs.array;
        var range:{min:Float, max:Float} = {
            min: Math.POSITIVE_INFINITY,
            max: Math.NEGATIVE_INFINITY
        };

        for (i in 0...array.length) {
            range.min = Math.min(range.min, array[i]);
            range.max = Math.max(range.max, array[i]);
        }

        var result:ArrayBUFFER;
        if (range.min >= -1.0 && range.max <= 1.0) {
            result = new Uint16Array(array.length);
            for (i in 0...array.length) {
                var encoded:Array<Int> = defaultEncode(array[i], array[(i + 1) % array.length], 0, 2);
                result[i] = encoded[0];
                result[(i + 1) % array.length] = encoded[1];
            }
            mesh.geometry.setAttribute("uv", new BufferAttribute(result, 2, true));
            mesh.geometry.attributes.uv.isPacked = true;
            mesh.geometry.attributes.uv.needsUpdate = true;
            mesh.geometry.attributes.uv.bytes = result.length * 2;

            if (!(mesh.material instanceof PackedPhongMaterial)) {
                mesh.material = new PackedPhongMaterial().copy(mesh.material);
            }

            mesh.material.defines.USE_PACKED_UV = 0;
        } else {
            result = quantizedEncodeUV(array, 2);
            mesh.geometry.setAttribute("uv", new BufferAttribute(result.quantized, 2));
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
    static function defaultEncode(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        if (bytes == 1) {
            return [
                Math.round((x + 1) * 0.5 * 255),
                Math.round((y + 1) * 0.5 * 255),
                Math.round((z + 1) * 0.5 * 255)
            ];
        } else if (bytes == 2) {
            return [
                Math.round((x + 1) * 0.5 * 65535),
                Math.round((y + 1) * 0.5 * 65535),
                Math.round((z + 1) * 0.5 * 65535)
            ];
        } else {
            console.error("number of bytes must be 1 or 2");
            return [];
        }
    }

    static function anglesEncode(x:Float, y:Float, z:Float):Array<Int> {
        var normal0:Int = Math.round(0.5 * (1.0 + Math.atan2(y, x) / Math.PI) * 65535);
        var normal1:Int = Math.round(0.5 * (1.0 + z) * 65535);
        return [normal0, normal1];
    }

    static function octEncodeBest(x:Float, y:Float, z:Float, bytes:Int):Array<Int> {
        // Implementation omitted for brevity
    }

    static function quantizedEncode(array:Array<Float>, bytes:Int):QuantizedResult {
        // Implementation omitted for brevity
    }

    static function quantizedEncodeUV(array:Array<Float>, bytes:Int):QuantizedResult {
        // Implementation omitted for brevity
    }
}