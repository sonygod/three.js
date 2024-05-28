import js.three.LineSegments;
import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.LineBasicMaterial;

class OctreeHelper extends LineSegments {
    var octree:Dynamic;
    var color:Int;

    public function new(octree:Dynamic, ?color:Int) {
        super(new BufferGeometry(), new LineBasicMaterial({ color: color ?? 0xffff00, toneMapped: false }));
        this.octree = octree;
        this.color = color;
        this.setType('OctreeHelper');
        this.update();
    }

    public function update() {
        var vertices = [];

        function traverse(tree:Dynamic) {
            for (i in 0...tree.length) {
                var min = tree[i].box.min;
                var max = tree[i].box.max;

                vertices.push(max.x, max.y, max.z);
                vertices.push(min.x, max.y, max.z); // 0, 1
                vertices.push(min.x, max.y, max.z);
                vertices.push(min.x, min.y, max.z); // 1, 2
                vertices.push(min.x, min.y, max.z);
                vertices.push(max.x, min.y, max.z); // 2, 3
                vertices.push(max.x, min.y, max.z);
                vertices.push(max.x, max.y, max.z); // 3, 0

                vertices.push(max.x, max.y, min.z);
                vertices.push(min.x, max.y, min.z); // 4, 5
                vertices.push(min.x, max.y, min.z);
                vertices.push(min.x, min.y, min.z); // 5, 6
                vertices.push(min.x, min.y, min.z);
                vertices.push(max.x, min.y, min.z); // 6, 7
                vertices.push(max.x, min.y, min.z);
                vertices.push(max.x, max.y, min.z); // 7, 4

                vertices.push(max.x, max.y, max.z);
                vertices.push(max.x, max.y, min.z); // 0, 4
                vertices.push(min.x, max.y, max.z);
                vertices.push(min.x, max.y, min.z); // 1, 5
                vertices.push(min.x, min.y, max.z);
                vertices.push(min.x, min.y, min.z); // 2, 6
                vertices.push(max.x, min.y, max.z);
                vertices.push(max.x, min.y, min.z); // 3, 7

                traverse(tree[i].subTrees);
            }
        }

        traverse(octree.subTrees);

        geometry.dispose();
        geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }

    public function dispose() {
        geometry.dispose();
        material.dispose();
    }
}

class Export {
    static function OctreeHelper() return OctreeHelper;
}