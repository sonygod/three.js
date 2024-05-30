package three.js.math;

import three.js.THREE.Triangle;
import three.js.THREE.Vector2;
import three.js.THREE.Vector3;

/**
 * Utility class for sampling weighted random points on the surface of a mesh.
 *
 * Building the sampler is a one-time O(n) operation. Once built, any number of
 * random samples may be selected in O(logn) time. Memory usage is O(n).
 *
 * References:
 * - http://www.joesfer.com/?p=84
 * - https://stackoverflow.com/a/4322940/1314762
 */

class MeshSurfaceSampler {
    private var _face:Triangle;
    private var _color:Vector3;
    private var _uva:Vector2;
    private var _uvb:Vector2;
    private var _uvc:Vector2;

    public function new(mesh:Mesh) {
        geometry = mesh.geometry;
        randomFunction = Math.random;

        indexAttribute = geometry.getIndex();
        positionAttribute = geometry.getAttribute('position');
        normalAttribute = geometry.getAttribute('normal');
        colorAttribute = geometry.getAttribute('color');
        uvAttribute = geometry.getAttribute('uv');
        weightAttribute = null;

        distribution = null;
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
        var faceWeights = new Float32Array(totalFaces);

        // Accumulate weights for each mesh face.
        for (i in 0...totalFaces) {
            var faceWeight = 1.0;

            var i0 = 3 * i;
            var i1 = 3 * i + 1;
            var i2 = 3 * i + 2;

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

        // Store cumulative total face weights in an array, where weight index
        // corresponds to face index.
        var distribution = new Float32Array(totalFaces);
        var cumulativeTotal = 0.0;

        for (i in 0...totalFaces) {
            cumulativeTotal += faceWeights[i];
            distribution[i] = cumulativeTotal;
        }

        this.distribution = distribution;
        return this;
    }

    public function setRandomGenerator(randomFunction:Void->Float):MeshSurfaceSampler {
        this.randomFunction = randomFunction;
        return this;
    }

    public function sample(targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {
        var faceIndex = sampleFaceIndex();
        return sampleFace(faceIndex, targetPosition, targetNormal, targetColor, targetUV);
    }

    private function sampleFaceIndex():Int {
        var cumulativeTotal = distribution[distribution.length - 1];
        return binarySearch(randomFunction() * cumulativeTotal);
    }

    private function binarySearch(x:Float):Int {
        var dist = distribution;
        var start = 0;
        var end = dist.length - 1;

        var index = -1;

        while (start <= end) {
            var mid = Math.ceil((start + end) / 2);

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

    private function sampleFace(faceIndex:Int, targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {
        var u = randomFunction();
        var v = randomFunction();

        if (u + v > 1) {
            u = 1 - u;
            v = 1 - v;
        }

        // get the vertex attribute indices
        var indexAttribute = this.indexAttribute;
        var i0 = faceIndex * 3;
        var i1 = faceIndex * 3 + 1;
        var i2 = faceIndex * 3 + 2;
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
                targetNormal.set(0, 0, 0).addScaledVector(_face.a, u).addScaledVector(_face.b, v).addScaledVector(_face.c, 1 - (u + v)).normalize();
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
            targetUV.set(0, 0).addScaledVector(_uva, u).addScaledVector(_uvb, v).addScaledVector(_uvc, 1 - (u + v));
        }

        return this;
    }
}