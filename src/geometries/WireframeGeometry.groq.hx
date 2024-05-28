package three.js.src.geometries;

import three.js.src.core.BufferGeometry;
import three.js.src.core.Float32BufferAttribute;
import three.js.math.Vector3;

class WireframeGeometry extends BufferGeometry {
    public function new(geometry:BufferGeometry = null) {
        super();

        this.type = 'WireframeGeometry';

        this.parameters = {
            geometry: geometry
        };

        if (geometry != null) {
            // buffer

            var vertices:Array<Float> = [];
            var edges:Set<String> = new Set();

            // helper variables

            var start:Vector3 = new Vector3();
            var end:Vector3 = new Vector3();

            if (geometry.index != null) {
                // indexed BufferGeometry

                var position:Float32BufferAttribute = geometry.getAttribute('position');
                var indices:Array<Int> = geometry.index.array;
                var groups:Array<{start:Int, count:Int, materialIndex:Int}> = geometry.groups;

                if (groups.length == 0) {
                    groups = [{ start: 0, count: indices.length, materialIndex: 0 }];
                }

                // create a data structure that contains all edges without duplicates

                for (o in 0...groups.length) {
                    var group = groups[o];
                    var groupStart:Int = group.start;
                    var groupCount:Int = group.count;

                    for (i in groupStart...groupStart + groupCount) {
                        for (j in 0...3) {
                            var index1:Int = indices[i + j];
                            var index2:Int = indices[i + (j + 1) % 3];

                            start.fromBufferAttribute(position, index1);
                            end.fromBufferAttribute(position, index2);

                            if (isUniqueEdge(start, end, edges)) {
                                vertices.push(start.x);
                                vertices.push(start.y);
                                vertices.push(start.z);
                                vertices.push(end.x);
                                vertices.push(end.y);
                                vertices.push(end.z);
                            }
                        }
                    }
                }
            } else {
                // non-indexed BufferGeometry

                var position:Float32BufferAttribute = geometry.getAttribute('position');

                for (i in 0...Std.int(position.count / 3)) {
                    for (j in 0...3) {
                        // three edges per triangle, an edge is represented as (index1, index2)
                        // e.g. the first triangle has the following edges: (0,1),(1,2),(2,0)

                        var index1:Int = 3 * i + j;
                        var index2:Int = 3 * i + (j + 1) % 3;

                        start.fromBufferAttribute(position, index1);
                        end.fromBufferAttribute(position, index2);

                        if (isUniqueEdge(start, end, edges)) {
                            vertices.push(start.x);
                            vertices.push(start.y);
                            vertices.push(start.z);
                            vertices.push(end.x);
                            vertices.push(end.y);
                            vertices.push(end.z);
                        }
                    }
                }
            }

            // build geometry

            this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }

    override public function copy(source:BufferGeometry) {
        super.copy(source);

        this.parameters = { geometry: source.parameters.geometry };

        return this;
    }
}

function isUniqueEdge(start:Vector3, end:Vector3, edges:Set<String>):Bool {
    var hash1:String = '${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}';
    var hash2:String = '${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}'; // coincident edge

    if (edges.exists(hash1) || edges.exists(hash2)) {
        return false;
    } else {
        edges.add(hash1);
        edges.add(hash2);
        return true;
    }
}