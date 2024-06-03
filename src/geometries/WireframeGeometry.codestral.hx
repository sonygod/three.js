import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector3;

class WireframeGeometry extends BufferGeometry {
    public var parameters:Object;

    public function new(geometry:BufferGeometry = null) {
        super();
        this.type = "WireframeGeometry";

        this.parameters = {
            geometry: geometry
        };

        if (geometry != null) {
            var vertices = new Array<Float>();
            var edges = new haxe.ds.StringMap<Bool>();

            var start = new Vector3();
            var end = new Vector3();

            if (geometry.index != null) {
                var position = geometry.attributes.position;
                var indices = geometry.index;
                var groups = geometry.groups;

                if (groups.length == 0) {
                    groups = [{ start: 0, count: indices.count, materialIndex: 0 }];
                }

                for (var o = 0; o < groups.length; o++) {
                    var group = groups[o];
                    var groupStart = group.start;
                    var groupCount = group.count;

                    for (var i = groupStart; i < groupStart + groupCount; i += 3) {
                        for (var j = 0; j < 3; j++) {
                            var index1 = indices.getX(i + j);
                            var index2 = indices.getX(i + (j + 1) % 3);

                            start.fromBufferAttribute(position, index1);
                            end.fromBufferAttribute(position, index2);

                            if (isUniqueEdge(start, end, edges)) {
                                vertices.push(start.x, start.y, start.z);
                                vertices.push(end.x, end.y, end.z);
                            }
                        }
                    }
                }
            } else {
                var position = geometry.attributes.position;

                for (var i = 0; i < position.count / 3; i++) {
                    for (var j = 0; j < 3; j++) {
                        var index1 = 3 * i + j;
                        var index2 = 3 * i + (j + 1) % 3;

                        start.fromBufferAttribute(position, index1);
                        end.fromBufferAttribute(position, index2);

                        if (isUniqueEdge(start, end, edges)) {
                            vertices.push(start.x, start.y, start.z);
                            vertices.push(end.x, end.y, end.z);
                        }
                    }
                }
            }

            this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:WireframeGeometry):WireframeGeometry {
        super.copy(source);

        this.parameters = haxe.ds.ObjectMap.copy(source.parameters);

        return this;
    }
}

function isUniqueEdge(start:Vector3, end:Vector3, edges:haxe.ds.StringMap<Bool>):Bool {
    var hash1 = "${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}";
    var hash2 = "${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}";

    if (edges.exists(hash1) || edges.exists(hash2)) {
        return false;
    } else {
        edges.set(hash1, true);
        edges.set(hash2, true);
        return true;
    }
}