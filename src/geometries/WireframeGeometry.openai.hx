package three.geom;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;
import haxe.ds.Set;

class WireframeGeometry extends BufferGeometry {
    public function new(?geometry:BufferGeometry) {
        super();
        type = 'WireframeGeometry';
        parameters = { geometry: geometry };
        
        if (geometry != null) {
            var vertices:Array<Float> = [];
            var edges:Set<String> = new Set();
            
            var start:Vector3 = new Vector3();
            var end:Vector3 = new Vector3();
            
            if (geometry.index != null) {
                var position:Float32BufferAttribute = geometry.attributes.position;
                var indices:Array<Int> = geometry.index.array;
                var groups:Array<{start:Int, count:Int, materialIndex:Int}> = geometry.groups;
                
                if (groups.length == 0) {
                    groups = [{ start: 0, count: indices.length, materialIndex: 0 }];
                }
                
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
                var position:Float32BufferAttribute = geometry.attributes.position;
                
                for (i in 0...position.count) {
                    for (j in 0...3) {
                        var index1:Int = i * 3 + j;
                        var index2:Int = i * 3 + (j + 1) % 3;
                        
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
            
            setAttribute('position', new Float32BufferAttribute(vertices, 3));
        }
    }
    
    override public function copy(source:WireframeGeometry):WireframeGeometry {
        super.copy(source);
        parameters = haxe.Json.parse(haxe.Json.stringify(source.parameters));
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