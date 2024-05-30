import three.cameras.Camera;
import three.math.Vector3;
import three.objects.LineSegments;
import three.math.Color;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class CameraHelper extends LineSegments {
    private var camera: Camera;
    private var pointMap: Map<String, Array<Int>>;

    private static var _vector: Vector3 = new Vector3();
    private static var _camera: Camera = new Camera();

    public function new(camera: Camera) {
        var geometry = new BufferGeometry();
        var material = new LineBasicMaterial({color: 0xffffff, vertexColors: true, toneMapped: false});

        var vertices = [];
        var colors = [];
        pointMap = new Map();

        addLine("n1", "n2");
        addLine("n2", "n4");
        addLine("n4", "n3");
        addLine("n3", "n1");

        addLine("f1", "f2");
        addLine("f2", "f4");
        addLine("f4", "f3");
        addLine("f3", "f1");

        addLine("n1", "f1");
        addLine("n2", "f2");
        addLine("n3", "f3");
        addLine("n4", "f4");

        addLine("p", "n1");
        addLine("p", "n2");
        addLine("p", "n3");
        addLine("p", "n4");

        addLine("u1", "u2");
        addLine("u2", "u3");
        addLine("u3", "u1");

        addLine("c", "t");
        addLine("p", "c");

        addLine("cn1", "cn2");
        addLine("cn3", "cn4");

        addLine("cf1", "cf2");
        addLine("cf3", "cf4");

        function addLine(a: String, b: String): Void {
            addPoint(a);
            addPoint(b);
        }

        function addPoint(id: String): Void {
            vertices.push(0, 0, 0);
            colors.push(0, 0, 0);

            if (!pointMap.exists(id)) {
                pointMap.set(id, []);
            }

            pointMap.get(id).push((vertices.length / 3) - 1);
        }

        geometry.setAttribute("position", new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute("color", new Float32BufferAttribute(colors, 3));

        super(geometry, material);

        this.camera = camera;
        if (this.camera.updateProjectionMatrix != null) this.camera.updateProjectionMatrix();

        this.matrix = camera.matrixWorld;
        this.matrixAutoUpdate = false;

        this.update();

        var colorFrustum = new Color(0xffaa00);
        var colorCone = new Color(0xff0000);
        var colorUp = new Color(0x00aaff);
        var colorTarget = new Color(0xffffff);
        var colorCross = new Color(0x333333);

        this.setColors(colorFrustum, colorCone, colorUp, colorTarget, colorCross);
    }

    public function setColors(frustum: Color, cone: Color, up: Color, target: Color, cross: Color): Void {
        var geometry = this.geometry;
        var colorAttribute = geometry.getAttribute("color");

        function setColor(idx: Int, color: Color): Void {
            colorAttribute.setXYZ(idx, color.r, color.g, color.b);
        }

        // near
        setColor(0, frustum); setColor(1, frustum); // n1, n2
        setColor(2, frustum); setColor(3, frustum); // n2, n4
        setColor(4, frustum); setColor(5, frustum); // n4, n3
        setColor(6, frustum); setColor(7, frustum); // n3, n1

        // far
        setColor(8, frustum); setColor(9, frustum); // f1, f2
        setColor(10, frustum); setColor(11, frustum); // f2, f4
        setColor(12, frustum); setColor(13, frustum); // f4, f3
        setColor(14, frustum); setColor(15, frustum); // f3, f1

        // sides
        setColor(16, frustum); setColor(17, frustum); // n1, f1
        setColor(18, frustum); setColor(19, frustum); // n2, f2
        setColor(20, frustum); setColor(21, frustum); // n3, f3
        setColor(22, frustum); setColor(23, frustum); // n4, f4

        // cone
        setColor(24, cone); setColor(25, cone); // p, n1
        setColor(26, cone); setColor(27, cone); // p, n2
        setColor(28, cone); setColor(29, cone); // p, n3
        setColor(30, cone); setColor(31, cone); // p, n4

        // up
        setColor(32, up); setColor(33, up); // u1, u2
        setColor(34, up); setColor(35, up); // u2, u3
        setColor(36, up); setColor(37, up); // u3, u1

        // target
        setColor(38, target); setColor(39, target); // c, t
        setColor(40, cross); setColor(41, cross); // p, c

        // cross
        setColor(42, cross); setColor(43, cross); // cn1, cn2
        setColor(44, cross); setColor(45, cross); // cn3, cn4

        setColor(46, cross); setColor(47, cross); // cf1, cf2
        setColor(48, cross); setColor(49, cross); // cf3, cf4

        colorAttribute.needsUpdate = true;
    }

    public function update(): Void {
        var geometry = this.geometry;
        var w = 1, h = 1;

        _camera.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse);

        setPoint("c", 0, 0, -1);
        setPoint("t", 0, 0, 1);

        setPoint("n1", -w, -h, -1);
        setPoint("n2", w, -h, -1);
        setPoint("n3", -w, h, -1);
        setPoint("n4", w, h, -1);

        setPoint("f1", -w, -h, 1);
        setPoint("f2", w, -h, 1);
        setPoint("f3", -w, h, 1);
        setPoint("f4", w, h, 1);

        setPoint("u1", w * 0.7, h * 1.1, -1);
        setPoint("u2", -w * 0.7, h * 1.1, -1);
        setPoint("u3", 0, h * 2, -1);

        setPoint("cf1", -w, 0, 1);
        setPoint("cf2", w, 0, 1);
        setPoint("cf3", 0, -h, 1);
        setPoint("cf4", 0, h, 1);

        setPoint("cn1", -w, 0, -1);
        setPoint("cn2", w, 0, -1);
        setPoint("cn3", 0, -h, -1);
        setPoint("cn4", 0, h, -1);

        geometry.getAttribute("position").needsUpdate = true;
    }

    public function dispose(): Void {
        this.geometry.dispose();
        this.material.dispose();
    }

    private function setPoint(point: String, x: Float, y: Float, z: Float): Void {
        _vector.set(x, y, z).unproject(_camera);

        var points = pointMap.get(point);
        if (points != null) {
            var position = this.geometry.getAttribute("position");

            for (i in points) {
                position.setXYZ(i, _vector.x, _vector.y, _vector.z);
            }
        }
    }
}