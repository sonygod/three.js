package openfl.geom;

import openfl._legacy.display.DisplayObject;
import openfl._legacy.geom.Vector3D;
import openfl._legacy.geom.Matrix3D;
import openfl._legacy.geom.PerspectiveProjection;
import openfl.geom.Matrix3D as OpenFLMatrix3D;

class CylinderGeometry extends BufferGeometry {

	public var radiusTop:Float = 1;
	public var radiusBottom:Float = 1;
	public var height:Float = 1;
	public var radialSegments:Int = 32;
	public var heightSegments:Int = 1;
	public var openEnded:Bool = false;
	public var thetaStart:Float = 0;
	public var thetaLength:Float = Math.PI * 2;

	public function new(radiusTop:Float = 1, radiusBottom:Float = 1, height:Float = 1, radialSegments:Int = 32, heightSegments:Int = 1, openEnded:Bool = false, thetaStart:Float = 0, thetaLength:Float = Math.PI * 2) {
		super();
		this.radiusTop = radiusTop;
		this.radiusBottom = radiusBottom;
		this.height = height;
		this.radialSegments = radialSegments;
		this.heightSegments = heightSegments;
		this.openEnded = openEnded;
		this.thetaStart = thetaStart;
		this.thetaLength = thetaLength;

		var scope:CylinderGeometry = this;
		radialSegments = Math.floor(radialSegments);
		heightSegments = Math.floor(heightSegments);

		var indices:Array<Int> = [];
		var vertices:Array<Float> = [];
		var normals:Array<Float> = [];
		var uvs:Array<Float> = [];

		var index:Int = 0;
		var indexArray:Array<Int> = [];
		var halfHeight:Float = height / 2;
		var groupStart:Int = 0;

		generateTorso();

		if (!openEnded) {
			if (radiusTop > 0) generateCap(true);
			if (radiusBottom > 0) generateCap(false);
		}

		setIndex(indices);
		setAttribute("position", new Float32BufferAttribute(vertices, 3));
		setAttribute("normal", new Float32BufferAttribute(normals, 3));
		setAttribute("uv", new Float32BufferAttribute(uvs, 2));

		function generateTorso() {
			var normal:Vector3D = new Vector3D();
			var vertex:Vector3D = new Vector3D();
			var groupCount:Int = 0;
			var slope:Float = (radiusBottom - radiusTop) / height;

			for (i in 0...heightSegments) {
				var indexRow:Array<Int> = [];
				var v:Float = i / heightSegments;
				var radius:Float = v * (radiusBottom - radiusTop) + radiusTop;

				for (j in 0...radialSegments) {
					var u:Float = j / radialSegments;
					var theta:Float = u * thetaLength + thetaStart;
					var sinTheta:Float = Math.sin(theta);
					var cosTheta:Float = Math.cos(theta);

					vertex.x = radius * sinTheta;
					vertex.y = -v * height + halfHeight;
					vertex.z = radius * cosTheta;
					vertices.push(vertex.x, vertex.y, vertex.z);

					normal.set(sinTheta, slope, cosTheta).normalize();
					normals.push(normal.x, normal.y, normal.z);

					uvs.push(u, 1 - v);

					indexRow.push(index++);
				}

				indexArray.push(indexRow);
			}

			for (i in 0...radialSegments) {
				for (j in 0...heightSegments) {
					var a:Int = indexArray[j][i];
					var b:Int = indexArray[j + 1][i];
					var c:Int = indexArray[j + 1][i + 1];
					var d:Int = indexArray[j][i + 1];

					indices.push(a, b, d);
					indices.push(b, c, d);

					groupCount += 6;
				}
			}

			scope.addGroup(groupStart, groupCount, 0);
			groupStart += groupCount;
		}

		function generateCap(top:Bool) {
			var centerIndexStart:Int = index;
			var uv:Vector3D = new Vector3D();
			var vertex:Vector3D = new Vector3D();
			var groupCount:Int = 0;
			var radius:Float = (top) ? radiusTop : radiusBottom;
			var sign:Float = (top) ? 1 : -1;

			for (i in 1...radialSegments) {
				vertices.push(0, halfHeight * sign, 0);
				normals.push(0, sign, 0);
				uvs.push(0.5, 0.5);
				index++;
			}

			var centerIndexEnd:Int = index;

			for (i in 0...radialSegments) {
				var u:Float = i / radialSegments;
				var theta:Float = u * thetaLength + thetaStart;
				var cosTheta:Float = Math.cos(theta);
				var sinTheta:Float = Math.sin(theta);

				vertex.x = radius * sinTheta;
				vertex.y = halfHeight * sign;
				vertex.z = radius * cosTheta;
				vertices.push(vertex.x, vertex.y, vertex.z);

				normals.push(0, sign, 0);

				uv.x = (cosTheta * 0.5) + 0.5;
				uv.y = (sinTheta * 0.5 * sign) + 0.5;
				uvs.push(uv.x, uv.y);

				index++;
			}

			for (i in 0...radialSegments) {
				var c:Int = centerIndexStart + i;
				var i1:Int = centerIndexEnd + i;

				if (top) {
					indices.push(i1, i1 + 1, c);
				} else {
					indices.push(i1 + 1, i1, c);
				}

				groupCount += 3;
			}

			scope.addGroup(groupStart, groupCount, (top) ? 1 : 2);
			groupStart += groupCount;
		}
	}

	public function copy(source:CylinderGeometry):CylinderGeometry {
		super.copy(source);
		radiusTop = source.radiusTop;
		radiusBottom = source.radiusBottom;
		height = source.height;
		radialSegments = source.radialSegments;
		heightSegments = source.heightSegments;
		openEnded = source.openEnded;
		thetaStart = source.thetaStart;
		thetaLength = source.thetaLength;
		return this;
	}

	public static function fromJSON(data:Dynamic):CylinderGeometry {
		return new CylinderGeometry(data.radiusTop, data.radiusBottom, data.height, data.radialSegments, data.heightSegments, data.openEnded, data.thetaStart, data.thetaLength);
	}

}