package;

import js.Browser.console;
import js.Node.Buffer;
import js.Node.Fs;
import js.Node.Path;
import js.Node.Process;
import js.html.Audio;
import js.html.CanvasElement;
import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.HTMLCollection;
import js.html.HTMLElement;
import js.html.HTMLImageElement;
import js.html.Image;
import js.html.MediaError;
import js.html.Node;
import js.html.Window;
import js.lib.File;
import js.lib.Reflect;
import js.lib.TypedArray;
import js.sys.ArrayBuffer;
import js.sys.ArrayBuffers;
import js.sys.ArrayBufferView;
import js.sys.DataView;
import js.sys.Error;
import js.sys.Function;
import js.sys.Object;
import js.sys.Reflect;
import js.sys.Sys;
import js.sys.TypedArray;
import js.WebGL.RenderingContext;
import js.WebGL.WebGLActiveInfo;
import js.WebGL.WebGLBuffer;
import js.WebGL.WebGLContextEvent;
import js.WebGL.WebGLFramebuffer;
import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderbuffer;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLShaderPrecisionFormat;
import js.WebGL.WebGLTexture;
import js.WebGL.WebGLUniformLocation;
import js.WebGL.WebGLVertexArrayObject;
import openfl._internal.Lib;
import openfl._internal.renderer.webgl.GLBuffer;
import openfl._internal.renderer.webgl.GLFramebuffer;
import openfl._internal.renderer.webgl.GLProgram;
import openfl._internal.renderer.webgl.GLShader;
import openfl._internal.renderer.webgl.GLTexture;
import openfl._internal.renderer.webgl.GLVertexArrayObject;
import openfl._internal.renderer.webgl.utils.FilterTexture;
import openfl._internal.renderer.webgl.utils.WebGLUtils;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.CairoRenderer;
import openfl.display.CanvasRenderer;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObjectRenderer;
import openfl.display.DOMRenderer;
import openfl.display.FPS;
import openfl.display.FrameLabel;
import openfl.display.FrameScript;
import openfl.display.Graphics;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.LoaderInfo;
import openfl.display.OpenGLRenderer;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.display.ShaderParameterKind;
import openfl.display.ShaderParameterType;
import openfl.display.ShaderPrecision;
import openfl.display.ShaderType;
import openfl.display.Stage;
import openfl.display.Stage3D;
import openfl.display.StageAlign;
import openfl.display.StageDisplayState;
import openfl.display.StageQuality;
import openfl.display.StageScaleMode;
import openfl.display.StageScaleModeEvent;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DMipFilter;
import openfl.display3D.Context3DProgramFormat;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.Context3DWrapMode;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.VideoTexture;
import openfl.errors.Error;
import openfl.errors.IllegalOperationError;
import openfl.errors.IOError;
import openfl.errors.RangeError;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.EventPhase;
import openfl.events.FocusEvent;
import open.fl.Assets;
import open.fl.HasEventListener;
import open.fl.IAssetCache;
import open.fl._internal.renderer.RenderSession;
import open.fl._internal.renderer.cairo.CairoGraphics;
import open.fl._internal.renderer.canvas.CanvasGraphics;
import open.fl._internal.renderer.canvas.CanvasTextField;
import open.fl._internal.renderer.canvas.CanvasVideo;
import open.fl._internal.renderer.dom.DOMDisplayObject;
import open.fl._internal.renderer.dom.DOMTextField;
import open.fl._internal.renderer.dom.DOMVideo;
import open.fl._internal.renderer.opengl.GLGraphics;
import open.fl._internal.renderer.opengl.GLTextField;
import open.fl._internal.renderer.opengl.GLVideo;
import open.fl._internal.renderer.opengl.utils.GLUtils;
import open.fl._internal.swf.SWFLite;
import open.fl._internal.text.GlyphPosition;
import open.fl._internal.text.TextEngine;
import open.fl._internal.text.TextFormat;
import open.fl._internal.text.TextLine;
import open.fl._internal.text.TextLineMetrics;
import open.fl._Vector;
import open.fl._Vector_Float;
import open.fl._Vector_Impl_;
import open.fl._Vector_Int;
import open.fl._Vector_Object;
import open.fl._Vector_String;
import open.fl._Vector_openfl_display_FrameLabel;
import open.fl._Vector_openfl_display_FrameScript;
import open.fl._Vector_openfl_display_Shader;
import open.fl._Vector_openfl_display_ShaderParameter;
import open.fl._Vector_openfl_geom_ColorTransform;
import open.fl._Vector_openfl_geom_Matrix;
import open.fl._Vector_openfl_geom_Matrix3D;
import open.fl._Vector_openfl_geom_Orientation3D;
import open.fl._Vector_openfl_geom_Point;
import open.fl._Vector_openfl_geom_Rectangle;
import geometry.Geometry;
import geometry.utils.Shape;
import geometry.utils.ShapeUtils;
import haxe.Log;
import haxe.Resource;
import haxe.Timer;
import haxe.ds.IntMap;
import haxe.format.JsonParser;
import haxe.format.JsonPrinter;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import haxe.io.PathKind;
import haxe.io.Paths;
import haxe.rtti.Meta;
import haxe.rtti.MetaExpr;
import haxe.unit.TestCase;
import js.Browser;
import js.html;
import js.html._Location;
import js.html.AudioContext;
import js.html.Blob;
import js.html.FormData;
import js.html.ImageBitmap;
import js.html.ImageData;
import js.html.Location;
import js.html.MessageEvent;
import js.html.OffscreenCanvas;
import js.html.Option;
import js.html.Selection;
import js.html.Storage;
import js.html.URL;
import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestUpload;
import js.lib.Date;
import js.node.ChildProcess;
import js.node.ReadStream;
import js.node.WriteStream;
import js.sys.ArrayBufferView;
import js.sys.Function;
import js.WebGL;
import js.WebGL.EXT_blend_minmax;
import js.WebGL.EXT_frag_depth;
import js.WebGL.EXT_sRGB;
import js.WebGL.EXT_shader_texture_lod;
import js.WebGL.OES_element_index_uint;
import js.WebGL.OES_standard_derivatives;
import js.WebGL.OES_texture_float;
import js.WebGL.OES_texture_float_linear;
import js.WebGL.OES_texture_half_float;
import js.WebGL.OES_texture_half_float_linear;
import js.WebGL.OES_vertex_array_object;
import js.WebGL.WebGL2RenderingContext;
import js.WebGL.WebGLActiveInfo;
import js.WebGL.WebGLBuffer;
import js.WebGL.WebGLContextAttributes;
import js.WebGL.WebGLContextEvent;
import js.WebGL.WebGLFramebuffer;
import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderbuffer;
import js.WebGL.WebGLShader;
import js.WebGL.WebGLShaderPrecisionFormat;
import js.WebGL.WebGLTexture;
import js.WebGL.WebGLUniformLocation;
import js.WebGL.WebGLVertexArrayObject;
import js.WebGL.WebGLVertexArrayObjectOES;
import js.html.performance.Performance;
import js.html.performance.PerformanceEntry;
import js.html.performance.PerformanceMark;
import js.html.performance.PerformanceMeasure;
import js.html.performance.PerformanceObserver;
import js.html.performance.PerformanceObserverEntryList;
import js.html.performance.PerformancePaintTiming;
import js.html.performance.PerformanceTiming;
import js.html.performance.PerformanceNavigation;
import js.html.performance.PerformanceNavigationTiming;
import js.html.performance.PerformanceResourceTiming;
import js.html.performance.PerformanceServerTiming;
import js.html.performance.PerformanceLongTaskTiming;
import js.html.performance.Performance;
import js.html.performance.PerformanceEntry;
import js.html.performance.PerformanceMark;
import js.html.performance.PerformanceMeasure;
import js.html.performance.PerformanceObserver;
import js.html.performance.PerformanceObserverEntryList;
import js.html.performance.PerformancePaintTiming;
import js.html.performance.PerformanceTiming;
import js.html.performance.PerformanceNavigation;
import js.html.performance.PerformanceNavigationTiming;
import js.html.performance.PerformanceResourceTiming;
import js.html.performance.PerformanceServerTiming;
import js.html.performance.PerformanceLongTaskTiming;

