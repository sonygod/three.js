package openfl.geom;

import js.Browser;
import js.Node;
import openfl._internal.Lib;
import openfl.display.DisplayObject;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D._internal.Context3DBuffer;
import openfl.display3D._internal.SamplerState;
import openfl.errors.Error;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.IEventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class TubeGeometry extends BufferGeometry
{
	public var tangents:Array<Vector3D>;
	public var normals:Array<Vector3D>;
	public var binormals:Array<Vector3D>;

	public function new(path:Curve = null, tubularSegments:Int = 64, radius:Float = 1, radialSegments:Int = 8, closed:Bool = false)
	{
		super ();
		this.type = "TubeGeometry";

		if (path == null) path = new QuadraticBezierCurve3(-1, -1, 0, -1, 1, 0, 1, 1, 0);
		this.parameters = {"path": path, "tubularSegments": tubularSegments, "radius": radius, "radialSegments": radialSegments, "closed": closed};

		var frames:Array<Vector3D> = path.computeFrenetFrames(tubularSegments, closed);

		this.tangents = frames.tangents;
		this.normals = frames.normals;
		this.binormals = frames.binormals;

		var vertex:Vector3D = new Vector3D();
		var normal:Vector3D = new Vector3D();
		var uv:Vector2D = new Vector2D();
		var P:Vector3D = new Vector3D();

		var vertices:Array<Float> = [];
		var normals1:Array<Float> = [];
		var uvs:Array<Float> = [];
		var indices:Array<Int> = [];

		generateBufferData();

		this.setIndex(indices);
		this.setAttribute("position", new Float32BufferAttribute(vertices, 3));
		this.setAttribute("normal", new Float32BufferAttribute(normals1, 3));
		this.setAttribute("uv", new Float32BufferAttribute(uvs, 2));
	}

	public function copy(source:TubeGeometry):TubeGeometry
	{
		super.copy(source);
		this.parameters = source.parameters;
		return this;
	}

	public function toJSON():Dynamic
	{
		var data:Dynamic = super.toJSON();
		data.path = this.parameters.path.toJSON();
		return data;
	}

	public static function fromJSON(data:Dynamic):TubeGeometry
	{
		return new TubeGeometry(new QuadraticBezierCurve3().fromJSON(data.path), data.tubularSegments, data.radius, data.radialSegments, data.closed);
	}

	protected function generateBufferData()
	{
		var path:Curve = this.parameters.path as Curve;
		var tubularSegments:Int = this.parameters.tubularSegments as Int;
		var radius:Float = this.parameters.radius as Float;
		var radialSegments:Int = this.parameters.radialSegments as Int;
		var closed:Bool = this.parameters.closed as Bool;

		for (i in 0...tubularSegments)
		{
			generateSegment(i);
		}

		if (!closed)
		{
			generateSegment(tubularSegments);
		}
		else
		{
			generateSegment(0);
		}

		generateUVs();
		generateIndices();
	}

	protected function generateSegment(i:Int)
	{
		var path:Curve = this.parameters.path as Curve;
		var tubularSegments:Int = this.parameters.tubularSegments as Int;
		var radius:Float = this.parameters.radius as Float;
		var radialSegments:Int = this.parameters.radialSegments as Int;
		var closed:Bool = this.parameters.closed as Bool;

		var P:Vector3D = path.getPointAt(i / tubularSegments, P);

		var N:Vector3D = this.normals[i];
		var B:Vector3D = this.binormals[i];

		var normal:Vector3D = new Vector3D();
		var vertex:Vector3D = new Vector3D();

		for (j in 0...(radialSegments + 1))
		{
			var v:Float = j / radialSegments * Math.PI * 2;
			var sin:Float = Math.sin(v);
			var cos:Float = -Math.cos(v);

			normal.x = (cos * N.x + sin * B.x);
			normal.y = (cos * N.y + sin * B.y);
			normal.z = (cos * N.z + sin * B.z);
			normal.normalize();

			normals.push(normal.x, normal.y, normal.z);

			vertex.x = P.x + radius * normal.x;
			vertex.y = P.y + radius * normal.y;
			vertex.z = P.z + radius * normal.z;

			vertices.push(vertex.x, vertex.y, vertex.z);
		}
	}

	protected function generateUVs()
	{
		var tubularSegments:Int = this.parameters.tubularSegments as Int;
		var radialSegments:Int = this.parameters.radialSegments as Int;

		var uv:Vector2D = new Vector2D();

		for (i in 0...(tubularSegments + 1))
		{
			for (j in 0...(radialSegments + 1))
			{
				uv.x = i / tubularSegments;
				uv.y = j / radialSegments;

				uvs.push(uv.x, uv.y);
			}
		}
	}

	protected function generateIndices()
	{
		var tubularSegments:Int = this.parameters.tubularSegments as Int;
		var radialSegments:Int = this.parameters.radialSegments as Int;

		var a:Int, b:Int, c:Int, d:Int:

		for (j in 1...(tubularSegments + 1))
		{
			for (i in 1...(radialSegments + 1))
			{
				a = (radialSegments + 1) * (j - 1) + (i - 1);
				b = (radialSegments + 1) * j + (i - 1);
				c = (radialSegments + 1) * j + i;
				d = (radialSegments + 1) * (j - 1) + i;

				indices.push(a, b, d);
				indices.push(b, c, d);
			}
		}
	}
}