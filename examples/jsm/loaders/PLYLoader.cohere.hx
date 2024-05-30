import haxe.io.Bytes;
import js.Browser.window;
import js.html.DataView;
import js.html.Float32Array;
import js.html.Int8Array;
import js.html.Int16Array;
import js.html.Int32Array;
import js.html.Uint8Array;
import js.html.Uint16Array;
import js.html.Uint32Array;

class PLYLoader {
    public function new(manager:Dynamic) {
        this.propertyNameMapping = { };
        this.customPropertyMapping = { };
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Void {
        var scope = this;
        var loader = new FileLoader(manager);
        loader.path = this.path;
        loader.setResponseType('arraybuffer');
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch (e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function setPropertyNameMapping(mapping:Map<String, String>):Void {
        this.propertyNameMapping = mapping;
    }

    public function setCustomPropertyNameMapping(mapping:Map<String, Array<String>>):Void {
        this.customPropertyMapping = mapping;
    }

    public function parse(data:Bytes):BufferGeometry {
        function parseHeader(data:Bytes, headerLength:Int = 0):Map<String, Dynamic> {
            var patternHeader = ~/^ply([\s\S]*?)end_header(\r\n|\r|\n)/;
            var headerText = patternHeader.exec(data.getString(data.length, 'utf-8'))[1];
            var header = {
                comments: [],
                elements: [],
                headerLength: headerLength,
                objInfo: ''
            };
            var lines = headerText.split('\n');
            var currentElement:Map<String, Dynamic>;

            function make_ply_element_property(propertValues:Array<String>, propertyNameMapping:Map<String, String>):Map<String, String> {
                var property = { type: propertValues[0] };
                if (property.type == 'list') {
                    property.name = propertValues[3];
                    property.countType = propertValues[1];
                    property.itemType = propertValues[2];
                } else {
                    property.name = propertValues[1];
                }
                if (property.name in propertyNameMapping) {
                    property.name = propertyNameMapping[property.name];
                }
                return property;
            }

            for (i in 0...lines.length) {
                var line = lines[i].trim();
                if (line == '') continue;
                var lineValues = line.split(' ');
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
                        currentElement = { };
                        currentElement.name = lineValues[0];
                        currentElement.count = Std.parseInt(lineValues[1]);
                        currentElement.properties = [];
                        break;
                    case 'property':
                        currentElement.properties.push(make_ply_element_property(lineValues, scope.propertyNameMapping));
                        break;
                    case 'obj_info':
                        header.objInfo = line;
                        break;
                    default:
                        trace('unhandled ${lineType} ${lineValues}');
                }
            }
            if (currentElement != null) {
                header.elements.push(currentElement);
            }
            return header;
        }

        function parseASCIINumber(n:String, type:String):Dynamic {
            switch (type) {
                case 'char': case 'uchar': case 'short': case 'ushort': case 'int': case 'uint':
                case 'int8': case 'uint8': case 'int16': case 'uint16': case 'int32': case 'uint32':
                    return Std.parseInt(n);
                case 'float': case 'double': case 'float32': case 'float64':
                    return Std.parseFloat(n);
            }
        }

        function parseASCIIElement(properties:Array<Map<String, String>>, tokens:Array<String>):Map<String, Dynamic> {
            var element = { };
            for (i in 0...properties.length) {
                if (tokens.length == 0) return null;
                var property = properties[i];
                if (property.type == 'list') {
                    var list = [];
                    var n = parseASCIINumber(tokens.shift(), property.countType);
                    for (j in 0...n) {
                        if (tokens.length == 0) return null;
                        list.push(parseASCIINumber(tokens.shift(), property.itemType));
                    }
                    element[property.name] = list;
                } else {
                    element[property.name] = parseASCIINumber(tokens.shift(), property.type);
                }
            }
            return element;
        }

        function createBuffer():Map<String, Array<Float>> {
            var buffer = {
                indices: [],
                vertices: [],
                normals: [],
                uvs: [],
                faceVertexUvs: [],
                colors: [],
                faceVertexColors: []
            };
            for (customProperty in scope.customPropertyMapping) {
                buffer[customProperty] = [];
            }
            return buffer;
        }

        function mapElementAttributes(properties:Array<Map<String, String>>):Map<String, String> {
            var elementNames = properties.map(property -> property.name);
            function findAttrName(names:Array<String>):Null<String> {
                for (name in names) {
                    if (elementNames.includes(name)) return name;
                }
                return null;
            }
            return {
                attrX: findAttrName(['x', 'px', 'posx']) or 'x',
                attrY: findAttrName(['y', 'py', 'posy']) or 'y',
                attrZ: findAttrName(['z', 'pz', 'posz']) or 'z',
                attrNX: findAttrName(['nx', 'normalx']),
                attrNY: findAttrName(['ny', 'normaly']),
                attrNZ: findAttrName(['nz', 'normalz']),
                attrS: findAttrName(['s', 'u', 'texture_u', 'tx']),
                attrT: findAttrName(['t', 'v', 'texture_v', 'ty']),
                attrR: findAttrName(['red', 'diffuse_red', 'r', 'diffuse_r']),
                attrG: findAttrName(['green', 'diffuse_green', 'g', 'diffuse_g']),
                attrB: findAttrName(['blue', 'diffuse_blue', 'b', 'diffuse_b'])
            };
        }

        function parseASCII(data:String, header:Map<String, Dynamic>):BufferGeometry {
            var buffer = createBuffer();
            var patternBody = ~/end_header\s+([\S\s]*?)\s*$/;
            var body = patternBody.exec(data)[1].split(' ');
            var tokens = new ArrayStream(body);
            var i = 0;
            while (i < header.elements.length) {
                var elementDesc = header.elements[i];
                var attributeMap = mapElementAttributes(elementDesc.properties);
                var j = 0;
                while (j < elementDesc.count) {
                    var element = parseASCIIElement(elementDesc.properties, tokens);
                    if (element == null) break;
                    handleElement(buffer, elementDesc.name, element, attributeMap);
                    j++;
                }
                i++;
            }
            return postProcess(buffer);
        }

        function postProcess(buffer:Map<String, Array<Float>>):BufferGeometry {
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
            for (customProperty in scope.customPropertyMapping) {
                if (buffer[customProperty].length > 0) {
                    geometry.setAttribute(customProperty, new Float32BufferAttribute(buffer[customProperty], scope.customPropertyMapping[customProperty].length));
                }
            }
            geometry.computeBoundingSphere();
            return geometry;
        }

        function handleElement(buffer:Map<String, Array<Float>>, elementName:String, element:Map<String, Dynamic>, cacheEntry:Map<String, String>):Void {
            if (elementName == 'vertex') {
                buffer.vertices.push(element[cacheEntry.attrX], element[cacheEntry.attrY], element[cacheEntry.attrZ]);
                if (cacheEntry.attrNX != null && cacheEntry.attrNY != null && cacheEntry.attrNZ != null) {
                    buffer.normals.push(element[cacheEntry.attrNX], element[cacheEntry.attrNY], element[cacheEntry.attrNZ]);
                }
                if (cacheEntry.attrS != null && cacheEntry.attrT != null) {
                    buffer.uvs.push(element[cacheEntry.attrS], element[cacheEntry.attrT]);
                }
                if (cacheEntry.attrR != null && cacheEntry.attrG != null && cacheEntry.attrB != null) {
                    var color = new Color();
                    color.setRGB(element[cacheEntry.attrR] / 255.0, element[cacheEntry.attrG] / 255.0, element[cacheEntry.attrB] / 255.0);
                    color.convertSRGBToLinear();
                    buffer.colors.push(color.r, color.g, color.b);
                }
                for (customProperty in scope.customPropertyMapping) {
                    for (elementProperty in scope.customPropertyMapping[customProperty]) {
                        buffer[customProperty].push(element[elementProperty]);
                    }
                }
            } else if (elementName == 'face') {
                var vertex_indices = element.vertex_indices or element.vertex_index;
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
                    var color = new Color();
                    color.setRGB(element[cacheEntry.attrR] / 255.0, element[cacheEntry.attrG] / 255.0, element[cacheEntry.attrB] / 255.0);
                    color.convertSRGBToLinear();
                    buffer.faceVertexColors.push(color.r, color.g, color.b);
                    buffer.faceVertexColors.push(color.r, color.g, color.b);
                    buffer.faceVertexColors.push(color.r, color.g, color.b);
                }
            }
        }

        function binaryReadElement(at:Int, properties:Array<Map<String, String>>):Array<Dynamic> {
            var element = { };
            var read = 0;
            for (i in 0...properties.length) {
                var property = properties[i];
                var valueReader = property.valueReader;
                if (property.type == 'list') {
                    var list = [];
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

        function setPropertyBinaryReaders(properties:Array<Map<String, String>>, body:DataView, little_endian:Bool):Void {
            function getBinaryReader(dataview:DataView, type:String, little_endian:Bool):Map<String, Dynamic> {
                switch (type) {
                    case 'int8': case 'char':
                        return { read: function(at:Int) {
                            return dataview.getInt8(at);
                        }, size: 1 };
                    case 'uint8': case 'uchar':
                        return { read: function(at:Int) {
                            return dataview.getUint8(at);
                        }, size: 1 };
                    case 'int16': case 'short':
                        return { read: function(at:Int) {
                            return dataview.getInt16(at, little_endian);
                        }, size: 2 };
                    case 'uint16': case 'ushort':
                        return { read: function(at:Int) {
                            return dataview.getUint16(at, little_endian);
                        }, size: 2 };
                    case 'int32': case 'int':
                        return { read: function(at:Int) {
                            return dataview.getInt32(at, little_endian);
                        }, size: 4 };
                    case 'uint32': case 'uint':
                        return { read: function(at:Int) {
                            return dataview.getUint32(at, little_endian);
                        }, size: 4 };
                    case 'float32': case 'float':
                        return { read: function(at:Int) {
                            return dataview.getFloat32(at, little_endian);
                        }, size: 4 };
                    case 'float64': case 'double':
                        return { read: function(at:Int) {
                            return dataview.getFloat64(at, little_endian);
                        }, size: 8 };
                }
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

        function parseBinary(data:Bytes, header:Map<String, Dynamic>):BufferGeometry {
            var buffer = createBuffer();
            var little_endian = (header.format == 'binary_little_endian');
            var body = new DataView(data, header.headerLength);
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

        function extractHeaderText(bytes:Bytes):Map<String, Dynamic> {
            var i = 0;
            var cont = true;
            var line = '';
            var lines = [];
            var startLine = bytes.getString(5, 'utf-8');
            var hasCRNL = startLine.startsWith('ply\r\n');
            while (cont && i < bytes.length) {
                var c = bytes.getString(i++, 1, 'utf-8');
                if (c != '\n' && c != '\r') {
                    line += c;
                } else {
                    if (line == 'end_header
                    if (line != '') {
                        lines.push(line);
                        line = '';
                    }
                }
            }
            if (hasCRNL) i++;
            return { headerText: lines.join('\r\n') + '\r\n', headerLength: i };
        }

        var geometry:BufferGeometry;
        var scope = this;
        if (data instanceof Bytes) {
            var bytes = data.getData();
            var { headerText, headerLength } = extractHeaderText(bytes);
            var header = parseHeader(headerText, headerLength);
            if (header.format == 'ascii') {
                var text = bytes.getString(bytes.length, 'utf-8');
                geometry = parseASCII(text, header);
            } else {
                geometry = parseBinary(data, header);
            }
        } else {
            geometry = parseASCII(data, parseHeader(data));
        }
        return geometry;
    }
}

class ArrayStream {
    public var arr:Array<String>;
    public var i:Int;

    public function new(arr:Array<String>) {
        this.arr = arr;
        this.i = 0;
    }

    public function empty():Bool {
        return this.i >= this.arr.length;
    }

    public function next():String {
        return this.arr[this.i++];
    }
}