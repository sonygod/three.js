package three.geometries;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class WireframeGeometry extends BufferGeometry {

    public function new(?geometry:BufferGeometry) {
        super();

        this.type = 'WireframeGeometry';

        this.parameters = {
            geometry: geometry
        };

        if (geometry != null) {
            var vertices:Array<Float> = [];
            var edges:Set<String> = new Set();

            var start:Vector3 = new Vector3();
            var end:Vector3 = new Vector3();

            if (geometry.index != null) {
                // indexed BufferGeometry
                var position:Float32BufferAttribute = geometry.attributes.position;
                var indices:Array<Int> = geometry.index.array;
                var groups:Array<{ start:Int, count:Int, materialIndex:Int }> = geometry.groups;

                if (groups.length == 0) {
                    groups = [ { start: 0, count: indices.length, materialIndex: 0 } ];
                }

                for (o in 0...groups.length) {
                    var group = groups[o];
                    var groupStart = group.start;
                    var groupCount = group.count;

                    for (i in groupStart...groupStart + groupCount) {
                        for (j in 0...3) {
                            var index1 = indices[i + j];
                            var index2 = indices[i + (j + 1) % 3];

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
                var position:Float32BufferAttribute = geometry.attributes.position;

                for (i in 0...(position.data.length / 3)) {
                    for (j in 0...3) {
                        var index1 = 3 * i + j;
                        var index2 = 3 * i + (j + 1) % 3;

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

    override public function copy(source:WireframeGeometry):WireframeGeometry {
        super.copy(source);

        this.parameters = { geometry: source.parameters.geometry };

        return this;
    }

    static function isUniqueEdge(start:Vector3, end:Vector3, edges:Set<String>):Bool {
        var hash1 = '${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}';
        var hash2 = '${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}'; // coincident edge

        if (edges.exists(hash1) || edges.exists(hash2)) {
            return false;
        } else {
            edges.add(hash1);
            edges.add(hash2);
            return true;
        }
    }
}