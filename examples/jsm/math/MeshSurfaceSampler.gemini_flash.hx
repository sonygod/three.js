import three.Triangle;
import three.Vector2;
import three.Vector3;
import three.BufferAttribute;
import three.BufferGeometry;

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

	private geometry:BufferGeometry;
	private randomFunction:() -> Float;

	private indexAttribute:BufferAttribute;
	private positionAttribute:BufferAttribute;
	private normalAttribute:BufferAttribute;
	private colorAttribute:BufferAttribute;
	private uvAttribute:BufferAttribute;
	private weightAttribute:BufferAttribute;

	private distribution:Array<Float>;

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

	}

	public function setWeightAttribute(name:String):MeshSurfaceSampler {

		this.weightAttribute = name != null ? this.geometry.getAttribute(name) : null;

		return this;

	}

	public function build():MeshSurfaceSampler {

		var indexAttribute = this.indexAttribute;
		var positionAttribute = this.positionAttribute;
		var weightAttribute = this.weightAttribute;

		var totalFaces = indexAttribute != null ? (indexAttribute.count / 3) : (positionAttribute.count / 3);
		var faceWeights = new Array<Float>(totalFaces);

		// Accumulate weights for each mesh face.

		for (i in 0...totalFaces) {

			var faceWeight = 1;

			var i0 = 3 * i;
			var i1 = 3 * i + 1;
			var i2 = 3 * i + 2;

			if (indexAttribute != null) {

				i0 = indexAttribute.getX(i0);
				i1 = indexAttribute.getX(i1);
				i2 = indexAttribute.getX(i2);

			}

			if (weightAttribute != null) {

				faceWeight = weightAttribute.getX(i0)
					+ weightAttribute.getX(i1)
					+ weightAttribute.getX(i2);

			}

			_face.a.fromBufferAttribute(positionAttribute, i0);
			_face.b.fromBufferAttribute(positionAttribute, i1);
			_face.c.fromBufferAttribute(positionAttribute, i2);
			faceWeight *= _face.getArea();

			faceWeights[i] = faceWeight;

		}

		// Store cumulative total face weights in an array, where weight index
		// corresponds to face index.

		var distribution = new Array<Float>(totalFaces);
		var cumulativeTotal = 0;

		for (i in 0...totalFaces) {

			cumulativeTotal += faceWeights[i];
			distribution[i] = cumulativeTotal;

		}

		this.distribution = distribution;
		return this;

	}

	public function setRandomGenerator(randomFunction:() -> Float):MeshSurfaceSampler {

		this.randomFunction = randomFunction;
		return this;

	}

	public function sample(targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {

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

		var index = - 1;

		while (start <= end) {

			var mid = Std.int(Math.ceil((start + end) / 2));

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

	public function sampleFace(faceIndex:Int, targetPosition:Vector3, targetNormal:Vector3, targetColor:Vector3, targetUV:Vector2):MeshSurfaceSampler {

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
		if (indexAttribute != null) {

			i0 = indexAttribute.getX(i0);
			i1 = indexAttribute.getX(i1);
			i2 = indexAttribute.getX(i2);

		}

		_face.a.fromBufferAttribute(this.positionAttribute, i0);
		_face.b.fromBufferAttribute(this.positionAttribute, i1);
		_face.c.fromBufferAttribute(this.positionAttribute, i2);

		targetPosition
			.set(0, 0, 0)
			.addScaledVector(_face.a, u)
			.addScaledVector(_face.b, v)
			.addScaledVector(_face.c, 1 - (u + v));

		if (targetNormal != null) {

			if (this.normalAttribute != null) {

				_face.a.fromBufferAttribute(this.normalAttribute, i0);
				_face.b.fromBufferAttribute(this.normalAttribute, i1);
				_face.c.fromBufferAttribute(this.normalAttribute, i2);
				targetNormal.set(0, 0, 0).addScaledVector(_face.a, u).addScaledVector(_face.b, v).addScaledVector(_face.c, 1 - (u + v)).normalize();

			} else {

				_face.getNormal(targetNormal);

			}

		}

		if (targetColor != null && this.colorAttribute != null) {

			_face.a.fromBufferAttribute(this.colorAttribute, i0);
			_face.b.fromBufferAttribute(this.colorAttribute, i1);
			_face.c.fromBufferAttribute(this.colorAttribute, i2);

			_color
				.set(0, 0, 0)
				.addScaledVector(_face.a, u)
				.addScaledVector(_face.b, v)
				.addScaledVector(_face.c, 1 - (u + v));

			targetColor.r = _color.x;
			targetColor.g = _color.y;
			targetColor.b = _color.z;

		}

		if (targetUV != null && this.uvAttribute != null) {

			_uva.fromBufferAttribute(this.uvAttribute, i0);
			_uvb.fromBufferAttribute(this.uvAttribute, i1);
			_uvc.fromBufferAttribute(this.uvAttribute, i2);
			targetUV.set(0, 0).addScaledVector(_uva, u).addScaledVector(_uvb, v).addScaledVector(_uvc, 1 - (u + v));

		}

		return this;

	}

}

private var _face = new Triangle();
private var _color = new Vector3();
private var _uva = new Vector2();
private var _uvb = new Vector2();
private var _uvc = new Vector2();