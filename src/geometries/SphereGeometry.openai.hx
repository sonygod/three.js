package geometries;

import core.BufferAttribute;
import core.BufferGeometry;
import math.Vector3;

class SphereGeometry extends BufferGeometry {

	public var radius:Float;
	public var widthSegments:Int;
	public var heightSegments:Int;
	public var phiStart:Float;
	public var phiLength:Float;
	public var thetaStart:Float;
	public var thetaLength:Float;
	
	public function new(radius:Float = 1, widthSegments:Int = 32, heightSegments:Int = 16, phiStart:Float = 0, phiLength:Float = Math.PI * 2, thetaStart:Float = 0, thetaLength:Float = Math.PI ) {
		super();
		
		this.type = "SphereGeometry";
		
		this.radius = radius;
		this.widthSegments = widthSegments;
		this.heightSegments = heightSegments;
		this.phiStart = phiStart;
		this.phiLength = phiLength;
		this.thetaStart = thetaStart;
		this.thetaLength = thetaLength;
		
		widthSegments = Math.max(3, Math.floor(widthSegments));
		heightSegments = Math.max(2, Math.floor(heightSegments));
		
		var thetaEnd = Math.min(thetaStart + thetaLength, Math.PI);
		
		var index:Int = 0;
		var grid:Array<Array<Int>> = [];
		
		var vertex:Vector3 = new Vector3();
		var normal:Vector3 = new Vector3();
		
		// buffers
		
		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];
		
		// generate vertices, normals and uvs
		
		for (var iy:Int = 0; iy <= heightSegments; iy++) {
		
			var verticesRow:Array<Int> = [];
		
			var v:Float = iy / heightSegments;
		
			// special case for the poles
		
			var uOffset:Float = 0;
		
			if (iy == 0 && thetaStart == 0) {
		
				uOffset = 0.5 / widthSegments;
		
			} else if (iy == heightSegments && thetaEnd == Math.PI) {
		
				uOffset = - 0.5 / widthSegments;
		
			}
		
			for (var ix:Int = 0; ix <= widthSegments; ix++) {
		
				var u:Float = ix / widthSegments;
		
				// vertex
		
				vertex.x = - radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
				vertex.y = radius * Math.cos(thetaStart + v * thetaLength);
				vertex.z = radius * Math.sin(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
		
				vertices.push(vertex.x, vertex.y, vertex.z);
		
				// normal
		
				normal.copy(vertex).normalize();
				normals.push(normal.x, normal.y, normal.z);
		
				// uv
		
				uvs.push(u + uOffset, 1 - v);
		
				verticesRow.push(index++);
		
			}
		
			grid.push(verticesRow);
		
		}
		
		// indices
		
		for (var iy:Int = 0; iy < heightSegments; iy++) {
		
			for (var ix:Int = 0; ix < widthSegments; ix++) {
		
				var a:Int = grid[iy][ix + 1];
				var b:Int = grid[iy][ix];
				var c:Int = grid[iy + 1][ix];
				var d:Int = grid[iy + 1][ix + 1];
		
				if (iy != 0 || thetaStart > 0) indices.push(a, b, d);
				if (iy != heightSegments - 1 || thetaEnd < Math.PI) indices.push(b, c, d);
		
			}
		
		}
		
		// build geometry
		
		this.setIndex(indices);
		this.setAttribute("position", new BufferAttribute(new Float32Array(vertices), 3));
		this.setAttribute("normal", new BufferAttribute(new Float32Array(normals), 3));
		this.setAttribute("uv", new BufferAttribute(new Float32Array(uvs), 2));
	}

	public function copy(source):SphereGeometry {
		super.copy(source);
		
		this.parameters = {radius: source.parameters.radius, widthSegments: source.parameters.widthSegments, heightSegments: source.parameters.heightSegments, phiStart: source.parameters.phiStart, phiLength: source.parameters.phiLength, thetaStart: source.parameters.thetaStart, thetaLength: source.parameters.thetaLength};
		
		return this;
	}

	public static function fromJSON(data):SphereGeometry {
		return new SphereGeometry(data.radius, data.widthSegments, data.heightSegments, data.phiStart, data.phiLength, data.thetaStart, data.thetaLength);
	}
}
