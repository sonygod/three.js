import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector3;

class BoxGeometry extends BufferGeometry {

	public var width:Float;
	public var height:Float;
	public var depth:Float;
	public var widthSegments:Int;
	public var heightSegments:Int;
	public var depthSegments:Int;

	public function new(width:Float = 1, height:Float = 1, depth:Float = 1, widthSegments:Int = 1, heightSegments:Int = 1, depthSegments:Int = 1) {
		super();
		this.type = "BoxGeometry";
		this.width = width;
		this.height = height;
		this.depth = depth;
		this.widthSegments = widthSegments;
		this.heightSegments = heightSegments;
		this.depthSegments = depthSegments;
		this.parameters = {
			"width":width,
			"height":height,
			"depth":depth,
			"widthSegments":widthSegments,
			"heightSegments":heightSegments,
			"depthSegments":depthSegments
		};
		buildGeometry();
	}

	private function buildGeometry() {
		// segments
		this.widthSegments = Math.floor(this.widthSegments);
		this.heightSegments = Math.floor(this.heightSegments);
		this.depthSegments = Math.floor(this.depthSegments);

		// buffers
		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		// helper variables
		var numberOfVertices:Int = 0;
		var groupStart:Int = 0;

		// build each side of the box geometry
		buildPlane("z", "y", "x", - 1, - 1, this.depth, this.height, this.width, this.depthSegments, this.heightSegments, 0); // px
		buildPlane("z", "y", "x", 1, - 1, this.depth, this.height, - this.width, this.depthSegments, this.heightSegments, 1); // nx
		buildPlane("x", "z", "y", 1, 1, this.width, this.depth, this.height, this.widthSegments, this.depthSegments, 2); // py
		buildPlane("x", "z", "y", 1, - 1, this.width, this.depth, - this.height, this.widthSegments, this.depthSegments, 3); // ny
		buildPlane("x", "y", "z", 1, - 1, this.width, this.height, this.depth, this.widthSegments, this.heightSegments, 4); // pz
		buildPlane("x", "y", "z", - 1, - 1, this.width, this.height, - this.depth, this.widthSegments, this.heightSegments, 5); // nz

		// build geometry
		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
	}

	private function buildPlane(u:String, v:String, w:String, udir:Float, vdir:Float, width:Float, height:Float, depth:Float, gridX:Int, gridY:Int, materialIndex:Int) {
		var segmentWidth:Float = width / gridX;
		var segmentHeight:Float = height / gridY;

		var widthHalf:Float = width / 2;
		var heightHalf:Float = height / 2;
		var depthHalf:Float = depth / 2;

		var gridX1:Int = gridX + 1;
		var gridY1:Int = gridY + 1;

		var vertexCounter:Int = 0;
		var groupCount:Int = 0;

		var vector:Vector3 = new Vector3();

		// generate vertices, normals and uvs
		for (iy in 0...gridY1) {
			var y:Float = iy * segmentHeight - heightHalf;
			for (ix in 0...gridX1) {
				var x:Float = ix * segmentWidth - widthHalf;

				// set values to correct vector component
				vector[u] = x * udir;
				vector[v] = y * vdir;
				vector[w] = depthHalf;

				// now apply vector to vertex buffer
				vertices.push(vector.x, vector.y, vector.z);

				// set values to correct vector component
				vector[u] = 0;
				vector[v] = 0;
				vector[w] = depth > 0 ? 1 : - 1;

				// now apply vector to normal buffer
				normals.push(vector.x, vector.y, vector.z);

				// uvs
				uvs.push(ix / gridX);
				uvs.push(1 - (iy / gridY));

				// counters
				vertexCounter += 1;
			}
		}

		// indices
		// 1. you need three indices to draw a single face
		// 2. a single segment consists of two faces
		// 3. so we need to generate six (2*3) indices per segment
		for (iy in 0...gridY) {
			for (ix in 0...gridX) {
				var a:Int = numberOfVertices + ix + gridX1 * iy;
				var b:Int = numberOfVertices + ix + gridX1 * (iy + 1);
				var c:Int = numberOfVertices + (ix + 1) + gridX1 * (iy + 1);
				var d:Int = numberOfVertices + (ix + 1) + gridX1 * iy;

				// faces
				indices.push(a, b, d);
				indices.push(b, c, d);

				// increase counter
				groupCount += 6;
			}
		}

		// add a group to the geometry. this will ensure multi material support
		this.addGroup(groupStart, groupCount, materialIndex);

		// calculate new start value for groups
		groupStart += groupCount;

		// update total number of vertices
		numberOfVertices += vertexCounter;
	}

	public function copy(source:BoxGeometry):BoxGeometry {
		super.copy(source);
		this.width = source.width;
		this.height = source.height;
		this.depth = source.depth;
		this.widthSegments = source.widthSegments;
		this.heightSegments = source.heightSegments;
		this.depthSegments = source.depthSegments;
		this.parameters = {
			"width":this.width,
			"height":this.height,
			"depth":this.depth,
			"widthSegments":this.widthSegments,
			"heightSegments":this.heightSegments,
			"depthSegments":this.depthSegments
		};
		return this;
	}

	public static function fromJSON(data:Dynamic):BoxGeometry {
		return new BoxGeometry(data.width, data.height, data.depth, data.widthSegments, data.heightSegments, data.depthSegments);
	}

}