package three.js.examples.math;

import three.Triangle;
import three.Vector2;
import three.Vector3;

class MeshSurfaceSampler {
    var geometry:Geometry;
    var randomFunction:Float->Float;
    var indexAttribute:BufferAttribute;
    var positionAttribute:BufferAttribute;
    var normalAttribute:BufferAttribute;
    var colorAttribute:BufferAttribute;
    var uvAttribute:BufferAttribute;
    var weightAttribute:BufferAttribute;
    var distribution:Array<Float>;

    public function new(mesh:Mesh) {
        geometry = mesh.geometry;
        randomFunction = Math.random;
        indexAttribute = geometry.getIndex();
        positionAttribute = geometry.getAttribute('position');
        normalAttribute = geometry.getAttribute('normal');
        colorAttribute = geometry.getAttribute('color');
        uvAttribute = geometry.getAttribute('uv');
        weightAttribute = null;
    }

    public function setWeightAttribute(name:String):MeshSurfaceSampler {
        weightAttribute = name != null ? geometry.getAttribute(name) : null;
        return this;
    }

    public function build():MeshSurfaceSampler {
        var indexAttribute = this.indexAttribute;
        var positionAttribute = this.positionAttribute;
        var weightAttribute = this.weightAttribute;

        var totalFaces = indexAttribute != null ? (indexAttribute.count / 3) : (positionAttribute.count / 3);
        var faceWeights = new Array<Float>(totalFaces);

        for (i in 0...totalFaces) {
            var faceWeight:Float = 1;

            var i0:Int = 3 * i;
            var i1:Int = 3 * i + 1;
            var i2:Int = 3 * i + 2;

            if (indexAttribute != null) {
                i0 = indexAttribute.getX(i0);
                i1 = indexAttribute.getX(i1);
                i2 = indexAttribute.getX(i2);
            }

            if (weightAttribute != null) {
                faceWeight = weightAttribute.getX(i0) + weightAttribute.getX(i1) + weightAttribute.getX(i2);
            }

            _face.a.fromBufferAttribute(positionAttribute, i0);
            _face.b.fromBufferAttribute(positionAttribute, i1);
            _face.c.fromBufferAttribute(positionAttribute, i2);
            faceWeight *= _face.getArea();

            faceWeights[i] = faceWeight;
        }

        var distribution = new Array<Float>(totalFaces);
        var cumulativeTotal:Float = 0;

        for (i in 0...totalFaces) {
            cumulativeTotal += faceWeights[i];
            distribution[i] = cumulativeTotal;
        }

        this.distribution = distribution;
        return this;
    }

    public function setRandomGenerator(randomFunction:Float->Float):MeshSurfaceSampler {
        this.randomFunction = randomFunction;
        return this;
    }

    public function sample(targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {
        var faceIndex = sampleFaceIndex();
        return sampleFace(faceIndex, targetPosition, targetNormal, targetColor, targetUV);
    }

    function sampleFaceIndex():Int {
        var cumulativeTotal:Float = distribution[distribution.length - 1];
        return binarySearch(randomFunction() * cumulativeTotal);
    }

    function binarySearch(x:Float):Int {
        var dist = distribution;
        var start:Int = 0;
        var end:Int = dist.length - 1;
        var index:Int = -1;

        while (start <= end) {
            var mid:Int = Math.ceil((start + end) / 2);

            if (mid == 0 || dist[mid - 1] <= x && dist[mid] > x) {
                index = mid;
                break;
            } else if (x < dist[mid]) {
                end = mid - 1;
            } else {
                start = mid + 1;
            }
        }

        return index;
    }

    function sampleFace(faceIndex:Int, targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {
        var u:Float = randomFunction();
        var v:Float = randomFunction();

        if (u + v > 1) {
            u = 1 - u;
            v = 1 - v;
        }

        var i0:Int = faceIndex * 3;
        var i1:Int = faceIndex * 3 + 1;
        var i2:Int = faceIndex * 3 + 2;
        if (indexAttribute != null) {
            i0 = indexAttribute.getX(i0);
            i1 = indexAttribute.getX(i1);
            i2 = indexAttribute.getX(i2);
        }

        _face.a.fromBufferAttribute(positionAttribute, i0);
        _face.b.fromBufferAttribute(positionAttribute, i1);
        _face.c.fromBufferAttribute(positionAttribute, i2);

        targetPosition
            .set(0, 0, 0)
            .addScaledVector(_face.a, u)
            .addScaledVector(_face.b, v)
            .addScaledVector(_face.c, 1 - (u + v));

        if (targetNormal != null) {
            if (normalAttribute != null) {
                _face.a.fromBufferAttribute(normalAttribute, i0);
                _face.b.fromBufferAttribute(normalAttribute, i1);
                _face.c.fromBufferAttribute(normalAttribute, i2);
                targetNormal
                    .set(0, 0, 0)
                    .addScaledVector(_face.a, u)
                    .addScaledVector(_face.b, v)
                    .addScaledVector(_face.c, 1 - (u + v))
                    .normalize();
            } else {
                _face.getNormal(targetNormal);
            }
        }

        if (targetColor != null && colorAttribute != null) {
            _face.a.fromBufferAttribute(colorAttribute, i0);
            _face.b.fromBufferAttribute(colorAttribute, i1);
            _face.c.fromBufferAttribute(colorAttribute, i2);

            _color
                .set(0, 0, 0)
                .addScaledVector(_face.a, u)
                .addScaledVector(_face.b, v)
                .addScaledVector(_face.c, 1 - (u + v));

            targetColor.r = _color.x;
            targetColor.g = _color.y;
            targetColor.b = _color.z;
        }

        if (targetUV != null && uvAttribute != null) {
            _uva.fromBufferAttribute(uvAttribute, i0);
            _uvb.fromBufferAttribute(uvAttribute, i1);
            _uvc.fromBufferAttribute(uvAttribute, i2);
            targetUV
                .set(0, 0)
                .addScaledVector(_uva, u)
                .addScaledVector(_uvb, v)
                .addScaledVector(_uvc, 1 - (u + v));
        }

        return this;
    }

    static var _face = new Triangle();
    static var _color = new Vector3();
    static var _uva = new Vector2();
    static var _uvb = new Vector2();
    static var _uvc = new Vector2();
}