import three.math.Color;
import three.core.BufferAttribute;
import three.core.BufferGeometry;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.math.Vector3;
import js.typedarrays.TypedArray;
import js.typedarrays.ArrayBufferView;
import js.typedarrays.Float32Array;
import js.typedarrays.Uint32Array;
import js.typedarrays.DataView;
import js.xml.XML;
import js.xml.XMLList;
import js.util.TextDecoder;
import js.Lib;
import js.Js;

class VTKLoader extends Loader {

	public function new(manager:Loader.Manager) {
		super(manager);
	}

	public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic):Void {
		var scope = this;
		var loader = new FileLoader(scope.manager);
		loader.setPath(scope.path);
		loader.setResponseType("arraybuffer");
		loader.setRequestHeader(scope.requestHeader);
		loader.setWithCredentials(scope.withCredentials);
		loader.load(url, function (text:ArrayBufferView) {
			try {
				onLoad(scope.parse(TextDecoder.wrap(text)));
			} catch(e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				scope.manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function parse(data:ArrayBufferView):BufferGeometry {
		function parseASCII(data:String):BufferGeometry {
			// connectivity of the triangles
			var indices:Array<Int> = [];
			// triangles vertices
			var positions:Array<Vector3> = [];
			// red, green, blue colors in the range 0 to 1
			var colors:Array<Float> = [];
			// normal vector, one per vertex
			var normals:Array<Vector3> = [];
			var result:Dynamic;
			// pattern for detecting the end of a number sequence
			var patWord = /^[^\d.\s-]+/;
			// pattern for reading vertices, 3 floats or integers
			var pat3Floats = /(\-?\d+\.?[\d\-\+e]*)\s+(\-?\d+\.?[\d\-\+e]*)\s+(\-?\d+\.?[\d\-\+e]*)/g;
			// pattern for connectivity, an integer followed by any number of ints
			// the first integer is the number of polygon nodes
			var patConnectivity = /(\d+)\s+([\s\d]*)/;
			// indicates start of vertex data section
			var patPOINTS = /^POINTS /;
			// indicates start of polygon connectivity section
			var patPOLYGONS = /^POLYGONS /;
			// indicates start of triangle strips section
			var patTRIANGLE_STRIPS = /^TRIANGLE_STRIPS /;
			// POINT_DATA number_of_values
			var patPOINT_DATA = /^POINT_DATA[ ]+(\d+)/;
			// CELL_DATA number_of_polys
			var patCELL_DATA = /^CELL_DATA[ ]+(\d+)/;
			// Start of color section
			var patCOLOR_SCALARS = /^COLOR_SCALARS[ ]+(\w+)[ ]+3/;
			// NORMALS Normals float
			var patNORMALS = /^NORMALS[ ]+(\w+)[ ]+(\w+)/;

			var inPointsSection = false;
			var inPolygonsSection = false;
			var inTriangleStripSection = false;
			var inPointDataSection = false;
			var inCellDataSection = false;
			var inColorSection = false;
			var inNormalsSection = false;

			var color = new Color();

			var lines = data.split('\n');

			for (var i in lines) {
				var line = lines[i].trim();

				if (line.indexOf("DATASET") === 0) {
					var dataset = line.split(" ")[1];
					if (dataset !== "POLYDATA") throw "Unsupported DATASET type: " + dataset;
				} else if (inPointsSection) {
					// get the vertices
					while ((result = pat3Floats.exec(line)) !== null) {
						if (patWord.exec(line) !== null) break;
						var x = parseFloat(result[1]);
						var y = parseFloat(result[2]);
						var z = parseFloat(result[3]);
						positions.push(new Vector3(x, y, z));
					}
				} else if (inPolygonsSection) {
					if ((result = patConnectivity.exec(line)) !== null) {
						// numVertices i0 i1 i2 ...
						var numVertices = parseInt(result[1]);
						var inds = result[2].split(/\s+/);
						if (numVertices >= 3) {
							var i0 = parseInt(inds[0]);
							var k = 1;
							// split the polygon in numVertices - 2 triangles
							for (var j = 0; j < numVertices - 2; ++j) {
								var i1 = parseInt(inds[k]);
								var i2 = parseInt(inds[k + 1]);
								indices.push(i0, i1, i2);
								k++;
							}
						}
					}
				} else if (inTriangleStripSection) {
					if ((result = patConnectivity.exec(line)) !== null) {
						// numVertices i0 i1 i2 ...
						var numVertices = parseInt(result[1]);
						var inds = result[2].split(/\s+/);
						if (numVertices >= 3) {
							// split the polygon in numVertices - 2 triangles
							for (var j = 0; j < numVertices - 2; j++) {
								if (j % 2 == 1) {
									indices.push(inds[j], inds[j + 2], inds[j + 1]);
								} else {
									indices.push(inds[j], inds[j + 1], inds[j + 2]);
								}
							}
						}
					}
				} else if (inPointDataSection || inCellDataSection) {
					if (inColorSection) {
						// Get the colors
						while ((result = pat3Floats.exec(line)) !== null) {
							if (patWord.exec(line) !== null) break;
							var r = parseFloat(result[1]);
							var g = parseFloat(result[2]);
							var b = parseFloat(result[3]);
							color.setRGB(r, g, b).convertSRGBToLinear();
							colors.push(color.r, color.g, color.b);
						}
					} else if (inNormalsSection) {
						// Get the normal vectors
						while ((result = pat3Floats.exec(line)) !== null) {
							if (patWord.exec(line) !== null) break;
							var x = parseFloat(result[1]);
							var y = parseFloat(result[2]);
							var z = parseFloat(result[3]);
							normals.push(new Vector3(x, y, z));
						}
					}
				}

				if (patPOLYGONS.exec(line) !== null) {
					inPolygonsSection = true;
					inPointsSection = false;
					inTriangleStripSection = false;
				} else if (patPOINTS.exec(line) !== null) {
					inPolygonsSection = false;
					inPointsSection = true;
					inTriangleStripSection = false;
				} else if (patTRIANGLE_STRIPS.exec(line) !== null) {
					inPolygonsSection = false;
					inPointsSection = false;
					inTriangleStripSection = true;
				} else if (patPOINT_DATA.exec(line) !== null) {
					inPointDataSection = true;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				} else if (patCELL_DATA.exec(line) !== null) {
					inCellDataSection = true;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				} else if (patCOLOR_SCALARS.exec(line) !== null) {
					inColorSection = true;
					inNormalsSection = false;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				} else if (patNORMALS.exec(line) !== null) {
					inNormalsSection = true;
					inColorSection = false;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				}
			}

			var geometry = new BufferGeometry();
			geometry.setIndex(new BufferAttribute(Uint32Array.from(indices), 1));
			geometry.setAttribute("position", new BufferAttribute(Float32Array.from(positions.map(function(v) v.toArray())), 3));

			if (normals.length === positions.length) {
				geometry.setAttribute("normal", new BufferAttribute(Float32Array.from(normals.map(function(v) v.toArray())), 3));
			}

			if (colors.length !== indices.length) {
				// stagger
				if (colors.length === positions.length) {
					geometry.setAttribute("color", new BufferAttribute(Float32Array.from(colors), 3));
				}
			} else {
				// cell
				geometry = geometry.toNonIndexed();
				var numTriangles = geometry.attributes.position.count / 3;

				if (colors.length === (numTriangles * 3)) {
					var newColors = [];
					for (var i = 0; i < numTriangles; i++) {
						var r = colors[3 * i + 0];
						var g = colors[3 * i + 1];
						var b = colors[3 * i + 2];
						color.setRGB(r, g, b).convertSRGBToLinear();
						newColors.push(color.r, color.g, color.b);
						newColors.push(color.r, color.g, color.b);
						newColors.push(color.r, color.g, color.b);
					}
					geometry.setAttribute("color", new BufferAttribute(Float32Array.from(newColors), 3));
				}
			}

			return geometry;
		}

		function parseBinary(data:ArrayBufferView):BufferGeometry {
			var buffer = new Uint8Array(data);
			var dataView = new DataView(data);
			// Points and normals, by default, are empty
			var points = [];
			var normals = [];
			var indices = [];
			var lookup32 = TypedArray.create(Uint32Array, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]);
			function findString(buffer:ArrayBufferView, start:Int):Dynamic {
				var index = start;
				var c = buffer[index];
				var s = [];
				while (c != 10) {
					s.push(String.fromCharCode(c));
					index++;
					c = buffer[index];
				}
				return {start: start, end: index, next: index + 1, parsedString: s.join('')};
			}
			var state, line;
			while (true) {
				// Get a string
				state = findString(buffer, index);
				line = state.parsedString;
				if (line.indexOf("DATASET") === 0) {
					var dataset = line.split(" ")[1];
					if (dataset !== "POLYDATA") throw "Unsupported DATASET type: " + dataset;
				} else if (inPointsSection) {
					// Add the points
					var numPoints = parseInt(line.split(" ")[1]), count = numPoints * 4 * 3;
					points = new Float32Array(numPoints * 3);
					var pointIndex = state.next;
					for (var i = 0; i < numPoints; i++) {
						points[3 * i] = dataView.getFloat32(pointIndex, false);
						pointIndex += 4;
						points[3 * i + 1] = dataView.getFloat32(pointIndex, false);
						pointIndex += 4;
						points[3 * i + 2] = dataView.getFloat32(pointIndex, false);
						pointIndex += 4;
					}
					// increment our next pointer
					state.next += count + 1;
				} else if (inTriangleStripSection) {
					if ((result = patConnectivity.exec(line)) !== null) {
						// numVertices i0 i1 i2 ...
						var numVertices = parseInt(result[1]);
						var inds = result[2].split(/\s+/);
						if (numVertices >= 3) {
							// split the polygon in numVertices - 2 triangles
							for (var j = 0; j < numVertices - 2; j++) {
								if (j % 2 == 1) {
									indices.push(lookup32[inds[j]], lookup32[inds[j + 2]], lookup32[inds[j + 1]]);
								} else {
									indices.push(lookup32[inds[j]], lookup32[inds[j + 1]], lookup32[inds[j + 2]]);
								}
							}
						}
					}
				} else if (inPolygonsSection) {
					if ((result = patConnectivity.exec(line)) !== null) {
						// numVertices i0 i1 i2 ...
						var numVertices = parseInt(result[1]);
						var inds = result[2].split(/\s+/);
						if (numVertices >= 3) {
							// split the polygon in numVertices - 2 triangles
							for (var j = 0; j < numVertices - 2; j++) {
								indices.push(lookup32[inds[j]], lookup32[inds[j + 1]], lookup32[inds[j + 2]]);
							}
						}
					}
				} else if (inPointDataSection || inCellDataSection) {
					if (inColorSection) {
						// Get the colors
						while ((result = pat3Floats.exec(line)) !== null) {
							if (patWord.exec(line) !== null) break;
							var r = parseFloat(result[1]);
							var g = parseFloat(result[2]);
							var b = parseFloat(result[3]);
							color.setRGB(r, g, b).convertSRGBToLinear();
							colors.push(color.r, color.g, color.b);
						}
					} else if (inNormalsSection) {
						// Get the normal vectors
						while ((result = pat3Floats.exec(line)) !== null) {
							if (patWord.exec(line) !== null) break;
							var x = parseFloat(result[1]);
							var y = parseFloat(result[2]);
							var z = parseFloat(result[3]);
							normals.push(new Vector3(x, y, z));
						}
					}
				}
				if (patPOLYGONS.exec(line) !== null) {
					inPolygonsSection = true;
					inPointsSection = false;
					inTriangleStripSection = false;
				} else if (patPOINTS.exec(line) !== null) {
					inPolygonsSection = false;
					inPointsSection = true;
					inTriangleStripSection = false;
				} else if (patTRIANGLE_STRIPS.exec(line) !== null) {
					inPolygonsSection = false;
					inPointsSection = false;
					inTriangleStripSection = true;
				} else if (patPOINT_DATA.exec(line) !== null) {
					inPointDataSection = true;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				} else if (patCELL_DATA.exec(line) !== null) {
					inCellDataSection = true;
					inPointsSection = false;
					inPolygonsSection = false;
					inTriangleStripSection = false;
				}
				// Increment index
				index = state.next;
				if (index >= buffer.byteLength) {
					break;
				}
			}
			var geometry = new BufferGeometry();
			geometry.setIndex(new BufferAttribute(Uint32Array.from(indices), 1));
			geometry.setAttribute("position", new BufferAttribute(Float32Array.from(points), 3));
			if (normals.length === points.length) {
				geometry.setAttribute("normal", new BufferAttribute(Float32Array.from(normals.map(function(v) v.toArray())), 3));
			}
			return geometry;
		}

		function parseXML(stringFile:String):BufferGeometry {
			// Changes XML to JSON, based on https://davidwalsh.name/convert-xml-json
			function xmlToJson(xml:XML):Dynamic {
				// Create the return object
				var obj:Dynamic = {};
				// Deal with attributes
				if (xml.nodeType === 1) {
					if (xml.attributes) {
						if (xml.attributes.length > 0) {
							obj["attributes"] = {};
							for (var i = 0; i < xml.attributes.length; i++) {
								var attribute = xml.attributes.item(i);
								obj["attributes"][attribute.nodeName] = attribute.nodeValue.trim();
							}
						}
					}
				} else if (xml.nodeType === 3) {
					obj = xml.nodeValue.trim();
				}
				// Deal with children
				if (xml.hasChildNodes()) {
					for (var i = 0; i < xml.childNodes.length; i++) {
						var item = xml.childNodes.item(i);
						var nodeName = item.nodeName;
						if (typeof obj[nodeName] === "undefined") {
							var tmp = xmlToJson(item);
							if (tmp !== "") obj[nodeName] = tmp;
						} else {
							if (typeof obj[nodeName].push === "undefined") {
								var old = obj[nodeName];
								obj[nodeName] = [old];
							}
							var tmp = xmlToJson(item);
							if (tmp !== "") obj[nodeName].push(tmp);
						}
					}
				}
				return obj;
			}
			// Taken from Base64-js
			function Base64toByteArray(b64:String):ArrayBufferView {
				var Arr = typeof Uint8Array !== "undefined" ? Uint8Array : Array;
				var revLookup:Dynamic = {};
				var code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
				for (var i = 0, l = code.length; i < l; i++) revLookup[code.charCodeAt(i)] = i;
				revLookup["-".charCodeAt(0)] = 62;
				revLookup["_".charCodeAt(0)] = 63;
				var len = b64.length;
				if (len % 4 > 0) throw new Error("Invalid string. Length must be a multiple of 4");
				var pad = len % 4;
				var arr = new Arr(len * 3 / 4 - pad);
				var l = pad > 0 ? len - 4 : len;
				var L = 0;
				for (var i = 0, j = 0; i < l; i += 4, j += 3) {
					var tmp =
						(revLookup[b64.charCodeAt(i)] << 18) |
						(revLookup[b64.charCodeAt(i + 1)] << 12) |
						(revLookup[b64.charCodeAt(i + 2)] << 6) |
						revLookup[b64.charCodeAt(i + 3)];
					arr[L++] = (tmp >> 16) & 0xFF;
					arr[L++] = (tmp >> 8) & 0xFF;
					arr[L++] = tmp & 0xFF;
				}
				if (pad === 2) {
					var tmp =
						(revLookup[b64.charCodeAt(i)] << 2) |
						(revLookup[b64.charCodeAt(i + 1)] >> 4);
					arr[L++] = tmp & 0xFF;
				} else if (pad === 3) {
					var tmp =
						(revLookup[b64.charCodeAt(i)] << 10) |
						(revLookup[b64.charCodeAt(i + 1)] << 4) |
						(revLookup[b64.charCodeAt(i + 2)] >> 2);
					arr[L++] = (tmp >> 8) & 0xFF;
					arr[L++] = tmp & 0xFF;
				}
				return arr;
			}
			function parseDataArray(ele:XML, compressed:Bool):ArrayBufferView {
				var numBytes = 0;
				if (ele.attributes.hasOwnProperty("header_type")) {
					if (ele.attributes.header_type === "UInt64") {
						numBytes = 8;
					} else if (ele.attributes.header_type === "UInt32") {
						numBytes = 4;
					}
				}
				var txt:ArrayBufferView, content:ArrayBufferView;
				if (ele.attributes.format === "binary") {
					if (compressed) {
						if (ele.attributes.type === "Float32") {
							txt = new Float32Array( 0 );
						} else if (ele.attributes.type === "Int32" || ele.attributes.type === "Int64") {
							txt = new Int32Array( 0 );
						}
						// VTP data with the header has the following structure:
						// [#blocks][#u-size][#p-size][#c-size-1][#c-size-2]...[#c-size-#blocks][DATA]
						//
						// Each token is an integer value whose type is specified by "header_type" at the top of the file (UInt32 if no type specified). The token meanings are:
						// [#blocks] = Number of blocks
						// [#u-size] = Block size before compression
						// [#p-size] = Size of last partial block (zero if it not needed)
						// [#c-size-i] = Size in bytes of block i after compression
						//
						// The [DATA] portion stores contiguously every block appended together. The offset from the beginning of the data section to the beginning of a block is
						// computed by summing the compressed block sizes from preceding blocks according to the header.
						var textNode = ele["#text"];
						if (Array.isArray(textNode)) textNode = textNode[0];
						var rawData = Base64toByteArray(textNode);
						var byteData = new DataView(rawData.buffer);
						// Each data point consists of 8 bits regardless of the header type
						var dataPointSize = 8;
						var blocks = byteData.getUint32(0, false);
						var headers = new Uint8Array(numBytes);
						headers.set(rawData.subarray(0, numBytes));
						var position = numBytes;
						for (var i = 0; i < numBytes; i++) {
							blocks |= (headers[i] & 0xFF) << (i * dataPointSize);
						}
						var blockSize = bytesToUint32(byteData.getUint32(position, false));
						position += 4;
						var dataOffsets:Array<Int> = [position];
						var partialBlockSize = 0;
						var dataStart = position;
						while (position