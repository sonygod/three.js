import js.three.Vector3;

class STLExporter {
    public function new() {

    }

    public function parse(scene: dynamic, ?options: { binary: Bool } = { binary: false }) : String {
        var objects: Array<{ object3d: dynamic; geometry: dynamic; }> = [];
        var triangles: Int = 0;

        scene.traverse(function (object: dynamic) {
            if (Std.is(object, dynamic)) {
                var geometry: dynamic = object.geometry;

                var index: dynamic = geometry.index;
                var positionAttribute: dynamic = geometry.getAttribute('position');

                triangles += if (index != null) (index.count / 3) else (positionAttribute.count / 3);

                objects.push({ object3d: object, geometry: geometry });
            }
        });

        var output: String;
        var offset: Int = 80; // skip header

        if (options.binary) {
            var bufferLength: Int = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
            var arrayBuffer: dynamic = new js.ArrayBuffer(bufferLength);
            output = new js.DataView(arrayBuffer);
            output.setUint32(offset, triangles, true);
            offset += 4;
        } else {
            output = 'solid exported\n';
        }

        var vA: Vector3 = new Vector3();
        var vB: Vector3 = new Vector3();
        var vC: Vector3 = new Vector3();
        var cb: Vector3 = new Vector3();
        var ab: Vector3 = new Vector3();
        var normal: Vector3 = new Vector3();

        for (i in 0...objects.length) {
            var object: dynamic = objects[i].object3d;
            var geometry: dynamic = objects[i].geometry;

            var index: dynamic = geometry.index;
            var positionAttribute: dynamic = geometry.getAttribute('position');

            if (index != null) {
                // indexed geometry
                for (j in 0...index.count) {
                    var a: Int = index.getX(j + 0);
                    var b: Int = index.getX(j + 1);
                    var c: Int = index.getX(j + 2);

                    writeFace(a, b, c, positionAttribute, object);
                }
            } else {
                // non-indexed geometry
                for (j in 0...positionAttribute.count) {
                    var a: Int = j + 0;
                    var b: Int = j + 1;
                    var c: Int = j + 2;

                    writeFace(a, b, c, positionAttribute, object);
                }
            }
        }

        if (!options.binary) {
            output += 'endsolid exported\n';
        }

        return output;

        function writeFace(a: Int, b: Int, c: Int, positionAttribute: dynamic, object: dynamic) {
            vA.fromBufferAttribute(positionAttribute, a);
            vB.fromBufferAttribute(positionAttribute, b);
            vC.fromBufferAttribute(positionAttribute, c);

            if (object.isSkinnedMesh) {
                object.applyBoneTransform(a, vA);
                object.applyBoneTransform(b, vB);
                object.applyBoneTransform(c, vC);
            }

            vA.applyMatrix4(object.matrixWorld);
            vB.applyMatrix4(object.matrixWorld);
            vC.applyMatrix4(object.matrixWorld);

            writeNormal(vA, vB, vC);

            writeVertex(vA);
            writeVertex(vB);
            writeVertex(vC);

            if (options.binary) {
                output.setUint16(offset, 0, true);
                offset += 2;
            } else {
                output += '\t\tendloop\n';
                output += '\tendfacet\n';
            }
        }

        function writeNormal(vA: Vector3, vB: Vector3, vC: Vector3) {
            cb.subVectors(vC, vB);
            ab.subVectors(vA, vB);
            cb.cross(ab).normalize();

            normal.copy(cb).normalize();

            if (options.binary) {
                output.setFloat32(offset, normal.x, true);
                offset += 4;
                output.setFloat32(offset, normal.y, true);
                offset += 4;
                output.setFloat32(offset, normal.z, true);
                offset += 4;
            } else {
                output += 'facet normal ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
                output += '\t\touter loop\n';
            }
        }

        function writeVertex(vertex: Vector3) {
            if (options.binary) {
                output.setFloat32(offset, vertex.x, true);
                offset += 4;
                output.setFloat32(offset, vertex.y, true);
                offset += 4;
                output.setFloat32(offset, vertex.z, true);
                offset += 4;
            } else {
                output += '\t\t\tvertex ' + vertex.x + ' ' + vertex.y + ' ' + vertex.z + '\n';
            }
        }
    }
}

@:expose
class Exports {
    static var STLExporter: STLExporter = new STLExporter();
}