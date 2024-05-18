package three.js.examples.jsm.exporters;

import three.Vector3;

class STLExporter {
    public function new() {}

    public function parse(scene:Dynamic, ?options:Dynamic = {}):Dynamic {
        options = Lambda.merge({ binary: false }, options);

        var binary:Bool = options.binary;

        var objects:Array<Dynamic> = [];
        var triangles:Int = 0;

        scene.traverse(function(object:Dynamic) {
            if (object.isMesh) {
                var geometry:Dynamic = object.geometry;
                var index:Dynamic = geometry.index;
                var positionAttribute:Dynamic = geometry.getAttribute('position');

                triangles += (index != null) ? (index.count / 3) : (positionAttribute.count / 3);

                objects.push({
                    object3d: object,
                    geometry: geometry
                });
            }
        });

        var output:Dynamic;
        var offset:Int = 80; // skip header

        if (binary) {
            var bufferLength:Int = triangles * 2 + triangles * 3 * 4 * 4 + 80 + 4;
            var arrayBuffer:ByteArray = new ByteArray(bufferLength);
            output = new DataView(arrayBuffer);
            output.setUint32(offset, triangles, true);
            offset += 4;
        } else {
            output = '';
            output += 'solid exported\n';
        }

        var vA:Vector3 = new Vector3();
        var vB:Vector3 = new Vector3();
        var vC:Vector3 = new Vector3();
        var cb:Vector3 = new Vector3();
        var ab:Vector3 = new Vector3();
        var normal:Vector3 = new Vector3();

        for (i in 0...objects.length) {
            var object:Dynamic = objects[i].object3d;
            var geometry:Dynamic = objects[i].geometry;

            var index:Dynamic = geometry.index;
            var positionAttribute:Dynamic = geometry.getAttribute('position');

            if (index != null) {
                // indexed geometry
                for (j in 0...index.count step 3) {
                    var a:Int = index.getX(j + 0);
                    var b:Int = index.getX(j + 1);
                    var c:Int = index.getX(j + 2);

                    writeFace(a, b, c, positionAttribute, object);
                }
            } else {
                // non-indexed geometry
                for (j in 0...positionAttribute.count step 3) {
                    var a:Int = j + 0;
                    var b:Int = j + 1;
                    var c:Int = j + 2;

                    writeFace(a, b, c, positionAttribute, object);
                }
            }
        }

        if (!binary) {
            output += 'endsolid exported\n';
        }

        return output;

        function writeFace(a:Int, b:Int, c:Int, positionAttribute:Dynamic, object:Dynamic) {
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

            if (binary) {
                output.setUint16(offset, 0, true);
                offset += 2;
            } else {
                output += '\t\tendloop\n';
                output += '\tendfacet\n';
            }
        }

        function writeNormal(vA:Vector3, vB:Vector3, vC:Vector3) {
            cb.subVectors(vC, vB);
            ab.subVectors(vA, vB);
            cb.cross(ab).normalize();

            normal.copy(cb).normalize();

            if (binary) {
                output.setFloat32(offset, normal.x, true);
                offset += 4;
                output.setFloat32(offset, normal.y, true);
                offset += 4;
                output.setFloat32(offset, normal.z, true);
                offset += 4;
            } else {
                output += '\tfacet normal ' + normal.x + ' ' + normal.y + ' ' + normal.z + '\n';
                output += '\t\touter loop\n';
            }
        }

        function writeVertex(vertex:Vector3) {
            if (binary) {
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