class ShapeGeometry extends Geometry {
	public var shapes:Array<Shape> = [];
	public var curveSegments:Int;

	public function new(shapes:Array<Shape> = [new Shape([new openfl.geom.Vector2D(0, 0.5), new openfl.geom.Vector2D(-0.5, -0.5), new openfl.geom.Vector2D(0.5, -0.5)])], curveSegments:Int = 12) {
		super();

		this.type = 'ShapeGeometry';

		this.shapes = shapes;
		this.curveSegments = curveSegments;

		this.buildGeometry();
	}

	public function copy(source:ShapeGeometry):ShapeGeometry {
		super.copy(source);

		this.shapes = source.shapes;
		this.curveSegments = source.curveSegments;

		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();

		var shapes = [];
		for (shape in this.shapes) {
			shapes.push(shape.uuid);
		}

		data.shapes = shapes;

		return data;
	}

	public static function fromJSON(data:Dynamic, shapes:Array<Shape>):ShapeGeometry {
		var geometryShapes = [];
		for (shape in shapes) {
			geometryShapes.push(shapes[shape]);
		}

		return new ShapeGeometry(geometryShapes, data.curveSegments);
	}

	private function buildGeometry() {
		var indices = [];
		var vertices = [];
		var normals = [];
		var uvs = [];

		var groupStart = 0;
		var groupCount = 0;

		if (!Std.is(this.shapes, Array)) {
			this.addShape(this.shapes);
		} else {
			for (shape in this.shapes) {
				this.addShape(shape);

				this.addGroup(groupStart, groupCount, indices.length);

				groupStart += groupCount;
				groupCount = 0;
			}
		}

		this.setIndex(indices);
		this.setAttribute('position', new Float32Array(vertices));
		this.setAttribute('normal', new Float32Array(normals));
		this.setAttribute('uv', new Float32Array(uvs));
	}

