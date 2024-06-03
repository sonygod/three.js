import three.Triangle;
import three.Vector2;
import three.Vector3;

class MeshSurfaceSampler {
    private var geometry: Geometry;
    private var randomFunction: () -> Float;
    private var indexAttribute: BufferAttribute;
    private var positionAttribute: BufferAttribute;
    private var normalAttribute: BufferAttribute;
    private var colorAttribute: BufferAttribute;
    private var uvAttribute: BufferAttribute;
    private var weightAttribute: BufferAttribute;
    private var distribution: Float32Array;

    public function new(mesh: Mesh) {
        this.geometry = mesh.geometry;
        this.randomFunction = Math.random;
        this.indexAttribute = this.geometry.index;
        this.positionAttribute = this.geometry.getAttribute('position');
        this.normalAttribute = this.geometry.getAttribute('normal');
        this.colorAttribute = this.geometry.getAttribute('color');
        this.uvAttribute = this.geometry.getAttribute('uv');
        this.weightAttribute = null;
        this.distribution = null;
    }

    public function setWeightAttribute(name: String): MeshSurfaceSampler {
        this.weightAttribute = name != null ? this.geometry.getAttribute(name) : null;
        return this;
    }

    public function build(): MeshSurfaceSampler {
        var indexAttribute = this.indexAttribute;
        var positionAttribute = this.positionAttribute;
        var weightAttribute = this.weightAttribute;

        var totalFaces = indexAttribute != null ? (indexAttribute.count / 3) : (positionAttribute.count / 3);
        var faceWeights = new Float32Array(totalFaces);

        for (var i = 0; i < totalFaces; i++) {
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

            var face = new Triangle();
            face.a.fromBufferAttribute(positionAttribute, i0);
            face.b.fromBufferAttribute(positionAttribute, i1);
            face.c.fromBufferAttribute(positionAttribute, i2);
            faceWeight *= face.getArea();

            faceWeights[i] = faceWeight;
        }

        var distribution = new Float32Array(totalFaces);
        var cumulativeTotal = 0.0;

        for (var i = 0; i < totalFaces; i++) {
            cumulativeTotal += faceWeights[i];
            distribution[i] = cumulativeTotal;
        }

        this.distribution = distribution;
        return this;
    }

    public function setRandomGenerator(randomFunction: () -> Float): MeshSurfaceSampler {
        this.randomFunction = randomFunction;
        return this;
    }

    public function sample(targetPosition: Vector3, targetNormal: Vector3 = null, targetColor: Color = null, targetUV: Vector2 = null): MeshSurfaceSampler {
        var faceIndex = this.sampleFaceIndex();
        return this.sampleFace(faceIndex, targetPosition, targetNormal, targetColor, targetUV);
    }

    private function sampleFaceIndex(): Int {
        var cumulativeTotal = this.distribution[this.distribution.length - 1];
        return this.binarySearch(this.randomFunction() * cumulativeTotal);
    }

    private function binarySearch(x: Float): Int {
        var dist = this.distribution;
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

    private function sampleFace(faceIndex: Int, targetPosition: Vector3, targetNormal: Vector3 = null, targetColor: Color = null, targetUV: Vector2 = null): MeshSurfaceSampler {
        var u = this.randomFunction();
        var v = this.randomFunction();

        if (u + v > 1) {
            u = 1 - u;
            v = 1 - v;
        }

        var indexAttribute = this.indexAttribute;
        var i0 = faceIndex * 3;
        var i1 = faceIndex * 3 + 1;
        var i2 = faceIndex * 3 + 2;

        if (indexAttribute != null) {
            i0 = indexAttribute.getX(i0);
            i1 = indexAttribute.getX(i1);
            i2 = indexAttribute.getX(i2);
        }

        var face = new Triangle();
        face.a.fromBufferAttribute(this.positionAttribute, i0);
        face.b.fromBufferAttribute(this.positionAttribute, i1);
        face.c.fromBufferAttribute(this.positionAttribute, i2);

        targetPosition.set(0, 0, 0).addScaledVector(face.a, u).addScaledVector(face.b, v).addScaledVector(face.c, 1 - (u + v));

        if (targetNormal != null) {
            if (this.normalAttribute != null) {
                face.a.fromBufferAttribute(this.normalAttribute, i0);
                face.b.fromBufferAttribute(this.normalAttribute, i1);
                face.c.fromBufferAttribute(this.normalAttribute, i2);
                targetNormal.set(0, 0, 0).addScaledVector(face.a, u).addScaledVector(face.b, v).addScaledVector(face.c, 1 - (u + v)).normalize();
            } else {
                face.getNormal(targetNormal);
            }
        }

        if (targetColor != null && this.colorAttribute != null) {
            face.a.fromBufferAttribute(this.colorAttribute, i0);
            face.b.fromBufferAttribute(this.colorAttribute, i1);
            face.c.fromBufferAttribute(this.colorAttribute, i2);

            var color = new Vector3();
            color.set(0, 0, 0).addScaledVector(face.a, u).addScaledVector(face.b, v).addScaledVector(face.c, 1 - (u + v));

            targetColor.r = color.x;
            targetColor.g = color.y;
            targetColor.b = color.z;
        }

        if (targetUV != null && this.uvAttribute != null) {
            var uva = new Vector2();
            var uvb = new Vector2();
            var uvc = new Vector2();

            uva.fromBufferAttribute(this.uvAttribute, i0);
            uvb.fromBufferAttribute(this.uvAttribute, i1);
            uvc.fromBufferAttribute(this.uvAttribute, i2);

            targetUV.set(0, 0).addScaledVector(uva, u).addScaledVector(uvb, v).addScaledVector(uvc, 1 - (u + v));
        }

        return this;
    }
}