import js.Browser.document;
import js.html.Window;
import js.html.HtmlElement;
import js.html.InputElement;
import js.html.CanvasElement;

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

    static function checkRayDirectionAgainstReferenceVector(rayDirection:Vector3, refVector:Vector3, assert:Function):Void {
        assert(Math.abs(refVector.x - rayDirection.x) <= Number.EPSILON && Math.abs(refVector.y - rayDirection.y) <= Number.EPSILON && Math.abs(refVector.z - rayDirection.z) <= Number.EPSILON, 'camera is pointing to the same direction as expected');
    }

    static function getRaycaster():Raycaster {
        return new Raycaster(new Vector3(0, 0, 0), new Vector3(0, 0, -1), 1, 100);
    }

    static function getObjectsToCheck():Array<Mesh> {
        var objects = new Array<Mesh>();

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

        for (var i in 0...objects.length) {
            objects[i].updateMatrixWorld();
        }

        return objects;
    }

    static function getSphere():Mesh {
        return new Mesh(new SphereGeometry(1, 100, 100));
    }

    static function main() {
        // INSTANCING
        var object = new Raycaster();
        js.Boot.trace('Can instantiate a Raycaster.', object);

        // PUBLIC
        var origin = new Vector3(0, 0, 0);
        var direction = new Vector3(0, 0, -1);
        var a = new Raycaster(origin.clone(), direction.clone());

        js.Boot.trace('Origin is correct', a.ray.origin);
        js.Boot.trace('Direction is correct', a.ray.direction);

        origin.set(1, 1, 1);
        direction.set(-1, 0, 0);
        a.set(origin, direction);

        js.Boot.trace('Origin was set correctly', a.ray.origin);
        js.Boot.trace('Direction was set correctly', a.ray.direction);

        var raycaster = getRaycaster();
        var objectsToCheck = getObjectsToCheck();

        js.Boot.trace('no recursive search should lead to one hit', raycaster.intersectObject(objectsToCheck[0], false).length === 1);
        js.Boot.trace('recursive search should lead to three hits', raycaster.intersectObject(objectsToCheck[0]).length === 3);

        var intersections = raycaster.intersectObject(objectsToCheck[0]);
        for (var i in 0...intersections.length - 1) {
            js.Boot.trace('intersections are sorted', intersections[i].distance <= intersections[i + 1].distance);
        }
    }
}