	private function addShape(shape:Shape) {
		var indexOffset = vertices.length / 3;
		var points = shape.extractPoints(this.curveSegments);

		var shapeVertices = points.shape;
		var shapeHoles = points.holes;

		if (!ShapeUtils.isClockWise(shapeVertices)) {
			shapeVertices = shapeVertices.reverse();
		}

		for (hole in shapeHoles) {
			var shapeHole = shapeHoles[hole];

			if (ShapeUtils.isClockWise(shapeHole)) {
				shapeHoles[hole] = shapeHole.reverse();
			}
		}

		var faces = ShapeUtils.triangulateShape(shapeVertices, shapeHoles);

		for (hole in shapeHoles) {
			var shapeHole = shapeHoles[hole];
			shapeVertices = shapeVertices.concat(shapeHole);
		}

		for (vertex in shapeVertices) {
			var vertex = shapeVertices[vertex];

			vertices.push(vertex.x, vertex.y, 0);
			normals.push(0, 0, 1);
			uvs.push(vertex.x, vertex.y);
		}

		for (face in faces) {
			var face = faces[face];

			var a = face[0] + indexOffset;
			var b = face[1] + indexOffset;
			var c = face[2] + indexOffset;

			indices.push(a, b, c);
			groupCount += 3;
		}
	}
}

class ShapeUtils {
	public static function isClockWise(points:Array<openfl.geom.Vector2D>):Bool {
		var sum = 0.0;
		for (i in 0...points.length) {
			var v1 = points[i];
			var v2 = points[(i + 1) % points.length];

			sum += ((v2.x - v1.x) * (v2.y + v1.y));
		}

		return sum < 0;
	}

	public static function triangulateShape(contour:Array<openfl.geom.Vector2D>, holes:Array<Array<openfl.geom.Vector2D>> = []):Array<Array<Int>> {
		var n = contour.length;
		var h = holes.length;

		var result = [];

		var hash = [];
		for (i in 0...(n + h)) {
			hash.push(0);
		}

		var eof = n + h;
		var maxTriangles = (n + eof) * (h + 2);
		var nvt = eof * 2; // 2 vertices per triangle
		var triangles = [];

		var V = [];
		for (i in 0...nvt) {
			V.push(0);
		}

		var vn = [contour];
		for (i in 0...h) {
			vn.push(holes[i]);
		}

		var vt = [];
		var Vt = [];
		for (i in 0...vn.length) {
			var Vn = vn[i];
			var Vtn = [];
			var Vti = [];
			for (j in 0...Vn.length) {
				Vtn.push(Vn[j].x);
				Vti.push(Vn[j].y);
			}

			var nvt = Vtn.length;

			var k = 0;
			for (j in 0...nvt) {
				var p = Vt.length;
				Vt.push(Vti[j]);
				V[p] = Vtn[k];
				k += 1;
			}

			vt.push(Vt);