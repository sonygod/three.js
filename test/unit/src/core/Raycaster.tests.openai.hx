package three.js.test.unit.src.core;

import three.core.Raycaster;
import three.math.Vector3;
import three.objects.Mesh;
import three.geometries.SphereGeometry;
import three.core.BufferGeometry;
import three.objects.Line;
import three.objects.Points;
import three.cameras.PerspectiveCamera;
import three.cameras.OrthographicCamera;

class RaycasterTests {

    public static function checkRayDirectionAgainstReferenceVector(rayDirection:Vector3, refVector:Vector3, assert:Assert) {
        assert.ok(Math.abs(refVector.x - rayDirection.x) <= Math.POSITIVE_INFINITY && 
                   Math.abs(refVector.y - rayDirection.y) <= Math.POSITIVE_INFINITY && 
                   Math.abs(refVector.z - rayDirection.z) <= Math.POSITIVE_INFINITY, 
                   'camera is pointing to the same direction as expected');
    }

    public static function getRaycaster():Raycaster {
        return new Raycaster(new Vector3(0, 0, 0), new Vector3(0, 0, -1), 1, 100);
    }

    public static function getObjectsToCheck():Array<Mesh> {
        var objects:Array<Mesh> = new Array();

        var sphere1:Mesh = getSphere();
        sphere1.position.set(0, 0, -10);
        sphere1.name = '1';
        objects.push(sphere1);

        var sphere11:Mesh = getSphere();
        sphere11.position.set(0, 0, 1);
        sphere11.name = '11';
        sphere1.add(sphere11);

        var sphere12:Mesh = getSphere();
        sphere12.position.set(0, 0, -1);
        sphere12.name = '12';
        sphere1.add(sphere12);

        var sphere2:Mesh = getSphere();
        sphere2.position.set(-5, 0, -5);
        sphere2.name = '2';
        objects.push(sphere2);

        for (i in 0...objects.length) {
            objects[i].updateMatrixWorld();
        }

        return objects;
    }

    public static function getSphere():Mesh {
        return new Mesh(new SphereGeometry(1, 100, 100));
    }

    public static function main() {
        Main.tests.push(new Test("Core", [
            new TestCase("Raycaster", [
                new Test("Instancing", function(assert) {
                    var object:Raycaster = new Raycaster();
                    assert.ok(object != null, 'Can instantiate a Raycaster.');
                }),
                new Test("set", function(assert) {
                    var origin:Vector3 = new Vector3(0, 0, 0);
                    var direction:Vector3 = new Vector3(0, 0, -1);
                    var a:Raycaster = new Raycaster(origin.clone(), direction.clone());

                    assert.deepEqual(a.ray.origin, origin, 'Origin is correct');
                    assert.deepEqual(a.ray.direction, direction, 'Direction is correct');

                    origin.set(1, 1, 1);
                    direction.set(-1, 0, 0);
                    a.set(origin, direction);

                    assert.deepEqual(a.ray.origin, origin, 'Origin was set correctly');
                    assert.deepEqual(a.ray.direction, direction, 'Direction was set correctly');
                }),
                new Test("setFromCamera (Perspective)", function(assert) {
                    var raycaster:Raycaster = new Raycaster();
                    var rayDirection:Vector3 = raycaster.ray.direction;
                    var camera:PerspectiveCamera = new PerspectiveCamera(90, 1, 1, 1000);

                    raycaster.setFromCamera({
                        x: 0,
                        y: 0
                    }, camera);
                    assert.ok(rayDirection.x == 0 && rayDirection.y == 0 && rayDirection.z == -1,
                              'camera is looking straight to -z and so does the ray in the middle of the screen');

                    var step:Float = 0.1;

                    for (x in -1...1.1) {
                        for (y in -1...1.1) {
                            raycaster.setFromCamera({
                                x: x,
                                y: y
                            }, camera);

                            var refVector:Vector3 = new Vector3(x, y, -1).normalize();

                            checkRayDirectionAgainstReferenceVector(rayDirection, refVector, assert);
                        }
                    }
                }),
                new Test("setFromCamera (Orthographic)", function(assert) {
                    var raycaster:Raycaster = new Raycaster();
                    var rayOrigin:Vector3 = raycaster.ray.origin;
                    var rayDirection:Vector3 = raycaster.ray.direction;
                    var camera:OrthographicCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1000);
                    var expectedOrigin:Vector3 = new Vector3(0, 0, 0);
                    var expectedDirection:Vector3 = new Vector3(0, 0, -1);

                    raycaster.setFromCamera({
                        x: 0,
                        y: 0
                    }, camera);
                    assert.deepEqual(rayOrigin, expectedOrigin, 'Ray origin has the right coordinates');
                    assert.deepEqual(rayDirection, expectedDirection, 'Camera and Ray are pointing towards -z');
                }),
                new Test("intersectObject", function(assert) {
                    var raycaster:Raycaster = getRaycaster();
                    var objectsToCheck:Array<Mesh> = getObjectsToCheck();

                    assert.ok(raycaster.intersectObject(objectsToCheck[0], false).length == 1,
                              'no recursive search should lead to one hit');

                    assert.ok(raycaster.intersectObject(objectsToCheck[0]).length == 3,
                              'recursive search should lead to three hits');

                    var intersections:Array<Intersection> = raycaster.intersectObject(objectsToCheck[0]);
                    for (i in 0...intersections.length - 1) {
                        assert.ok(intersections[i].distance <= intersections[i + 1].distance,
                                  'intersections are sorted');
                    }
                }),
                new Test("intersectObjects", function(assert) {
                    var raycaster:Raycaster = getRaycaster();
                    var objectsToCheck:Array<Mesh> = getObjectsToCheck();

                    assert.ok(raycaster.intersectObjects(objectsToCheck, false).length == 1,
                              'no recursive search should lead to one hit');

                    assert.ok(raycaster.intersectObjects(objectsToCheck).length == 3,
                              'recursive search should lead to three hits');

                    var intersections:Array<Intersection> = raycaster.intersectObjects(objectsToCheck);
                    for (i in 0...intersections.length - 1) {
                        assert.ok(intersections[i].distance <= intersections[i + 1].distance,
                                  'intersections are sorted');
                    }
                }),
                new Test("Line intersection threshold", function(assert) {
                    var raycaster:Raycaster = getRaycaster();
                    var points:Array<Vector3> = [new Vector3(-2, -10, -5), new Vector3(-2, 10, -5)];
                    var geometry:BufferGeometry = new BufferGeometry().setFromPoints(points);
                    var line:Line = new Line(geometry, null);

                    raycaster.params.Line.threshold = 1.999;
                    assert.ok(raycaster.intersectObject(line).length == 0,
                              'no Line intersection with a not-large-enough threshold');

                    raycaster.params.Line.threshold = 2.001;
                    assert.ok(raycaster.intersectObject(line).length == 1,
                              'successful Line intersection with a large-enough threshold');
                }),
                new Test("Points intersection threshold", function(assert) {
                    var raycaster:Raycaster = getRaycaster();
                    var coordinates:Array<Vector3> = [new Vector3(-2, 0, -5)];
                    var geometry:BufferGeometry = new BufferGeometry().setFromPoints(coordinates);
                    var points:Points = new Points(geometry, null);

                    raycaster.params.Points.threshold = 1.999;
                    assert.ok(raycaster.intersectObject(points).length == 0,
                              'no Points intersection with a not-large-enough threshold');

                    raycaster.params.Points.threshold = 2.001;
                    assert.ok(raycaster.intersectObject(points).length == 1,
                              'successful Points intersection with a large-enough threshold');
                }),
            ])
        ]));
    }
}