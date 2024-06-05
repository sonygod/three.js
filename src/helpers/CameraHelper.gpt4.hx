import three.cameras.Camera;
import three.math.Vector3;
import three.objects.LineSegments;
import three.math.Color;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class CameraHelper extends LineSegments {

    var camera:Camera;
    var pointMap:Map<String, Array<Int>>;
    static var _vector:Vector3 = new Vector3();
    static var _camera:Camera = new Camera();

    public function new(camera:Camera) {
        var geometry = new BufferGeometry();
        var material = new LineBasicMaterial({ color: 0xffffff, vertexColors: true, toneMapped: false });

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        pointMap = new Map<String, Array<Int>>();

        // near
        addLine('n1', 'n2', vertices, colors);
        addLine('n2', 'n4', vertices, colors);
        addLine('n4', 'n3', vertices, colors);
        addLine('n3', 'n1', vertices, colors);

        // far
        addLine('f1', 'f2', vertices, colors);
        addLine('f2', 'f4', vertices, colors);
        addLine('f4', 'f3', vertices, colors);
        addLine('f3', 'f1', vertices, colors);

        // sides
        addLine('n1', 'f1', vertices, colors);
        addLine('n2', 'f2', vertices, colors);
        addLine('n3', 'f3', vertices, colors);
        addLine('n4', 'f4', vertices, colors);

        // cone
        addLine('p', 'n1', vertices, colors);
        addLine('p', 'n2', vertices, colors);
        addLine('p', 'n3', vertices, colors);
        addLine('p', 'n4', vertices, colors);

        // up
        addLine('u1', 'u2', vertices, colors);
        addLine('u2', 'u3', vertices, colors);
        addLine('u3', 'u1', vertices, colors);

        // target
        addLine('c', 't', vertices, colors);
        addLine('p', 'c', vertices, colors);

        // cross
        addLine('cn1', 'cn2', vertices, colors);
        addLine('cn3', 'cn4', vertices, colors);
        addLine('cf1', 'cf2', vertices, colors);
        addLine('cf3', 'cf4', vertices, colors);

        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        super(geometry, material);

        this.camera = camera;
        if (this.camera.updateProjectionMatrix != null) this.camera.updateProjectionMatrix();

        this.matrix = camera.matrixWorld;
        this.matrixAutoUpdate = false;

        this.update();

        // colors
        var colorFrustum = new Color(0xffaa00);
        var colorCone = new Color(0xff0000);
        var colorUp = new Color(0x00aaff);
        var colorTarget = new Color(0xffffff);
        var colorCross = new Color(0x333333);

        this.setColors(colorFrustum, colorCone, colorUp, colorTarget, colorCross);
    }

    function addLine(a:String, b:String, vertices:Array<Float>, colors:Array<Float>) {
        addPoint(a, vertices, colors);
        addPoint(b, vertices, colors);
    }

    function addPoint(id:String, vertices:Array<Float>, colors:Array<Float>) {
        vertices.push(0, 0, 0);
        colors.push(0, 0, 0);

        if (pointMap.exists(id) == false) {
            pointMap.set(id, []);
        }

        pointMap.get(id).push(Math.floor(vertices.length / 3) - 1);
    }

    public function setColors(frustum:Color, cone:Color, up:Color, target:Color, cross:Color) {
        var geometry = this.geometry;
        var colorAttribute = geometry.getAttribute('color');

        // near
        colorAttribute.setXYZ(0, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(1, frustum.r, frustum.g, frustum.b); // n1, n2
        colorAttribute.setXYZ(2, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(3, frustum.r, frustum.g, frustum.b); // n2, n4
        colorAttribute.setXYZ(4, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(5, frustum.r, frustum.g, frustum.b); // n4, n3
        colorAttribute.setXYZ(6, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(7, frustum.r, frustum.g, frustum.b); // n3, n1

        // far
        colorAttribute.setXYZ(8, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(9, frustum.r, frustum.g, frustum.b); // f1, f2
        colorAttribute.setXYZ(10, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(11, frustum.r, frustum.g, frustum.b); // f2, f4
        colorAttribute.setXYZ(12, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(13, frustum.r, frustum.g, frustum.b); // f4, f3
        colorAttribute.setXYZ(14, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(15, frustum.r, frustum.g, frustum.b); // f3, f1

        // sides
        colorAttribute.setXYZ(16, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(17, frustum.r, frustum.g, frustum.b); // n1, f1
        colorAttribute.setXYZ(18, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(19, frustum.r, frustum.g, frustum.b); // n2, f2
        colorAttribute.setXYZ(20, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(21, frustum.r, frustum.g, frustum.b); // n3, f3
        colorAttribute.setXYZ(22, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(23, frustum.r, frustum.g, frustum.b); // n4, f4

        // cone
        colorAttribute.setXYZ(24, cone.r, cone.g, cone.b); colorAttribute.setXYZ(25, cone.r, cone.g, cone.b); // p, n1
        colorAttribute.setXYZ(26, cone.r, cone.g, cone.b); colorAttribute.setXYZ(27, cone.r, cone.g, cone.b); // p, n2
        colorAttribute.setXYZ(28, cone.r, cone.g, cone.b); colorAttribute.setXYZ(29, cone.r, cone.g, cone.b); // p, n3
        colorAttribute.setXYZ(30, cone.r, cone.g, cone.b); colorAttribute.setXYZ(31, cone.r, cone.g, cone.b); // p, n4

        // up
        colorAttribute.setXYZ(32, up.r, up.g, up.b); colorAttribute.setXYZ(33, up.r, up.g, up.b); // u1, u2
        colorAttribute.setXYZ(34, up.r, up.g, up.b); colorAttribute.setXYZ(35, up.r, up.g, up.b); // u2, u3
        colorAttribute.setXYZ(36, up.r, up.g, up.b); colorAttribute.setXYZ(37, up.r, up.g, up.b); // u3, u1

        // target
        colorAttribute.setXYZ(38, target.r, target.g, target.b); colorAttribute.setXYZ(39, target.r, target.g, target.b); // c, t
        colorAttribute.setXYZ(40, cross.r, cross.g, cross.b); colorAttribute.setXYZ(41, cross.r, cross.g, cross.b); // p, c

        // cross
        colorAttribute.setXYZ(42, cross.r, cross.g, cross.b); colorAttribute.setXYZ(43, cross.r, cross.g, cross.b); // cn1, cn2
        colorAttribute.setXYZ(44, cross.r, cross.g, cross.b); colorAttribute.setXYZ(45, cross.r, cross.g, cross.b); // cn3, cn4
        colorAttribute.setXYZ(46, cross.r, cross.g, cross.b); colorAttribute.setXYZ(47, cross.r, cross.g, cross.b); // cf1, cf2
        colorAttribute.setXYZ(48, cross.r, cross.g, cross.b); colorAttribute.setXYZ(49, cross.r, cross.g, cross.b); // cf3, cf4

        colorAttribute.needsUpdate = true;
    }

    public function update() {
        var geometry = this.geometry;
        var pointMap = this.pointMap;

        var w = 1, h = 1;

        // we need just camera projection matrix inverse
        // world matrix must be identity
        _camera.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse);

        // center / target
        setPoint('c', pointMap, geometry, _camera, 0, 0, -1);
        setPoint('t', pointMap, geometry, _camera, 0, 0, 1);

        // near
        setPoint('n1', pointMap, geometry, _camera, -w, -h, -1);
        setPoint('n2', pointMap, geometry, _camera, w, -h, -1);
        setPoint('n3', pointMap, geometry, _camera, -w, h, -1);
        setPoint('n4', pointMap, geometry, _camera, w, h, -1);

        // far
        setPoint('f1', pointMap, geometry, _camera, -w, -h, 1);
        setPoint('f2', pointMap, geometry, _camera, w, -h, 1);
        setPoint('f3', pointMap, geometry, _camera, -w, h, 1);
        setPoint('f4', pointMap, geometry, _camera, w, h, 1);

        // up
        setPoint('u1', pointMap, geometry, _camera, w * 0.7, h * 1.1, -1);
        setPoint('u2', pointMap, geometry, _camera, -w * 0.7, h * 1.1, -1);
        setPoint('u3', pointMap, geometry, _camera, 0, h * 2, -1);

        // cross
        setPoint('cf1', pointMap, geometry, _camera, -w, 0, 1);
        setPoint('cf2', pointMap, geometry, _camera, w, 0, 1);
        setPoint('cf3', pointMap, geometry, _camera, 0, -h, 1);
        setPoint('cf4', pointMap, geometry, _camera, 0, h, 1);

        setPoint('cn1', pointMap, geometry, _camera, -w, 0, -1);
        setPoint('cn2', pointMap, geometry, _camera, w, 0, -1);
        setPoint('cn3', pointMap, geometry, _camera, 0, -h, -1);
        setPoint('cn4', pointMap, geometry, _camera, 0, h, -1);

        geometry.getAttribute('position').needsUpdate = true;
    }

    public function dispose() {
        this.geometry.dispose();
        this.material.dispose();
    }
}

function setPoint(point:String, pointMap:Map<String, Array<Int>>, geometry:BufferGeometry, camera:Camera, x:Float, y:Float, z:Float) {
    _vector.set(x, y, z).unproject(camera);

    var points = pointMap.get(point);

    if (points != null) {
        var position = geometry.getAttribute('position');

        for (i in 0...points.length) {
            position.setXYZ(points[i], _vector.x, _vector.y, _vector.z);
        }
    }
}