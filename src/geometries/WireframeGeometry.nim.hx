import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class WireframeGeometry extends BufferGeometry {

    public var type:String;
    public var parameters:Dynamic;

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

                var position:BufferAttribute = geometry.attributes.position;
                var indices:BufferAttribute = geometry.index;
                var groups:Array<Dynamic> = geometry.groups;

                if (groups.length == 0) {

                    groups = [{ start: 0, count: indices.count, materialIndex: 0 }];

                }

                // create a data structure that contains all edges without duplicates

                for (i in 0...groups.length) {

                    var group:Dynamic = groups[i];

                    var groupStart:Int = group.start;
                    var groupCount:Int = group.count;

                    for (j in groupStart...(groupStart + groupCount)) {

                        for (k in 0...3) {

                            var index1:Int = indices.getX(j + k);
                            var index2:Int = indices.getX((j + k + 1) % 3);

                            start.fromBufferAttribute(position, index1);
                            end.fromBufferAttribute(position, index2);

                            if (isUniqueEdge(start, end, edges) == true) {

                                vertices.push(start.x, start.y, start.z);
                                vertices.push(end.x, end.y, end.z);

                            }

                        }

                    }

                }

            } else {

                // non-indexed BufferGeometry

                var position:BufferAttribute = geometry.attributes.position;

                for (i in 0...(position.count / 3)) {

                    for (j in 0...3) {

                        // three edges per triangle, an edge is represented as (index1, index2)
                        // e.g. the first triangle has the following edges: (0,1),(1,2),(2,0)

                        var index1:Int = 3 * i + j;
                        var index2:Int = 3 * i + ((j + 1) % 3);

                        start.fromBufferAttribute(position, index1);
                        end.fromBufferAttribute(position, index2);

                        if (isUniqueEdge(start, end, edges) == true) {

                            vertices.push(start.x, start.y, start.z);
                            vertices.push(end.x, end.y, end.z);

                        }

                    }

                }

            }

            // build geometry

            this.setAttribute('position', new BufferAttribute(vertices, 3));

        }

    }

    public function copy(source:WireframeGeometry):WireframeGeometry {

        super.copy(source);

        this.parameters = Type.clone(source.parameters);

        return this;

    }

    private static function isUniqueEdge(start:Vector3, end:Vector3, edges:Set<String>):Bool {

        var hash1:String = "${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}";
        var hash2:String = "${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}"; // coincident edge

        if (edges.exists(hash1) == true || edges.exists(hash2) == true) {

            return false;

        } else {

            edges.add(hash1);
            edges.add(hash2);
            return true;

        }

    }

}