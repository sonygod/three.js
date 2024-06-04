import three.core.BufferGeometry;
import three.loaders.Loader;
import three.math.Color;
import three.core.Float32BufferAttribute;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Encoding;
import haxe.io.Input;

/**
 * Description: A THREE loader for PLY ASCII files (known as the Polygon
 * File Format or the Stanford Triangle Format).
 *
 * Limitations: ASCII decoding assumes file is UTF-8.
 *
 * Usage:
 *	const loader = new PLYLoader();
 *	loader.load('./models/ply/ascii/dolphins.ply', function (geometry) {
 *
 *		scene.add( new THREE.Mesh( geometry ) );
 *
 *	} );
 *
 * If the PLY file uses non standard property names, they can be mapped while
 * loading. For example, the following maps the properties
 * “diffuse_(red|green|blue)” in the file to standard color names.
 *
 * loader.setPropertyNameMapping( {
 *	diffuse_red: 'red',
 *	diffuse_green: 'green',
 *	diffuse_blue: 'blue'
 * } );
 *
 * Custom properties outside of the defaults for position, uv, normal
 * and color attributes can be added using the setCustomPropertyNameMapping method.
 * For example, the following maps the element properties “custom_property_a”
 * and “custom_property_b” to an attribute “customAttribute” with an item size of 2.
 * Attribute item sizes are set from the number of element properties in the property array.
 *
 * loader.setCustomPropertyNameMapping( {
 *	customAttribute: ['custom_property_a', 'custom_property_b'],
 * } );
 *
 */

class PLYLoader extends Loader {

	public var propertyNameMapping:Map<String, String> = new Map();
	public var customPropertyMapping:Map<String, Array<String>> = new Map();

	public function new(manager:Loader = null) {
		super(manager);
	}

