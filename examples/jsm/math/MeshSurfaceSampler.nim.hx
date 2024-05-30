import three.math.Triangle;
import three.math.Vector2;
import three.math.Vector3;

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

    var geometry:Dynamic;
    var randomFunction:Dynamic;

    var indexAttribute:Dynamic;
    var positionAttribute:Dynamic;
    var normalAttribute:Dynamic;
    var colorAttribute:Dynamic;
    var uvAttribute:Dynamic;
    var weightAttribute:Dynamic;

    var distribution:Dynamic;

    var _face:Triangle;
    var _color:Vector3;
    var _uva:Vector2;
    var _uvb:Vector2;
    var _uvc:Vector2;

    public function new(mesh:Dynamic) {
        this.geometry = mesh.geometry;
        this.randomFunction = Math.random;

        this.indexAttribute = this.geometry.index;
        this.positionAttribute = this.geometry.getAttribute('position');
        this.normalAttribute = this.geometry.getAttribute('normal');
        this.colorAttribute = this.geometry.getAttribute('color');
        this.uvAttribute = this.geometry.getAttribute('uv');
        this.weightAttribute = null;

        this.distribution = null;

        this._face = new Triangle();
        this._color = new Vector3();
        this._uva = new Vector2();
        this._uvb = new Vector2();
        this._uvc = new Vector2();
    }

    public function setWeightAttribute(name:String):MeshSurfaceSampler {
        this.weightAttribute = name ? this.geometry.getAttribute(name) : null;
        return this;
    }

    public function build():MeshSurfaceSampler {
        var indexAttribute = this.indexAttribute;
        var positionAttribute = this.positionAttribute;
        var weightAttribute = this.weightAttribute;

        var totalFaces = indexAttribute ? (indexAttribute.count / 3) : (positionAttribute.count / 3);
        var faceWeights = new Float32Array(totalFaces);

        // Accumulate weights for each mesh face.
        for (i in 0...totalFaces) {
            var faceWeight = 1;
            var i0 = 3 * i;
            var i1 = 3 * i + 1;
            var i2 = 3 * i + 2;

            if (indexAttribute) {
                i0 = indexAttribute.getX(i0);
                i1 = indexAttribute.getX(i1);
                i2 = indexAttribute.getX(i2);
            }

            if (weightAttribute) {
                faceWeight = weightAttribute.getX(i0) + weightAttribute.getX(i1) + weightAttribute.getX(i2);
            }

            this._face.a.fromBufferAttribute(positionAttribute, i0);
            this._face.b.fromBufferAttribute(positionAttribute, i1);
            this._face.c.fromBufferAttribute(positionAttribute, i2);
            faceWeight *= this._face.getArea();

            faceWeights[i] = faceWeight;
        }

        // Store cumulative total face weights in an array, where weight index
        // corresponds to face index.
        var distribution = new Float32Array(totalFaces);
        var cumulativeTotal = 0;

        for (i in 0...totalFaces) {
            cumulativeTotal += faceWeights[i];
            distribution[i] = cumulativeTotal;
        }

        this.distribution = distribution;
        return this;
    }

    public function setRandomGenerator(randomFunction:Dynamic):MeshSurfaceSampler {
        this.randomFunction = randomFunction;
        return this;
    }

    public function sample(targetPosition:Dynamic, targetNormal:Dynamic, targetColor:Dynamic, targetUV:Dynamic):MeshSurfaceSampler {
        var faceIndex = this.sampleFaceIndex();
        return this.sampleFace(faceIndex, targetPosition, targetNormal, targetColor, targetUV);
    }

    public function sampleFaceIndex():Int {
        var cumulativeTotal = this.distribution[this.distribution.length - 1];
        return this.binarySearch(this.randomFunction() * cumulativeTotal);
    }

    public function binarySearch(x:Float):Int {
        var dist = this.distribution;
        var start = 0;
        var end = dist.length - 1;

        var index = -1;

        while (start <= end) {
            var mid = Math.ceil((start + end) / 2);

            if (mid === 0 || dist[mid - 1] <= x && dist[mid] > x) {
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

    public function sampleFace(faceIndex:Int, targetPosition:Dynamic, targetNormal:Dynamic, targetColor:Dynamic, targetUV:Dynamic):MeshSurfaceSampler {
        var u = this.randomFunction();
        var v = this.randomFunction();

        if (u + v > 1) {
            u = 1 - u;
            v = 1 - v;
        }

        // get the vertex attribute indices
        var indexAttribute = this.indexAttribute;
        var i0 = faceIndex * 3;
        var i1 = faceIndex * 3 + 1;
        var i2 = faceIndex * 3 + 2;
        if (indexAttribute) {
            i0 = indexAttribute.getX(i0);
            i1 = indexAttribute.getX(i1);
            i2 = indexAttribute.getX(i2);
        }

        this._face.a.fromBufferAttribute(this.positionAttribute, i0);
        this._face.b.fromBufferAttribute(this.positionAttribute, i1);
        this._face.c.fromBufferAttribute(this.positionAttribute, i2);

        targetPosition
            .set(0, 0, 0)
            .addScaledVector(this._face.a, u)
            .addScaledVector(this._face.b, v)
            .addScaledVector(this._face.c, 1 - (u + v));

        if (targetNormal !== undefined) {
            if (this.normalAttribute !== undefined) {
                this._face.a.fromBufferAttribute(this.normalAttribute, i0);
                this._face.b.fromBufferAttribute(this.normalAttribute, i1);
                this._face.c.fromBufferAttribute(this.normalAttribute, i2);
                targetNormal.set(0, 0, 0).addScaledVector(this._face.a, u).addScaledVector(this._face.b, v).addScaledVector(this._face.c, 1 - (u + v)).normalize();
            } else {
                this._face.getNormal(targetNormal);
            }
        }

        if (targetColor !== undefined && this.colorAttribute !== undefined) {
            this._face.a.fromBufferAttribute(this.colorAttribute, i0);
            this._face.b.fromBufferAttribute(this.colorAttribute, i1);
            this._face.c.fromBufferAttribute(this.colorAttribute, i2);

            this._color
                .set(0, 0, 0)
                .addScaledVector(this._face.a, u)
                .addScaledVector(this._face.b, v)
                .addScaledVector(this._face.c, 1 - (u + v));

            targetColor.r = this._color.x;
            targetColor.g = this._color.y;
            targetColor.b = this._color.z;
        }

        if (targetUV !== undefined && this.uvAttribute !== undefined) {
            this._uva.fromBufferAttribute(this.uvAttribute, i0);
            this._uvb.fromBufferAttribute(this.uvAttribute, i1);
            this._uvc.fromBufferAttribute(this.uvAttribute, i2);
            targetUV.set(0, 0).addScaledVector(this._uva, u).addScaledVector(this._uvb, v).addScaledVector(this._uvc, 1 - (u + v));
        }

        return this;
    }
}