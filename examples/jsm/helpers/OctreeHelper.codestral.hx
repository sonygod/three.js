import js.three.LineSegments;
import js.three.BufferGeometry;
import js.three.Float32BufferAttribute;
import js.three.LineBasicMaterial;
import js.three.materials.LineBasicMaterialParameters;

class OctreeHelper extends LineSegments {
    public var octree: js.three.Octree;
    public var color: Int;
    public var type: String;

    public function new(octree: js.three.Octree, ?color: Int) {
        this.color = color != null ? color : 0xffff00;

        var parameters: LineBasicMaterialParameters = {
            color: this.color,
            toneMapped: false
        };
        var material: LineBasicMaterial = new LineBasicMaterial(parameters);

        super(new BufferGeometry(), material);

        this.octree = octree;
        this.type = 'OctreeHelper';

        this.update();
    }

    public function update() {
        var vertices: Array<Float> = [];

        function traverse(tree: Array<js.three.OctreeNode>) {
            for (i in 0...tree.length) {
                var min = tree[i].box.min;
                var max = tree[i].box.max;

                vertices.push(max.x, max.y, max.z); vertices.push(min.x, max.y, max.z); // 0, 1
                vertices.push(min.x, max.y, max.z); vertices.push(min.x, min.y, max.z); // 1, 2
                vertices.push(min.x, min.y, max.z); vertices.push(max.x, min.y, max.z); // 2, 3
                vertices.push(max.x, min.y, max.z); vertices.push(max.x, max.y, max.z); // 3, 0

                vertices.push(max.x, max.y, min.z); vertices.push(min.x, max.y, min.z); // 4, 5
                vertices.push(min.x, max.y, min.z); vertices.push(min.x, min.y, min.z); // 5, 6
                vertices.push(min.x, min.y, min.z); vertices.push(max.x, min.y, min.z); // 6, 7
                vertices.push(max.x, min.y, min.z); vertices.push(max.x, max.y, min.z); // 7, 4

                vertices.push(max.x, max.y, max.z); vertices.push(max.x, max.y, min.z); // 0, 4
                vertices.push(min.x, max.y, max.z); vertices.push(min.x, max.y, min.z); // 1, 5
                vertices.push(min.x, min.y, max.z); vertices.push(min.x, min.y, min.z); // 2, 6
                vertices.push(max.x, min.y, max.z); vertices.push(max.x, min.y, min.z); // 3, 7

                traverse(tree[i].subTrees);
            }
        }

        traverse(this.octree.subTrees);

        this.geometry.dispose();

        this.geometry = new BufferGeometry();
        this.geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}