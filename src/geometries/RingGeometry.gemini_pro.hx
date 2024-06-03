import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.math.Vector2;
import three.math.Vector3;

class RingGeometry extends BufferGeometry {

	public var innerRadius:Float;
	public var outerRadius:Float;
	public var thetaSegments:Int;
	public var phiSegments:Int;
	public var thetaStart:Float;
	public var thetaLength:Float;

	public function new(innerRadius:Float = 0.5, outerRadius:Float = 1, thetaSegments:Int = 32, phiSegments:Int = 1, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
		super();
		this.type = "RingGeometry";
		this.innerRadius = innerRadius;
		this.outerRadius = outerRadius;
		this.thetaSegments = thetaSegments;
		this.phiSegments = phiSegments;
		this.thetaStart = thetaStart;
		this.thetaLength = thetaLength;
		this.parameters = {
			"innerRadius": innerRadius,
			"outerRadius": outerRadius,
			"thetaSegments": thetaSegments,
			"phiSegments": phiSegments,
			"thetaStart": thetaStart,
			"thetaLength": thetaLength
		};
		thetaSegments = Math.max(3, thetaSegments);
		phiSegments = Math.max(1, phiSegments);
		var indices = new Array<Int>();
		var vertices = new Array<Float>();
		var normals = new Array<Float>();
		var uvs = new Array<Float>();
		var radius = innerRadius;
		var radiusStep = (outerRadius - innerRadius) / phiSegments;
		var vertex = new Vector3();
		var uv = new Vector2();
		for (j in 0...phiSegments + 1) {
			for (i in 0...thetaSegments + 1) {
				var segment = thetaStart + i / thetaSegments * thetaLength;
				vertex.x = radius * Math.cos(segment);
				vertex.y = radius * Math.sin(segment);
				vertices.push(vertex.x, vertex.y, vertex.z);
				normals.push(0, 0, 1);
				uv.x = (vertex.x / outerRadius + 1) / 2;
				uv.y = (vertex.y / outerRadius + 1) / 2;
				uvs.push(uv.x, uv.y);
			}
			radius += radiusStep;
		}
		for (j in 0...phiSegments) {
			var thetaSegmentLevel = j * (thetaSegments + 1);
			for (i in 0...thetaSegments) {
				var segment = i + thetaSegmentLevel;
				var a = segment;
				var b = segment + thetaSegments + 1;
				var c = segment + thetaSegments + 2;
				var d = segment + 1;
				indices.push(a, b, d);
				indices.push(b, c, d);
			}
		}
		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
	}

	public function copy(source:RingGeometry):RingGeometry {
		super.copy(source);
		this.parameters = {
			"innerRadius": source.innerRadius,
			"outerRadius": source.outerRadius,
			"thetaSegments": source.thetaSegments,
			"phiSegments": source.phiSegments,
			"thetaStart": source.thetaStart,
			"thetaLength": source.thetaLength
		};
		return this;
	}

	public static function fromJSON(data:Dynamic):RingGeometry {
		return new RingGeometry(data.innerRadius, data.outerRadius, data.thetaSegments, data.phiSegments, data.thetaStart, data.thetaLength);
	}

}