	public function load(url:String, onLoad:BufferGeometry->Void, onProgress:Dynamic->Void = null, onError:Dynamic->Void = null) {
		var scope = this;
		var loader = new FileLoader(manager);
		loader.setPath(path);
		loader.setResponseType('arraybuffer');
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);
		loader.load(url, function(text:Bytes) {
			try {
				onLoad(scope.parse(text));
			} catch (e:Dynamic) {
				if (onError != null) {
					onError(e);
				} else {
					console.error(e);
				}
				manager.itemError(url);
			}
		}, onProgress, onError);
	}

	public function setPropertyNameMapping(mapping:Map<String, String>) {
		propertyNameMapping = mapping;
	}

	public function setCustomPropertyNameMapping(mapping:Map<String, Array<String>>) {
		customPropertyMapping = mapping;
	}

	public function parse(data:Bytes):BufferGeometry {

		function parseHeader(data:Bytes, headerLength:Int = 0):Dynamic {
			var patternHeader = ~/^ply([\s\S]*)end_header(\r\n|\r|\n)/;
			var headerText:String = '';
			var result = patternHeader.exec(data.toString(Encoding.UTF8));

			if (result != null) {
				headerText = result[1];
			}

			var header = {
				comments: new Array<String>(),
				elements: new Array<Dynamic>(),
				headerLength: headerLength,
				objInfo: ''
			};

			var lines = headerText.split(/\r\n|\r|\n/);
			var currentElement:Dynamic;

			function make_ply_element_property(propertValues:Array<String>, propertyNameMapping:Map<String, String>):Dynamic {
				var property = { type: propertValues[0] };

				if (property.type == 'list') {
					property.name = propertValues[3];
					property.countType = propertValues[1];
					property.itemType = propertValues[2];
				} else {
					property.name = propertValues[1];
				}

				if (propertyNameMapping.exists(property.name)) {
					property.name = propertyNameMapping.get(property.name);
				}

				return property;
			}

			for (i in 0...lines.length) {
				var line = lines[i];
				line = line.trim();

				if (line == '') continue;

				var lineValues = line.split(/\s+/);
				var lineType = lineValues.shift();
				line = lineValues.join(' ');

				switch (lineType) {
					case 'format':
						header.format = lineValues[0];
						header.version = lineValues[1];
						break;
					case 'comment':
						header.comments.push(line);
						break;
					case 'element':
						if (currentElement != null) {
							header.elements.push(currentElement);
						}
						currentElement = {};
						currentElement.name = lineValues[0];
						currentElement.count = Std.parseInt(lineValues[1]);
						currentElement.properties = new Array<Dynamic>();
						break;
					case 'property':
						currentElement.properties.push(make_ply_element_property(lineValues, propertyNameMapping));
						break;
					case 'obj_info':
						header.objInfo = line;
						break;
					default:
						console.log('unhandled', lineType, lineValues);
				}
			}

			if (currentElement != null) {
				header.elements.push(currentElement);
			}

			return header;
		}

		function parseASCIINumber(n:String, type:String):Float {
			switch (type) {
				case 'char': case 'uchar': case 'short': case 'ushort': case 'int': case 'uint':
				case 'int8': case 'uint8': case 'int16': case 'uint16': case 'int32': case 'uint32':
					return Std.parseInt(n);
				case 'float': case 'double': case 'float32': case 'float64':
					return Std.parseFloat(n);
			}
			return 0.;
		}

		function parseASCIIElement(properties:Array<Dynamic>, tokens:ArrayStream):Dynamic {
			var element = {};

			for (i in 0...properties.length) {
				if (tokens.empty()) return null;
				if (properties[i].type == 'list') {
					var list = new Array<Float>();
					var n = parseASCIINumber(tokens.next(), properties[i].countType);
					for (j in 0...n) {
						if (tokens.empty()) return null;
						list.push(parseASCIINumber(tokens.next(), properties[i].itemType));
					}
					element[properties[i].name] = list;
				} else {
					element[properties[i].name] = parseASCIINumber(tokens.next(), properties[i].type);
				}
			}
			return element;
		}

		function createBuffer():Dynamic {
			var buffer = {
			  indices: new Array<Int>(),
			  vertices: new Array<Float>(),
			  normals: new Array<Float>(),
			  uvs: new Array<Float>(),
			  faceVertexUvs: new Array<Float>(),
			  colors: new Array<Float>(),
			  faceVertexColors: new Array<Float>()
			};

			for (customProperty in customPropertyMapping.keys()) {
				buffer[customProperty] = new Array<Float>();
			}
			return buffer;
		}

		function mapElementAttributes(properties:Array<Dynamic>):Dynamic {
			var elementNames = properties.map(function(property:Dynamic) {
				return property.name;
			});
			function findAttrName(names:Array<String>):String {
				for (i in 0...names.length) {
					var name = names[i];
					if (elementNames.indexOf(name) != -1) return name;
				}
				return null;
			}
			return {
				attrX: findAttrName(['x', 'px', 'posx']) || 'x',
				attrY: findAttrName(['y', 'py', 'posy']) || 'y',
				attrZ: findAttrName(['z', 'pz', 'posz']) || 'z',
				attrNX: findAttrName(['nx', 'normalx']),
				attrNY: findAttrName(['ny', 'normaly']),
				attrNZ: findAttrName(['nz', 'normalz']),
				attrS: findAttrName(['s', 'u', 'texture_u', 'tx']),
				attrT: findAttrName(['t', 'v', 'texture_v', 'ty']),
				attrR: findAttrName(['red', 'diffuse_red', 'r', 'diffuse_r']),
				attrG: findAttrName(['green', 'diffuse_green', 'g', 'diffuse_g']),
				attrB: findAttrName(['blue', 'diffuse_blue', 'b', 'diffuse_b']),
			};
		}

		function parseASCII(data:String, header:Dynamic):BufferGeometry {
			var buffer = createBuffer();
			var patternBody = ~/end_header\s+(\S[\s\S]*\S|\S)\s*$/;
			var body:Array<String>;
			var matches = patternBody.exec(data);
			if (matches != null) {
				body = matches[1].split(/\s+/);
			} else {
				body = new Array<String>();
			}
			var tokens = new ArrayStream(body);
			for (i in 0...header.elements.length) {
				var elementDesc = header.elements[i];
				var attributeMap = mapElementAttributes(elementDesc.properties);
				for (j in 0...elementDesc.count) {
					var element = parseASCIIElement(elementDesc.properties, tokens);
					if (element == null) break;
					handleElement(buffer, elementDesc.name, element, attributeMap);
				}
			}
			return postProcess(buffer);
		}

		function postProcess(buffer:Dynamic):BufferGeometry {
			var geometry = new BufferGeometry();
			if (buffer.indices.length > 0) {
				geometry.setIndex(buffer.indices);
			}
			geometry.setAttribute('position', new Float32BufferAttribute(buffer.vertices, 3));
			if (buffer.normals.length > 0) {
				geometry.setAttribute('normal', new Float32BufferAttribute(buffer.normals, 3));
			}
			if (buffer.uvs.length > 0) {
				geometry.setAttribute('uv', new Float32BufferAttribute(buffer.uvs, 2));
			}
			if (buffer.colors.length > 0) {
				geometry.setAttribute('color', new Float32BufferAttribute(buffer.colors, 3));
			}
			if (buffer.faceVertexUvs.length > 0 || buffer.faceVertexColors.length > 0) {
				geometry = geometry.toNonIndexed();
				if (buffer.faceVertexUvs.length > 0) geometry.setAttribute('uv', new Float32BufferAttribute(buffer.faceVertexUvs, 2));
				if (buffer.faceVertexColors.length > 0) geometry.setAttribute('color', new Float32BufferAttribute(buffer.faceVertexColors, 3));
			}
			for (customProperty in customPropertyMapping.keys()) {
				if (buffer[customProperty].length > 0) {
					geometry.setAttribute(customProperty, new Float32BufferAttribute(buffer[customProperty], customPropertyMapping.get(customProperty).length));
				}
			}
			geometry.computeBoundingSphere();
			return geometry;
		}

		function handleElement(buffer:Dynamic, elementName:String, element:Dynamic, cacheEntry:Dynamic) {
			if (elementName == 'vertex') {
				buffer.vertices.push(element[cacheEntry.attrX], element[cacheEntry.attrY], element[cacheEntry.attrZ]);
				if (cacheEntry.attrNX != null && cacheEntry.attrNY != null && cacheEntry.attrNZ != null) {
					buffer.normals.push(element[cacheEntry.attrNX], element[cacheEntry.attrNY], element[cacheEntry.attrNZ]);
				}
				if (cacheEntry.attrS != null && cacheEntry.attrT != null) {
					buffer.uvs.push(element[cacheEntry.attrS], element[cacheEntry.attrT]);
				}
				if (cacheEntry.attrR != null && cacheEntry.attrG != null && cacheEntry.attrB != null) {
					var _color = new Color();
					_color.setRGB(element[cacheEntry.attrR] / 255.0, element[cacheEntry.attrG] / 255.0, element[cacheEntry.attrB] / 255.0).convertSRGBToLinear();
					buffer.colors.push(_color.r, _color.g, _color.b);
				}
				for (customProperty in customPropertyMapping.keys()) {
					for (elementProperty in customPropertyMapping.get(customProperty)) {
						buffer[customProperty].push(element[elementProperty]);
					}
				}
			} else if (elementName == 'face') {
				var vertex_indices = element.vertex_indices || element.vertex_index;
				var texcoord = element.texcoord;
				if (vertex_indices.length == 3) {
					buffer.indices.push(vertex_indices[0], vertex_indices[1], vertex_indices[2]);
					if (texcoord != null && texcoord.length == 6) {
						buffer.faceVertexUvs.push(texcoord[0], texcoord[1]);
						buffer.faceVertexUvs.push(texcoord[2], texcoord[3]);
						buffer.faceVertexUvs.push(texcoord[4], texcoord[5]);
					}
				} else if (vertex_indices.length == 4) {
					buffer.indices.push(vertex_indices[0], vertex_indices[1], vertex_indices[3]);
					buffer.indices.push(vertex_indices[1], vertex_indices[2], vertex_indices[3]);
				}
				if (cacheEntry.attrR != null && cacheEntry.attrG != null && cacheEntry.attrB != null) {
					var _color = new Color();
					_color.setRGB(element[cacheEntry.attrR] / 255.0, element[cacheEntry.attrG] / 255.0, element[cacheEntry.attrB] / 255.0).convertSRGBToLinear();
					buffer.faceVertexColors.push(_color.r, _color.g, _color.b);
					buffer.faceVertexColors.push(_color.r, _color.g, _color.b);
					buffer.faceVertexColors.push(_color.r, _color.g, _color.b);
				}
			}
		}

		function binaryReadElement(at:Int, properties:Array<Dynamic>):Array<Dynamic> {
			var element = {};
			var read = 0;
			for (i in 0...properties.length) {
				var property = properties[i];
				var valueReader = property.valueReader;
				if (property.type == 'list') {
					var list = new Array<Float>();
					var n = property.countReader.read(at + read);
					read += property.countReader.size;
					for (j in 0...n) {
						list.push(valueReader.read(at + read));
						read += valueReader.size;
					}
					element[property.name] = list;
				} else {
					element[property.name] = valueReader.read(at + read);
					read += valueReader.size;
				}
			}
			return [element, read];
		}

		function setPropertyBinaryReaders(properties:Array<Dynamic>, body:DataView, little_endian:Bool) {
			function getBinaryReader(dataview:DataView, type:String, little_endian:Bool):Dynamic {
				switch (type) {
					case 'int8':	case 'char':	return { read: function(at:Int):Int { return dataview.getInt8(at); }, size: 1 };
					case 'uint8':	case 'uchar':	return { read: function(at:Int):Int { return dataview.getUint8(at); }, size: 1 };
					case 'int16':	case 'short':	return { read: function(at:Int):Int { return dataview.getInt16(at, little_endian); }, size: 2 };
					case 'uint16':	case 'ushort':	return { read: function(at:Int):Int { return dataview.getUint16(at, little_endian); }, size: 2 };
					case 'int32':	case 'int':		return { read: function(at:Int):Int { return dataview.getInt32(at, little_endian); }, size: 4 };
					case 'uint32':	case 'uint':	return { read: function(at:Int):Int { return dataview.getUint32(at, little_endian); }, size: 4 };
					case 'float32': case 'float':	return { read: function(at:Int):Float { return dataview.getFloat32(at, little_endian); }, size: 4 };
					case 'float64': case 'double':	return { read: function(at:Int):Float { return dataview.getFloat64(at, little_endian); }, size: 8 };
				}
				return null;
			}
			for (i in 0...properties.length) {
				var property = properties[i];
				if (property.type == 'list') {
					property.countReader = getBinaryReader(body, property.countType, little_endian);
					property.valueReader = getBinaryReader(body, property.itemType, little_endian);
				} else {
					property.valueReader = getBinaryReader(body, property.type, little_endian);
				}
			}
		}

		function parseBinary(data:Bytes, header:Dynamic):BufferGeometry {
			var buffer = createBuffer();
			var little_endian = (header.format == 'binary_little_endian');
			var body = new DataView(data.buffer, header.headerLength);
			var result:Array<Dynamic>;
			var loc = 0;
			for (currentElement in 0...header.elements.length) {
				var elementDesc = header.elements[currentElement];
				var properties = elementDesc.properties;
				var attributeMap = mapElementAttributes(properties);
				setPropertyBinaryReaders(properties, body, little_endian);
				for (currentElementCount in 0...elementDesc.count) {
					result = binaryReadElement(loc, properties);
					loc += result[1];
					var element = result[0];
					handleElement(buffer, elementDesc.name, element, attributeMap);
				}
			}
			return postProcess(buffer);
		}

		function extractHeaderText(bytes:Bytes):Dynamic {
			var i = 0;
			var cont = true;
			var line = '';
			var lines = new Array<String>();
			var startLine = new TextDecoder().decode(bytes.subarray(0, 5));
			var hasCRNL = /^ply\r\n/.test(startLine);
			do {
				var c = String.fromCharCode(bytes.get(i++));
				if (c != '\n' && c != '\r') {
					line += c;
				} else {
					if (line == 'end_header') cont = false;
					if (line != '') {
						lines.push(line);
						line = '';
					}
				}
			} while (cont && i < bytes.length);
			if (hasCRNL == true) i++;
			return { headerText: lines.join('\r') + '\r', headerLength: i };
		}

		var geometry:BufferGeometry;
		var scope = this;
		if (data.length > 0) {
			var bytes = new Uint8Array(data.buffer);
			var _extractHeaderText = extractHeaderText(bytes);
			var headerText = _extractHeaderText.headerText;
			var headerLength = _extractHeaderText.headerLength;
			var header = parseHeader(Bytes.ofString(headerText), headerLength);
			if (header.format == 'ascii') {
				geometry = parseASCII(data.toString(Encoding.UTF8), header);
			} else {
				geometry = parseBinary(data, header);
			}
		} else {
			geometry = parseASCII(data.toString(Encoding.UTF8), parseHeader(data));
		}
		return geometry;
	}
}

class ArrayStream {

	public var arr:Array<String>;
	public var i:Int = 0;

	public function new(arr:Array<String>) {
		this.arr = arr;
	}

	public function empty():Bool {
		return i >= arr.length;
	}

	public function next():String {
		return arr[i++];
	}
}