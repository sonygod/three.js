import three.math.Frustum;
import three.math.Sphere;
import three.math.Plane;
import three.objects.Sprite;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Box3;
import three.objects.Mesh;
import three.geometries.BoxGeometry;
import three.math.Vector3Constants;

class FrustumTests {
    public function new() {
        var unit3 = new Vector3(1, 0, 0);

        var a = new Frustum();
        trace(a.planes != null, "Passed!");
        trace(a.planes.length == 6, "Passed!");

        var pDefault = new Plane();
        for (i in 0 ... 6) {
            trace(a.planes[i].equals(pDefault), "Passed!");
        }

        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        a = new Frustum(p0, p1, p2, p3, p4, p5);
        trace(a.planes[0].equals(p0), "Passed!");
        trace(a.planes[1].equals(p1), "Passed!");
        trace(a.planes[2].equals(p2), "Passed!");
        trace(a.planes[3].equals(p3), "Passed!");
        trace(a.planes[4].equals(p4), "Passed!");
        trace(a.planes[5].equals(p5), "Passed!");

        a.set(p0, p1, p2, p3, p4, p5);
        trace(a.planes[0].equals(p0), "Check plane #0");
        trace(a.planes[1].equals(p1), "Check plane #1");
        trace(a.planes[2].equals(p2), "Check plane #2");
        trace(a.planes[3].equals(p3), "Check plane #3");
        trace(a.planes[4].equals(p4), "Check plane #4");
        trace(a.planes[5].equals(p5), "Check plane #5");

        var b = new Frustum(p0, p1, p2, p3, p4, p5);
        var c = b.clone();
        trace(c.planes[0].equals(p0), "Passed!");
        trace(c.planes[1].equals(p1), "Passed!");
        trace(c.planes[2].equals(p2), "Passed!");
        trace(c.planes[3].equals(p3), "Passed!");
        trace(c.planes[4].equals(p4), "Passed!");
        trace(c.planes[5].equals(p5), "Passed!");

        c.planes[0].copy(p1);
        trace(b.planes[0].equals(p0), "Passed!");

        var d = new Frustum().copy(b);
        trace(d.planes[0].equals(p0), "Passed!");

        b.planes[0] = p1;
        trace(d.planes[0].equals(p0), "Passed!");

        var m = new Matrix4().makeOrthographic(-1, 1, -1, 1, 1, 100);
        var e = new Frustum().setFromProjectionMatrix(m);

        trace(!e.containsPoint(new Vector3(0, 0, 0)), "Passed!");
        trace(e.containsPoint(new Vector3(0, 0, -50)), "Passed!");
        trace(e.containsPoint(new Vector3(0, 0, -1.001)), "Passed!");
        trace(e.containsPoint(new Vector3(-1, -1, -1.001)), "Passed!");
        trace(!e.containsPoint(new Vector3(-1.1, -1.1, -1.001)), "Passed!");
        trace(e.containsPoint(new Vector3(1, 1, -1.001)), "Passed!");
        trace(!e.containsPoint(new Vector3(1.1, 1.1, -1.001)), "Passed!");
        trace(e.containsPoint(new Vector3(0, 0, -100)), "Passed!");
        trace(e.containsPoint(new Vector3(-1, -1, -100)), "Passed!");
        trace(!e.containsPoint(new Vector3(-1.1, -1.1, -100.1)), "Passed!");
        trace(e.containsPoint(new Vector3(1, 1, -100)), "Passed!");
        trace(!e.containsPoint(new Vector3(1.1, 1.1, -100.1)), "Passed!");
        trace(!e.containsPoint(new Vector3(0, 0, -101)), "Passed!");

        m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        var f = new Frustum().setFromProjectionMatrix(m);

        trace(!f.containsPoint(new Vector3(0, 0, 0)), "Passed!");
        trace(f.containsPoint(new Vector3(0, 0, -50)), "Passed!");
        trace(f.containsPoint(new Vector3(0, 0, -1.001)), "Passed!");
        trace(f.containsPoint(new Vector3(-1, -1, -1.001)), "Passed!");
        trace(!f.containsPoint(new Vector3(-1.1, -1.1, -1.001)), "Passed!");
        trace(f.containsPoint(new Vector3(1, 1, -1.001)), "Passed!");
        trace(!f.containsPoint(new Vector3(1.1, 1.1, -1.001)), "Passed!");
        trace(f.containsPoint(new Vector3(0, 0, -99.999)), "Passed!");
        trace(f.containsPoint(new Vector3(-99.999, -99.999, -99.999)), "Passed!");
        trace(!f.containsPoint(new Vector3(-100.1, -100.1, -100.1)), "Passed!");
        trace(f.containsPoint(new Vector3(99.999, 99.999, -99.999)), "Passed!");
        trace(!f.containsPoint(new Vector3(100.1, 100.1, -100.1)), "Passed!");
        trace(!f.containsPoint(new Vector3(0, 0, -101)), "Passed!");

        trace(!f.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 0)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 0.9)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(0, 0, 0), 1.1)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(0, 0, -50), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(0, 0, -1.001), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(-1, -1, -1.001), 0)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(-1.1, -1.1, -1.001), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(-1.1, -1.1, -1.001), 0.5)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(1, 1, -1.001), 0)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(1.1, 1.1, -1.001), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(1.1, 1.1, -1.001), 0.5)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(0, 0, -99.999), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(-99.999, -99.999, -99.999), 0)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(-100.1, -100.1, -100.1), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(-100.1, -100.1, -100.1), 0.5)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(99.999, 99.999, -99.999), 0)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(100.1, 100.1, -100.1), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(100.1, 100.1, -100.1), 0.2)), "Passed!");
        trace(!f.intersectsSphere(new Sphere(new Vector3(0, 0, -101), 0)), "Passed!");
        trace(f.intersectsSphere(new Sphere(new Vector3(0, 0, -101), 1.1)), "Passed!");

        var object = new Mesh(new BoxGeometry(1, 1, 1));
        var intersects = f.intersectsObject(object);
        trace(!intersects, "No intersection");

        object.position.set(-1, -1, -1);
        object.updateMatrixWorld();

        intersects = f.intersectsObject(object);
        trace(intersects, "Successful intersection");

        object.position.set(1, 1, 1);
        object.updateMatrixWorld();

        intersects = f.intersectsObject(object);
        trace(!intersects, "No intersection");

        var sprite = new Sprite();
        intersects = f.intersectsSprite(sprite);
        trace(!intersects, "No intersection");

        sprite.position.set(-1, -1, -1);
        sprite.updateMatrixWorld();

        intersects = f.intersectsSprite(sprite);
        trace(intersects, "Successful intersection");

        var box = new Box3(Vector3Constants.zero.clone(), Vector3Constants.one.clone());
        intersects = f.intersectsBox(box);
        trace(!intersects, "No intersection");

        box.translate(new Vector3(-1 - Vector3Constants.EPS, -1 - Vector3Constants.EPS, -1 - Vector3Constants.EPS));

        intersects = f.intersectsBox(box);
        trace(intersects, "Successful intersection");
    }
}