package three.js.misc;

import three.BufferAttribute;
import three.BufferGeometry;
import three.Color;
import three.DynamicDrawUsage;
import three.Matrix4;
import three.Mesh;
import three.MeshStandardMaterial;
import three.Vector3;

class TubePainter {
    private static inline var BUFFER_SIZE:Int = 1000000 * 3;

    private var positions:BufferAttribute;
    private var normals:BufferAttribute;
    private var colors:BufferAttribute;
    private var geometry:BufferGeometry;
    private var material:MeshStandardMaterial;
    private var mesh:Mesh;

    private var vector1:Vector3;
    private var vector2:Vector3;
    private var vector3:Vector3;
    private var vector4:Vector3;
    private var color:Color;
    private var size:Float;

    public function new() {
        positions = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
        positions.usage = DynamicDrawUsage;

        normals = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
        normals.usage = DynamicDrawUsage;

        colors = new BufferAttribute(new Float32Array(BUFFER_SIZE), 3);
        colors.usage = DynamicDrawUsage;

        geometry = new BufferGeometry();
        geometry.setAttribute('position', positions);
        geometry.setAttribute('normal', normals);
        geometry.setAttribute('color', colors);
        geometry.drawRange.count = 0;

        material = new MeshStandardMaterial({
            vertexColors: true
        });

        mesh = new Mesh(geometry, material);
        mesh.frustumCulled = false;

        vector1 = new Vector3();
        vector2 = new Vector3();
        vector3 = new Vector3();
        vector4 = new Vector3();
        color = new Color(0xffffff);
        size = 1;
    }

    private function getPoints(size:Float):Array<Vector3> {
        var PI2:Float = Math.PI * 2;
        var sides:Int = 10;
        var array:Array<Vector3> = [];
        var radius:Float = 0.01 * size;

        for (i in 0...sides) {
            var angle:Float = (i / sides) * PI2;
            array.push(new Vector3(Math.sin(angle) * radius, Math.cos(angle) * radius, 0));
        }

        return array;
    }

    private function stroke(position1:Vector3, position2:Vector3, matrix1:Matrix4, matrix2:Matrix4) {
        if (position1.distanceToSquared(position2) == 0) return;

        var count:Int = geometry.drawRange.count;

        var points:Array<Vector3> = getPoints(size);

        for (i in 0...points.length) {
            var vertex1:Vector3 = points[i];
            var vertex2:Vector3 = points[(i + 1) % points.length];

            vector1.copy(vertex1).applyMatrix4(matrix2).add(position2);
            vector2.copy(vertex2).applyMatrix4(matrix2).add(position2);
            vector3.copy(vertex2).applyMatrix4(matrix1).add(position1);
            vector4.copy(vertex1).applyMatrix4(matrix1).add(position1);

            vector1.toArray(positions.array, (count + 0) * 3);
            vector2.toArray(positions.array, (count + 1) * 3);
            vector4.toArray(positions.array, (count + 2) * 3);

            vector2.toArray(positions.array, (count + 3) * 3);
            vector3.toArray(positions.array, (count + 4) * 3);
            vector4.toArray(positions.array, (count + 5) * 3);

            vector1.copy(vertex1).applyMatrix4(matrix2).normalize();
            vector2.copy(vertex2).applyMatrix4(matrix2).normalize();
            vector3.copy(vertex2).applyMatrix4(matrix1).normalize();
            vector4.copy(vertex1).applyMatrix4(matrix1).normalize();

            vector1.toArray(normals.array, (count + 0) * 3);
            vector2.toArray(normals.array, (count + 1) * 3);
            vector4.toArray(normals.array, (count + 2) * 3);

            vector2.toArray(normals.array, (count + 3) * 3);
            vector3.toArray(normals.array, (count + 4) * 3);
            vector4.toArray(normals.array, (count + 5) * 3);

            color.toArray(colors.array, (count + 0) * 3);
            color.toArray(colors.array, (count + 1) * 3);
            color.toArray(colors.array, (count + 2) * 3);

            color.toArray(colors.array, (count + 3) * 3);
            color.toArray(colors.array, (count + 4) * 3);
            color.toArray(colors.array, (count + 5) * 3);

            count += 6;
        }

        geometry.drawRange.count = count;
    }

    private var up:Vector3 = new Vector3(0, 1, 0);
    private var point1:Vector3 = new Vector3();
    private var point2:Vector3 = new Vector3();
    private var matrix1:Matrix4 = new Matrix4();
    private var matrix2:Matrix4 = new Matrix4();

    public function moveTo(position:Vector3) {
        point1.copy(position);
        matrix1.lookAt(point2, point1, up);

        point2.copy(position);
        matrix2.copy(matrix1);
    }

    public function lineTo(position:Vector3) {
        point1.copy(position);
        matrix1.lookAt(point2, point1, up);

        stroke(point1, point2, matrix1, matrix2);

        point2.copy(point1);
        matrix2.copy(matrix1);
    }

    public function setSize(value:Float) {
        size = value;
    }

    private var count:Int = 0;

    public function update() {
        var start:Int = count;
        var end:Int = geometry.drawRange.count;

        if (start == end) return;

        positions.addUpdateRange(start * 3, (end - start) * 3);
        positions.needsUpdate = true;

        normals.addUpdateRange(start * 3, (end - start) * 3);
        normals.needsUpdate = true;

        colors.addUpdateRange(start * 3, (end - start) * 3);
        colors.needsUpdate = true;

        count = geometry.drawRange.count;
    }

    public function get_mesh():Mesh {
        return mesh;
    }

    public function get_moveTo():Void->Void {
        return moveTo;
    }

    public function get_lineTo():Void->Void {
        return lineTo;
    }

    public function get_setSize():Float->Void {
        return setSize;
    }

    public function get_update():Void->Void {
        return update;
    }
}