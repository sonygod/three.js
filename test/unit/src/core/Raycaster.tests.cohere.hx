import h3d.Raycaster;
import h3d.Vector3;
import h3d.Mesh;
import h3d.SphereGeometry;
import h3d.BufferGeometry;
import h3d.Line;
import h3d.Points;
import h3d.PerspectiveCamera;
import h3d.OrthographicCamera;

function checkRayDirectionAgainstReferenceVector(rayDirection:Vector3<Float>, refVector:Vector3<Float>, assert) {
    assert.isTrue(refVector.x - rayDirection.x <= Float.EPSILON && refVector.y - rayDirection.y <= Float.EPSILON && refVector.z - rayDirection.z <= Float.EPSILON, 'camera is pointing to the same direction as expected');
}

function getRaycaster():Raycaster<Float> {
    return new Raycaster(new Vector3<Float>(), new Vector3<Float>(0, 0, -1), 1, 100);
}

function getObjectsToCheck():Array<Mesh<Float>> {
    var objects = new Array<Mesh<Float>>();
    var sphere1 = getSphere();
    sphere1.position.set(0, 0, -10);
    sphere1.name = 1;
    objects.push(sphere1);

    var sphere11 = getSphere();
    sphere11.position.set(0, 0, 1);
    sphere11.name = 11;
    sphere1.add(sphere11);

    var sphere12 = getSphere();
    sphere12.position.set(0, 0, -1);
    sphere12.name = 12;
    sphere1.add(sphere12);

    var sphere2 = getSphere();
    sphere2.position.set(-5, 0, -5);
    sphere2.name = 2;
    objects.push(sphere2);

    for (i in 0...objects.length) {
        objects[i].updateMatrixWorld();
    }

    return objects;
}

function getSphere():Mesh<Float> {
    return new Mesh(new SphereGeometry(1, 100, 100));
}

class TestRaycaster {
    static public function instancing():Void {
        var object = new Raycaster();
        trace('Can instantiate a Raycaster.');
    }

    static public function set():Void {
        var origin = new Vector3<Float>();
        var direction = new Vector3<Float>(0, 0, -1);
        var a = new Raycaster(origin.clone(), direction.clone());

        assert.equal(a.ray.origin, origin, 'Origin is correct');
        assert.equal(a.ray.direction, direction, 'Direction is correct');

        origin.set(1, 1, 1);
        direction.set(-1, 0, 0);
        a.set(origin, direction);

        assert.equal(a.ray.origin, origin, 'Origin was set correctly');
        assert.equal(a.ray.direction, direction, 'Direction was set correctly');
    }

    static public function setFromCameraPerspective():Void {
        var raycaster = new Raycaster();
        var rayDirection = raycaster.ray.direction;
        var camera = new PerspectiveCamera(90, 1, 1, 1000);

        raycaster.setFromCamera({ x: 0, y: 0 }, camera);
        assert.isTrue(rayDirection.x == 0 && rayDirection.y == 0 && rayDirection.z == -1, 'camera is looking straight to -z and so does the ray in the middle of the screen');

        var step = 0.1;

        for (var x = -1; x <= 1; x += step) {
            for (var y = -1; y <= 1; y += step) {
                raycaster.setFromCamera({ x: x, y: y }, camera);
                var refVector = new Vector3<Float>(x, y, -1).normalize();
                checkRayDirectionAgainstReferenceVector(rayDirection, refVector, assert);
            }
        }
    }

    static public function setFromCameraOrthographic():Void {
        var raycaster = new Raycaster();
        var rayOrigin = raycaster.ray.origin;
        var rayDirection = raycaster.ray.direction;
        var camera = new OrthographicCamera(-1, 1, 1, -1, 0, 1000);
        var expectedOrigin = new Vector3<Float>();
        var expectedDirection = new Vector3<Float>(0, 0, -1);

        raycaster.setFromCamera({ x: 0, y: 0 }, camera);
        assert.equal(rayOrigin, expectedOrigin, 'Ray origin has the right coordinates');
        assert.equal(rayDirection, expectedDirection, 'Camera and Ray are pointing towards -z');
    }

    static public function intersectObject():Void {
        var raycaster = getRaycaster();
        var objectsToCheck = getObjectsToCheck();

        assert.equal(raycaster.intersectObject(objectsToCheck[0], false).length, 1, 'no recursive search should lead to one hit');

        assert.equal(raycaster.intersectObject(objectsToCheck[0]).length, 3, 'recursive search should lead to three hits');

        var intersections = raycaster.intersectObject(objectsToCheck[0]);
        for (i in 0...intersections.length) {
            assert.isTrue(intersections[i].distance <= intersections[i + 1].distance, 'intersections are sorted');
        }
    }

    static public function intersectObjects():Void {
        var raycaster = getRaycaster();
        var objectsToCheck = getObjectsToCheck();

        assert.equal(raycaster.intersectObjects(objectsToCheck, false).length, 1, 'no recursive search should lead to one hit');

        assert.equal(raycaster.intersectObjects(objectsToCheck).length, 3, 'recursive search should lead to three hits');

        var intersections = raycaster.intersectObjects(objectsToCheck);
        for (i in 0...intersections.length) {
            assert.isTrue(intersections[i].distance <= intersections[i + 1].distance, 'intersections are sorted');
        }
    }

    static public function lineIntersectionThreshold():Void {
        var raycaster = getRaycaster();
        var points = [new Vector3<Float>(-2, -10, -5), new Vector3<Float>(-2, 10, -5)];
        var geometry = new BufferGeometry().setFromPoints(points);
        var line = new Line(geometry, null);

        raycaster.params.Line.threshold = 1.999;
        assert.equal(raycaster.intersectObject(line).length, 0, 'no Line intersection with a not-large-enough threshold');

        raycaster.params.Line.threshold = 2.001;
        assert.equal(raycaster.intersectObject(line).length, 1, 'successful Line intersection with a large-enough threshold');
    }

    static public function pointsIntersectionThreshold():Void {
        var raycaster = getRaycaster();
        var coordinates = [new Vector3<Float>(-2, 0, -5)];
        var geometry = new BufferGeometry().setFromPoints(coordinates);
        var points = new Points(geometry, null);

        raycaster.params.Points.threshold = 1.999;
        assert.equal(raycaster.intersectObject(points).length, 0, 'no Points intersection with a not-large-enough threshold');

        raycaster.params.Points.threshold = 2.001;
        assert.equal(raycaster.intersectObject(points).length, 1, 'successful Points intersection with a large-enough threshold');
    }
}