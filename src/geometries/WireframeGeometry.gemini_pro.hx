import haxe.ds.Set;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class WireframeGeometry extends BufferGeometry {

    public var geometry:BufferGeometry = null;

    public function new(geometry:BufferGeometry = null) {
        super();
        this.type = "WireframeGeometry";
        this.parameters = {
            geometry: geometry
        };
        if (geometry != null) {
            var vertices:Array<Float> = [];
            var edges:Set<String> = new Set();
            var start:Vector3 = new Vector3();
            var end:Vector3 = new Vector3();
            if (geometry.index != null) {
                var position:Float32BufferAttribute = geometry.attributes.position;
                var indices:Dynamic = geometry.index;
                var groups:Array<Dynamic> = geometry.groups;
                if (groups.length == 0) {
                    groups = [{start: 0, count: indices.count, materialIndex: 0}];
                }
                for (o in 0...groups.length) {
                    var group:Dynamic = groups[o];
                    var groupStart:Int = group.start;
                    var groupCount:Int = group.count;
                    for (i in groupStart...(groupStart + groupCount)) {
                        for (j in 0...3) {
                            var index1:Int = indices.getX(i + j);
                            var index2:Int = indices.getX(i + (j + 1) % 3);
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
                var position:Float32BufferAttribute = geometry.attributes.position;
                for (i in 0...(position.count / 3)) {
                    for (j in 0...3) {
                        var index1:Int = 3 * i + j;
                        var index2:Int = 3 * i + ((j + 1) % 3);
                        start.fromBufferAttribute(position, index1);
                        end.fromBufferAttribute(position, index2);
                        if (isUniqueEdge(start, end, edges)) {
                            vertices.push(start.x, start.y, start.z);
                            vertices.push(end.x, end.y, end.z);
                        }
                    }
                }
            }
            this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }

    public function copy(source:WireframeGeometry):WireframeGeometry {
        super.copy(source);
        this.parameters = {
            geometry: source.parameters.geometry
        };
        return this;
    }
}

function isUniqueEdge(start:Vector3, end:Vector3, edges:Set<String>):Bool {
    var hash1:String = '${start.x},${start.y},${start.z}-${end.x},${end.y},${end.z}';
    var hash2:String = '${end.x},${end.y},${end.z}-${start.x},${start.y},${start.z}';
    if (edges.exists(hash1) || edges.exists(hash2)) {
        return false;
    } else {
        edges.add(hash1);
        edges.add(hash2);
        return true;
    }
}