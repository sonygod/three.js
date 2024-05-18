import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.core.InstancedBufferAttribute;
import three.core.InterleavedBuffer;
import three.core.InterleavedBufferAttribute;
import three.enums.TriangleFanDrawMode;
import three.enums.TriangleStripDrawMode;
import three.enums.TrianglesDrawMode;
import three.math.Matrix4;

class BufferGeometryUtils {

    public static computeMikkTSpaceTangents(geometry: BufferGeometry, MikkTSpace, negateSign: Bool = true): BufferGeometry {
        if (!MikkTSpace || !MikkTSpace.isReady) {
            throw new Error("BufferGeometryUtils: Initialized MikkTSpace library required.");
        }

        if (!geometry.hasAttribute("position") || !geometry.hasAttribute("normal") || !geometry.hasAttribute("uv")) {
            throw new Error("BufferGeometryUtils: Tangents require \"position\", \"normal\", and \"uv\" attributes.");
        }

        function getAttributeArray(attribute: BufferAttribute<Float>): Array<Float> {
            if (attribute.normalized || attribute is InterleavedBufferAttribute) {
                const dstArray: Array<Float> = new Array<Float>(attribute.count * attribute.itemSize);

                for (let i: Int = 0, j: Int = 0; i < attribute.count; i++) {
                    dstArray[j++] = attribute.getX(i);
                    dstArray[j++] = attribute.getY(i);

                    if (attribute.itemSize > 2) {
                        dstArray[j++] = attribute.getZ(i);
                    }
                }

                return dstArray;
            }

            if (attribute.array instanceof Float32Array) {
                return Array<Float>(<Float32Array>attribute.array);
            }

            return new Array<Float>(<Array<Float>>attribute.array);
        }

        // MikkTSpace algorithm requires non-indexed input.
        const _geometry: BufferGeometry = if (geometry.index) geometry.toNonIndexed() else geometry;

        // Compute vertex tangents.
        const tangents: Array<Float> = MikkTSpace.generateTangents(
            getAttributeArray(_geometry.attributes.position),
            getAttributeArray(_geometry.attributes.normal),
            getAttributeArray(_geometry.attributes.uv)
        );

        // Texture coordinate convention of glTF differs from the apparent
        // default of the MikkTSpace library; .w component must be flipped.
        if (negateSign) {
            for (let i = 3; i < tangents.length; i += 4) {
                tangents[i] *= -1;
            }
        }

        //
        _geometry.setAttribute("tangent", new BufferAttribute(tangents, 4));

        if (geometry !== _geometry) {
            geometry.copy(_geometry);
        }

        return geometry;
    }

    // ... Rest of the code

}