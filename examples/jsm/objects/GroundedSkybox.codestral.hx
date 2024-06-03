import js.three.Mesh;
import js.three.MeshBasicMaterial;
import js.three.SphereGeometry;
import js.three.Vector3;

/**
 * A ground-projected skybox. The height is how far the camera that took the photo was above the ground -
 * a larger value will magnify the downward part of the image. By default the object is centered at the camera,
 * so it is often helpful to set skybox.position.y = height to put the ground at the origin. Set the radius
 * large enough to ensure your user's camera stays inside.
 */

class GroundedSkybox extends Mesh {

    public function new(map:Texture, height:Float, radius:Float, resolution:Int = 128) {

        super();

        if (height <= 0 || radius <= 0 || resolution <= 0) {
            throw "GroundedSkybox height, radius, and resolution must be positive.";
        }

        var geometry = new SphereGeometry(radius, 2 * resolution, resolution);
        geometry.scale(1, 1, -1);

        var pos = geometry.getAttribute('position');
        var tmp = new Vector3();

        for (var i = 0; i < pos.count; ++i) {
            tmp.fromBufferAttribute(pos, i);
            if (tmp.y < 0) {
                // Smooth out the transition from flat floor to sphere:
                var y1 = -height * 3 / 2;
                var f = tmp.y < y1 ? -height / tmp.y : (1 - tmp.y * tmp.y / (3 * y1 * y1));
                tmp.multiplyScalar(f);
                tmp.toArray(pos.array, 3 * i);
            }
        }

        pos.needsUpdate = true;

        var material = new MeshBasicMaterial(js.Boot.typedMap({
            map: map,
            depthWrite: false
        }));

        this.geometry = geometry;
        this.material = material;
    }
}