package three.js.helpers;

import three.js.core.BufferGeometry;
import three.js.core.Float32BufferAttribute;
import three.js.materials.LineBasicMaterial;
import three.js.objects.LineSegments;

class OctreeHelper extends LineSegments {
    
    public var octree:Dynamic;
    public var color:Int;

    public function new(octree:Dynamic, color:Int = 0xFFFF00) {
        super(new BufferGeometry(), new LineBasicMaterial({ color: color, toneMapped: false }));
        this.octree = octree;
        this.color = color;
        this.type = 'OctreeHelper';
        update();
    }

    public function update():Void {
        var vertices:Array<Float> = [];

        function traverse(tree:Array<Dynamic>):Void {
            for (i in 0...tree.length) {
                var min:Array<Float> = tree[i].box.min;
                var max:Array<Float> = tree[i].box.max;

                vertices.push(max[0], max[1], max[2]); vertices.push(min[0], max[1], max[2]); // 0, 1
                vertices.push(min[0], max[1], max[2]); vertices.push(min[0], min[1], max[2]); // 1, 2
                vertices.push(min[0], min[1], max[2]); vertices.push(max[0], min[1], max[2]); // 2, 3
                vertices.push(max[0], min[1], max[2]); vertices.push(max[0], max[1], max[2]); // 3, 0

                vertices.push(max[0], max[1], min[2]); vertices.push(min[0], max[1], min[2]); // 4, 5
                vertices.push(min[0], max[1], min[2]); vertices.push(min[0], min[1], min[2]); // 5, 6
                vertices.push(min[0], min[1], min[2]); vertices.push(max[0], min[1], min[2]); // 6, 7
                vertices.push(max[0], min[1], min[2]); vertices.push(max[0], max[1], min[2]); // 7, 4

                vertices.push(max[0], max[1], max[2]); vertices.push(max[0], max[1], min[2]); // 0, 4
                vertices.push(min[0], max[1], max[2]); vertices.push(min[0], max[1], min[2]); // 1, 5
                vertices.push(min[0], min[1], max[2]); vertices.push(min[0], min[1], min[2]); // 2, 6
                vertices.push(max[0], min[1], max[2]); vertices.push(max[0], min[1], min[2]); // 3, 7

                traverse(tree[i].subTrees);
            }
        }

        traverse(octree.subTrees);

        geometry.dispose();
        geometry = new BufferGeometry();
        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
    }

    public function dispose():Void {
        geometry.dispose();
        material.dispose();
    }
}