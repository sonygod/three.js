package openfl.geom;

import openfl.geom.Vector3;
import openfl.geom.BufferGeometry;
import openfl.geom.BufferAttribute;

class SphereGeometry extends BufferGeometry {

	public var radius:Float = 1;
	public var widthSegments:Int = 32;
	public var heightSegments:Int = 16;
	public var phiStart:Float = 0;
	public var phiLength:Float = Math.PI * 2;
	public var thetaStart:Float = 0;
	public var thetaLength:Float = Math.PI;

	public function new() {
		super();
		this.type = 'SphereGeometry';
		widthSegments = max(3, std.int(widthSegments));
		heightSegments = max(2, std.int(heightSegments));
		var thetaEnd = min(thetaStart + thetaLength, Math.PI);
		var index = 0;
		var grid:Array<Int> = [];
		var vertex:Vector3 = new Vector3();
		var normal:Vector3 = new Vector3();
		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];
		for (iy in 0...heightSegments) {
			var verticesRow:Array<Int> = [];
			var v = iy / heightSegments;
			var uOffset = 0.0;
			if (iy == 0 && thetaStart == 0) {
				uOffset = 0.5 / widthSegments;
			} else if (iy == heightSegments && thetaEnd == Math.PI) {
				uOffset = -0.5 / widthSegments;
			}
			for (ix in 0...widthSegments) {
				var u = ix / widthSegments;
				vertex.x = -radius * Math.cos(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
				vertex.y = radius * Math.cos(thetaStart + v * thetaLength);
				vertex.z = radius * Math.sin(phiStart + u * phiLength) * Math.sin(thetaStart + v * thetaLength);
				vertices.push(vertex.x);
				vertices.push(vertex.y);
				vertices.push(vertex.z);
				normal.copy(vertex).normalize();
				normals.push(normal.x);
				normals.push(normal.y);
				normals.push(normal.z);
				uvs.push(u + uOffset);
				uvs.push(1 - v);
				verticesRow.push(index++);
			}
			grid.push(verticesRow);
		}
		for (iy in 0...heightSegments) {
			for (ix in 0...widthSegments) {
				var a = grid[iy][ix + 1];
				var b = grid[iy][ix];
				var c = grid[iy + 1][ix];
				var d = grid[iy + 1][ix + 1];
				if (iy != 0 || thetaStart > 0) {
					indices.push(a);
					indices.push(b);
					indices.push(d);
				}
				if (iy != heightSegments - 1 || thetaEnd < Math.PI) {
					indices.push(b);
					indices.push(c);
					indices.push(d);
				}
			}
		}
		this.setIndex(indices);
		this.setAttribute('position', new Float32BufferAttribute(vertices, 3));
		this.setAttribute('normal', new Float32BufferAttribute(normals, 3));
		this.setAttribute('uv', new Float32BufferAttribute(uvs, 2));
	}

	public function copy(source:SphereGeometry):SphereGeometry {
		super.copy(source);
		this.parameters = source.parameters;
		return this;
	}

	public static function fromJSON(data:Dynamic):SphereGeometry {
		return new SphereGeometry(data.radius, data.widthSegments, data.heightSegments, data.phiStart, data.phiLength, data.thetaStart, data.thetaLength);
	}

}