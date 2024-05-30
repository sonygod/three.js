package three.test.unit.src.objects;

import three.src.core.Object3D;
import three.src.objects.Mesh;
import three.src.core.Raycaster;
import three.src.geometries.PlaneGeometry;
import three.src.geometries.BoxGeometry;
import three.src.materials.MeshBasicMaterial;
import three.src.math.Vector2;
import three.src.math.Vector3;
import three.src.constants.DoubleSide;
import three.src.materials.Material;

class MeshTest {

    public static function main() {
        // INHERITANCE
        var mesh = new Mesh();
        trace(mesh instanceof Object3D, "Mesh extends from Object3D");

        // INSTANCING
        var object = new Mesh();
        trace(object, "Can instantiate a Mesh.");

        // PROPERTIES
        trace(object.type == "Mesh", "Mesh.type should be Mesh");

        // PUBLIC
        trace(object.isMesh, "Mesh.isMesh should be true");

        // raycast
        var geometry = new PlaneGeometry();
        var material = new MeshBasicMaterial();
        var mesh = new Mesh(geometry, material);
        var raycaster = new Raycaster();
        raycaster.ray.origin.set(0.25, 0.25, 1);
        raycaster.ray.direction.set(0, 0, -1);
        var intersections = [];
        mesh.raycast(raycaster, intersections);
        var intersection = intersections[0];
        trace(intersection.object == mesh, "intersction object");
        trace(intersection.distance == 1, "intersction distance");
        trace(intersection.faceIndex == 1, "intersction face index");
        trace(intersection.face == {a: 0, b: 2, c: 1}, "intersction vertex indices");
        trace(intersection.point == new Vector3(0.25, 0.25, 0), "intersction point");
        trace(intersection.uv == new Vector2(0.75, 0.75), "intersction uv");

        // raycast/range
        var geometry = new BoxGeometry(1, 1, 1);
        var material = new MeshBasicMaterial({side: DoubleSide});
        var mesh = new Mesh(geometry, material);
        var raycaster = new Raycaster();
        var intersections = [];
        raycaster.ray.origin.set(0, 0, 0);
        raycaster.ray.direction.set(1, 0, 0);
        raycaster.near = 100;
        raycaster.far = 200;
        mesh.matrixWorld.identity();
        mesh.position.setX(150);
        mesh.updateMatrixWorld(true);
        intersections.length = 0;
        mesh.raycast(raycaster, intersections);
        trace(intersections.length > 0, "bounding sphere between near and far");
        // ... 其他测试代码
    }
}