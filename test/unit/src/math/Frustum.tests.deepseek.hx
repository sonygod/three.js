package;

import three.math.Frustum;
import three.math.Sphere;
import three.math.Plane;
import three.objects.Sprite;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Box3;
import three.objects.Mesh;
import three.geometries.BoxGeometry;
import utils.math.MathConstants;

class FrustumTests {

    static function main() {

        var unit3 = new Vector3(1, 0, 0);

        var pDefault = new Plane();
        var p0 = new Plane(unit3, -1);
        var p1 = new Plane(unit3, 1);
        var p2 = new Plane(unit3, 2);
        var p3 = new Plane(unit3, 3);
        var p4 = new Plane(unit3, 4);
        var p5 = new Plane(unit3, 5);

        var a = new Frustum();
        assert(a.planes.length == 6);
        for (i in 0...6) {
            assert(a.planes[i].equals(pDefault));
        }

        a = new Frustum(p0, p1, p2, p3, p4, p5);
        assert(a.planes[0].equals(p0));
        assert(a.planes[1].equals(p1));
        assert(a.planes[2].equals(p2));
        assert(a.planes[3].equals(p3));
        assert(a.planes[4].equals(p4));
        assert(a.planes[5].equals(p5));

        var b = new Frustum(p0, p1, p2, p3, p4, p5);
        var a = b.clone();
        assert(a.planes[0].equals(p0));
        assert(a.planes[1].equals(p1));
        assert(a.planes[2].equals(p2));
        assert(a.planes[3].equals(p3));
        assert(a.planes[4].equals(p4));
        assert(a.planes[5].equals(p5));

        a.planes[0] = p1;
        assert(b.planes[0].equals(p0));

        var m = new Matrix4().makeOrthographic(-1, 1, -1, 1, 1, 100);
        a = new Frustum().setFromProjectionMatrix(m);
        assert(!a.containsPoint(new Vector3(0, 0, 0)));
        assert(a.containsPoint(new Vector3(0, 0, -50)));
        assert(a.containsPoint(new Vector3(0, 0, -1.001)));
        assert(a.containsPoint(new Vector3(-1, -1, -1.001)));
        assert(!a.containsPoint(new Vector3(-1.1, -1.1, -1.001)));
        assert(a.containsPoint(new Vector3(1, 1, -1.001)));
        assert(!a.containsPoint(new Vector3(1.1, 1.1, -1.001)));
        assert(a.containsPoint(new Vector3(0, 0, -100)));
        assert(a.containsPoint(new Vector3(-1, -1, -100)));
        assert(!a.containsPoint(new Vector3(-1.1, -1.1, -100.1)));
        assert(a.containsPoint(new Vector3(1, 1, -100)));
        assert(!a.containsPoint(new Vector3(1.1, 1.1, -100.1)));
        assert(!a.containsPoint(new Vector3(0, 0, -101)));

        m = new Matrix4().makePerspective(-1, 1, 1, -1, 1, 100);
        a = new Frustum().setFromProjectionMatrix(m);
        assert(!a.containsPoint(new Vector3(0, 0, 0)));
        assert(a.containsPoint(new Vector3(0, 0, -50)));
        assert(a.containsPoint(new Vector3(0, 0, -1.001)));
        assert(a.containsPoint(new Vector3(-1, -1, -1.001)));
        assert(!a.containsPoint(new Vector3(-1.1, -1.1, -1.001)));
        assert(a.containsPoint(new Vector3(1, 1, -1.001)));
        assert(!a.containsPoint(new Vector3(1.1, 1.1, -1.001)));
        assert(a.containsPoint(new Vector3(0, 0, -99.999)));
        assert(a.containsPoint(new Vector3(-99.999, -99.999, -99.999)));
        assert(!a.containsPoint(new Vector3(-100.1, -100.1, -100.1)));
        assert(a.containsPoint(new Vector3(99.999, 99.999, -99.999)));
        assert(!a.containsPoint(new Vector3(100.1, 100.1, -100.1)));
        assert(!a.containsPoint(new Vector3(0, 0, -101)));

        var object = new Mesh(new BoxGeometry(1, 1, 1));
        var intersects = a.intersectsObject(object);
        assert(!intersects);

        object.position.set(-1, -1, -1);
        object.updateMatrixWorld();

        intersects = a.intersectsObject(object);
        assert(intersects);

        object.position.set(1, 1, 1);
        object.updateMatrixWorld();

        intersects = a.intersectsObject(object);
        assert(!intersects);

        var sprite = new Sprite();
        intersects = a.intersectsSprite(sprite);
        assert(!intersects);

        sprite.position.set(-1, -1, -1);
        sprite.updateMatrixWorld();

        intersects = a.intersectsSprite(sprite);
        assert(intersects);

        var box = new Box3(MathConstants.zero3.clone(), MathConstants.one3.clone());
        intersects = a.intersectsBox(box);
        assert(!intersects);

        box.translate(new Vector3(-1 - MathConstants.eps, -1 - MathConstants.eps, -1 - MathConstants.eps));

        intersects = a.intersectsBox(box);
        assert(intersects);

    }

}