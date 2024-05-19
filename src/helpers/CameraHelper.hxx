import three.cameras.Camera;
import three.math.Vector3;
import three.objects.LineSegments;
import three.math.Color;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class CameraHelper extends LineSegments {

    public function new(camera:Camera) {

        var geometry = new BufferGeometry();
        var material = new LineBasicMaterial({color: 0xffffff, vertexColors: true, toneMapped: false});

        var vertices:Array<Float> = [];
        var colors:Array<Float> = [];

        var pointMap:Map<String, Array<Int>> = new Map();

        addLine('n1', 'n2');
        addLine('n2', 'n4');
        addLine('n4', 'n3');
        addLine('n3', 'n1');

        addLine('f1', 'f2');
        addLine('f2', 'f4');
        addLine('f4', 'f3');
        addLine('f3', 'f1');

        addLine('n1', 'f1');
        addLine('n2', 'f2');
        addLine('n3', 'f3');
        addLine('n4', 'f4');

        addLine('p', 'n1');
        addLine('p', 'n2');
        addLine('p', 'n3');
        addLine('p', 'n4');

        addLine('u1', 'u2');
        addLine('u2', 'u3');
        addLine('u3', 'u1');

        addLine('c', 't');
        addLine('p', 'c');

        addLine('cn1', 'cn2');
        addLine('cn3', 'cn4');

        addLine('cf1', 'cf2');
        addLine('cf3', 'cf4');

        function addLine(a:String, b:String) {

            addPoint(a);
            addPoint(b);

        }

        function addPoint(id:String) {

            vertices.push(0, 0, 0);
            colors.push(0, 0, 0);

            if (!pointMap.exists(id)) {

                pointMap.set(id, []);

            }

            pointMap.get(id).push((vertices.length / 3) - 1);

        }

        geometry.setAttribute('position', new Float32BufferAttribute(vertices, 3));
        geometry.setAttribute('color', new Float32BufferAttribute(colors, 3));

        super(geometry, material);

        this.type = 'CameraHelper';

        this.camera = camera;
        if (this.camera.updateProjectionMatrix) this.camera.updateProjectionMatrix();

        this.matrix = camera.matrixWorld;
        this.matrixAutoUpdate = false;

        this.pointMap = pointMap;

        this.update();

        var colorFrustum = new Color(0xffaa00);
        var colorCone = new Color(0xff0000);
        var colorUp = new Color(0x00aaff);
        var colorTarget = new Color(0xffffff);
        var colorCross = new Color(0x333333);

        this.setColors(colorFrustum, colorCone, colorUp, colorTarget, colorCross);

    }

    public function setColors(frustum:Color, cone:Color, up:Color, target:Color, cross:Color) {

        var geometry = this.geometry;

        var colorAttribute = geometry.getAttribute('color');

        colorAttribute.setXYZ(0, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(1, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(2, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(3, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(4, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(5, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(6, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(7, frustum.r, frustum.g, frustum.b);

        colorAttribute.setXYZ(8, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(9, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(10, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(11, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(12, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(13, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(14, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(15, frustum.r, frustum.g, frustum.b);

        colorAttribute.setXYZ(16, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(17, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(18, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(19, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(20, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(21, frustum.r, frustum.g, frustum.b);
        colorAttribute.setXYZ(22, frustum.r, frustum.g, frustum.b); colorAttribute.setXYZ(23, frustum.r, frustum.g, frustum.b);

        colorAttribute.setXYZ(24, cone.r, cone.g, cone.b); colorAttribute.setXYZ(25, cone.r, cone.g, cone.b);
        colorAttribute.setXYZ(26, cone.r, cone.g, cone.b); colorAttribute.setXYZ(27, cone.r, cone.g, cone.b);
        colorAttribute.setXYZ(28, cone.r, cone.g, cone.b); colorAttribute.setXYZ(29, cone.r, cone.g, cone.b);
        colorAttribute.setXYZ(30, cone.r, cone.g, cone.b); colorAttribute.setXYZ(31, cone.r, cone.g, cone.b);

        colorAttribute.setXYZ(32, up.r, up.g, up.b); colorAttribute.setXYZ(33, up.r, up.g, up.b);
        colorAttribute.setXYZ(34, up.r, up.g, up.b); colorAttribute.setXYZ(35, up.r, up.g, up.b);
        colorAttribute.setXYZ(36, up.r, up.g, up.b); colorAttribute.setXYZ(37, up.r, up.g, up.b);

        colorAttribute.setXYZ(38, target.r, target.g, target.b); colorAttribute.setXYZ(39, target.r, target.g, target.b);
        colorAttribute.setXYZ(40, cross.r, cross.g, cross.b); colorAttribute.setXYZ(41, cross.r, cross.g, cross.b);

        colorAttribute.setXYZ(42, cross.r, cross.g, cross.b); colorAttribute.setXYZ(43, cross.r, cross.g, cross.b);
        colorAttribute.setXYZ(44, cross.r, cross.g, cross.b); colorAttribute.setXYZ(45, cross.r, cross.g, cross.b);
        colorAttribute.setXYZ(46, cross.r, cross.g, cross.b); colorAttribute.setXYZ(47, cross.r, cross.g, cross.b);
        colorAttribute.setXYZ(48, cross.r, cross.g, cross.b); colorAttribute.setXYZ(49, cross.r, cross.g, cross.b);

        colorAttribute.needsUpdate = true;

    }

    public function update() {

        var geometry = this.geometry;
        var pointMap = this.pointMap;

        var w = 1, h = 1;

        _camera.projectionMatrixInverse.copy(this.camera.projectionMatrixInverse);

        setPoint('c', pointMap, geometry, _camera, 0, 0, -1);
        setPoint('t', pointMap, geometry, _camera, 0, 0, 1);

        setPoint('n1', pointMap, geometry, _camera, -w, -h, -1);
        setPoint('n2', pointMap, geometry, _camera, w, -h, -1);
        setPoint('n3', pointMap, geometry, _camera, -w, h, -1);
        setPoint('n4', pointMap, geometry, _camera, w, h, -1);

        setPoint('f1', pointMap, geometry, _camera, -w, -h, 1);
        setPoint('f2', pointMap, geometry, _camera, w, -h, 1);
        setPoint('f3', pointMap, geometry, _camera, -w, h, 1);
        setPoint('f4', pointMap, geometry, _camera, w, h, 1);

        setPoint('u1', pointMap, geometry, _camera, w * 0.7, h * 1.1, -1);
        setPoint('u2', pointMap, geometry, _camera, -w * 0.7, h * 1.1, -1);
        setPoint('u3', pointMap, geometry, _camera, 0, h * 2, -1);

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

        for (i in points) {

            position.setXYZ(points[i], _vector.x, _vector.y, _vector.z);

        }

    }

}