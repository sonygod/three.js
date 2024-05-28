import js.Browser.Window;
import js.Node.Buffer;
import js.Node.Fs;
import js.Node.Path;
import js.html.ArrayBuffer;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Int8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.Uint8ClampedArray;
import js.html.WebGl.RenderingContext;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.VideoTexture;
import openfl.errors.Error;
import openfl.events.ActivityEvent;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.FocusEvent;
import openfl.events.FullScreenEvent;
import openfl.events.GameInputEvent;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.events.ProgressEvent;
import openflCoefficient.AudioCoefficients;
import openflNet.NetConnection;
import openflNet.NetStream;
import openflNet.NetStreamInfo;
import openflNet.SharedObject;
import openflNet.SharedObjectFlushStatus;
import openflNet.SharedObjectEvent;
import openflText.TextFormat;
import openflText.TextField;
import openflText.TextFieldAutoSize;
import openflText.TextFieldType;
import openflUtils.ByteArray;
import openflUtils.CompressionAlgorithm;
import openflUtils.Dictionary;
import openflUtils.Endian;
import openflUtils.ObjectEncoding;

import haxe.Resource;
import haxe.io.Bytes;

class WireframeGeometry extends BufferGeometry {
	public var parameters: { geometry: BufferGeometry; };
	public var type: String;

	public function new(geometry: BufferGeometry = null) {
		super();
		type = 'WireframeGeometry';
		parameters = { geometry: geometry };

		if (geometry != null) {
			var vertices = [];
			var edges = new Set<String>();
			var start = new Vector3();
			var end = new Vector;

			if (geometry.index != null) {
				var position = geometry.attributes.get_position();
				var indices = geometry.index;
				var groups = geometry.groups;

				if (groups.length == 0) {
					groups = [ { start: 0, count: indices.count, materialIndex: 0 } ];
				}

				for (group in groups) {
					var groupStart = group.start;
					var groupCount = group.count;

					for (i = groupStart; i < groupStart + groupCount; i += 3) {
						for (j = 0; j < 3; j++) {
							var index1 = indices.getX(i + j);
							var index2 = indices.getX(i + (j + 1) % 3);

							start.fromBufferAttribute(position, index1);
							end.fromBufferAttribute(position, index2);

							if (isUniqueEdge(start, end, edges)) {
								vertices.push(start.x, start.y, start.z);
								vertices.push(end.x, end.y, end.z);
							}
						}
					}
				}
			} else {
				var position = geometry.attributes.get_position();

				for (i = 0; i < position.count / 3; i++) {
					for (j = 0; j < 3; j++) {
						var index1 = 3 * i + j;
						var index2 = 3 * i + (j + 1) % 3;

						start.fromBufferAttribute(position, index1);
						end.fromBufferAttribute(position, index2);

						if (isUniqueEdge(start, end, edges)) {
							vertices.push(start.x, start.y, start.z);
							vertices.push(end.x, end.y, end.z);
						}
					}
				}
			}

			var positionAttribute = new Float32BufferAttribute(vertices, 3);
			setAttribute('position', positionAttribute);
		}
	}

	public function copy(source: WireframeGeometry) : WireframeGeometry {
		super.copy(source);
		parameters = source.parameters;
		return this;
	}

	public static function isUniqueEdge(start: Vector3, end: Vector3, edges: Set<String>) : Bool {
		var hash1 = start.x + ',' + start.y + ',' + start.z + '-' + end.x + ',' + end.y + ',' + end.z;
		var hash2 = end.x + ',' + end.y + ',' + end.z + '-' + start.x + ',' + start.y + ',' + start.z;

		if (edges.exists(hash1) || edges.exists(hash2)) {
			return false;
		} else {
			edges.add(hash1);
			edges.add(hash2);
			return true;
		}
	}
}