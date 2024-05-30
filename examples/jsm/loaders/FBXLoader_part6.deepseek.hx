class BinaryParser {

    public function parse(buffer:haxe.io.Bytes):FBXTree {

        var reader = new BinaryReader(buffer);
        reader.skip(23); // skip magic 23 bytes

        var version = reader.getUint32();

        if (version < 6400) {

            throw 'THREE.FBXLoader: FBX version not supported, FileVersion: ' + version;

        }

        var allNodes = new FBXTree();

        while (!this.endOfContent(reader)) {

            var node = this.parseNode(reader, version);
            if (node !== null) allNodes.add(node.name, node);

        }

        return allNodes;

    }

    // Check if reader has reached the end of content.
    public function endOfContent(reader:BinaryReader):Bool {

        // footer size: 160bytes + 16-byte alignment padding
        // - 16bytes: magic
        // - padding til 16-byte alignment (at least 1byte?)
        //	(seems like some exporters embed fixed 15 or 16bytes?)
        // - 4bytes: magic
        // - 4bytes: version
        // - 120bytes: zero
        // - 16bytes: magic
        if (reader.size() % 16 == 0) {

            return ((reader.getOffset() + 160 + 16) & ~0xf) >= reader.size();

        } else {

            return reader.getOffset() + 160 + 16 >= reader.size();

        }

    }

    // recursively parse nodes until the end of the file is reached
    public function parseNode(reader:BinaryReader, version:Int):Dynamic {

        var node = {};

        // The first three data sizes depends on version.
        var endOffset = (version >= 7500) ? reader.getUint64() : reader.getUint32();
        var numProperties = (version >= 7500) ? reader.getUint64() : reader.getUint32();

        (version >= 7500) ? reader.getUint64() : reader.getUint32(); // the returned propertyListLen is not used

        var nameLen = reader.getUint8();
        var name = reader.getString(nameLen);

        // Regards this node as NULL-record if endOffset is zero
        if (endOffset == 0) return null;

        var propertyList = [];

        for (i in 0...numProperties) {

            propertyList.push(this.parseProperty(reader));

        }

        // Regards the first three elements in propertyList as id, attrName, and attrType
        var id = propertyList.length > 0 ? propertyList[0] : '';
        var attrName = propertyList.length > 1 ? propertyList[1] : '';
        var attrType = propertyList.length > 2 ? propertyList[2] : '';

        // check if this node represents just a single property
        // like (name, 0) set or (name2, [0, 1, 2]) set of {name: 0, name2: [0, 1, 2]}
        node.singleProperty = (numProperties == 1 && reader.getOffset() == endOffset) ? true : false;

        while (endOffset > reader.getOffset()) {

            var subNode = this.parseNode(reader, version);

            if (subNode !== null) this.parseSubNode(name, node, subNode);

        }

        node.propertyList = propertyList; // raw property list used by parent

        if (Std.is(id, Int)) node.id = id;
        if (attrName != '') node.attrName = attrName;
        if (attrType != '') node.attrType = attrType;
        if (name != '') node.name = name;

        return node;

    }

    public function parseSubNode(name:String, node:Dynamic, subNode:Dynamic) {

        // special case: child node is single property
        if (subNode.singleProperty == true) {

            var value = subNode.propertyList[0];

            if (Std.is(value, Array)) {

                node[subNode.name] = subNode;

                subNode.a = value;

            } else {

                node[subNode.name] = value;

            }

        } else if (name == 'Connections' && subNode.name == 'C') {

            var array = [];

            for (property in subNode.propertyList) {

                // first Connection is FBX type (OO, OP, etc.). We'll discard these
                if (Std.int(property) != 0) array.push(property);

            }

            if (node.connections == null) {

                node.connections = [];

            }

            node.connections.push(array);

        } else if (subNode.name == 'Properties70') {

            var keys = Reflect.fields(subNode);

            for (key in keys) {

                node[key] = subNode[key];

            }

        } else if (name == 'Properties70' && subNode.name == 'P') {

            var innerPropName = subNode.propertyList[0];
            var innerPropType1 = subNode.propertyList[1];
            var innerPropType2 = subNode.propertyList[2];
            var innerPropFlag = subNode.propertyList[3];
            var innerPropValue;

            if (innerPropName.indexOf('Lcl ') == 0) innerPropName = innerPropName.replace('Lcl ', 'Lcl_');
            if (innerPropType1.indexOf('Lcl ') == 0) innerPropType1 = innerPropType1.replace('Lcl ', 'Lcl_');

            if (innerPropType1 == 'Color' || innerPropType1 == 'ColorRGB' || innerPropType1 == 'Vector' || innerPropType1 == 'Vector3D' || innerPropType1.indexOf('Lcl_') == 0) {

                innerPropValue = [
                    subNode.propertyList[4],
                    subNode.propertyList[5],
                    subNode.propertyList[6]
                ];

            } else {

                innerPropValue = subNode.propertyList[4];

            }

            // this will be copied to parent, see above
            node[innerPropName] = {

                'type': innerPropType1,
                'type2': innerPropType2,
                'flag': innerPropFlag,
                'value': innerPropValue

            };

        } else if (node[subNode.name] == null) {

            if (Std.is(subNode.id, Int)) {

                node[subNode.name] = {};
                node[subNode.name][subNode.id] = subNode;

            } else {

                node[subNode.name] = subNode;

            }

        } else {

            if (subNode.name == 'PoseNode') {

                if (!Std.is(node[subNode.name], Array)) {

                    node[subNode.name] = [node[subNode.name]];

                }

                node[subNode.name].push(subNode);

            } else if (node[subNode.name][subNode.id] == null) {

                node[subNode.name][subNode.id] = subNode;

            }

        }

    }

    public function parseProperty(reader:BinaryReader):Dynamic {

        var type = reader.getString(1);
        var length:Int;

        switch (type) {

            case 'C':
                return reader.getBoolean();

            case 'D':
                return reader.getFloat64();

            case 'F':
                return reader.getFloat32();

            case 'I':
                return reader.getInt32();

            case 'L':
                return reader.getInt64();

            case 'R':
                length = reader.getUint32();
                return reader.getArrayBuffer(length);

            case 'S':
                length = reader.getUint32();
                return reader.getString(length);

            case 'Y':
                return reader.getInt16();

            case 'b':
            case 'c':
            case 'd':
            case 'f':
            case 'i':
            case 'l':

                var arrayLength = reader.getUint32();
                var encoding = reader.getUint32(); // 0: non-compressed, 1: compressed
                var compressedLength = reader.getUint32();

                if (encoding == 0) {

                    switch (type) {

                        case 'b':
                        case 'c':
                            return reader.getBooleanArray(arrayLength);

                        case 'd':
                            return reader.getFloat64Array(arrayLength);

                        case 'f':
                            return reader.getFloat32Array(arrayLength);

                        case 'i':
                            return reader.getInt32Array(arrayLength);

                        case 'l':
                            return reader.getInt64Array(arrayLength);

                    }

                }

                var data = fflate.unzlibSync(new Uint8Array(reader.getArrayBuffer(compressedLength)));
                var reader2 = new BinaryReader(data.buffer);

                switch (type) {

                    case 'b':
                    case 'c':
                        return reader2.getBooleanArray(arrayLength);

                    case 'd':
                        return reader2.getFloat64Array(arrayLength);

                    case 'f':
                        return reader2.getFloat32Array(arrayLength);

                    case 'i':
                        return reader2.getInt32Array(arrayLength);

                    case 'l':
                        return reader2.getInt64Array(arrayLength);

                }

                break; // cannot happen but is required by the DeepScan

            default:
                throw 'THREE.FBXLoader: Unknown property type ' + type;

        }

    }

}