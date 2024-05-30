package three.js.loaders;

import haxe.io.BytesInput;
import haxe.io.Float64Array;
import haxe.io.Int32Array;
import haxe.io.UInt32Array;
import haxe.io.UInt64Array;
import haxe.io.Bytes;

class BinaryParser {
    
    public function new() {}

    public function parse(buffer:Bytes) {
        var reader = new BinaryReader(buffer);
        reader.skip(23); // skip magic 23 bytes

        var version = reader.getUint32();

        if (version < 6400) {
            throw new Error('THREE.FBXLoader: FBX version not supported, FileVersion: ' + version);
        }

        var allNodes = new FBXTree();

        while (!endOfContent(reader)) {
            var node = parseNode(reader, version);
            if (node != null) allNodes.add(node.name, node);
        }

        return allNodes;
    }

    private function endOfContent(reader:BinaryReader) {
        if (reader.size() % 16 == 0) {
            return (reader.getOffset() + 160 + 16) & ~0xf >= reader.size();
        } else {
            return reader.getOffset() + 160 + 16 >= reader.size();
        }
    }

    private function parseNode(reader:BinaryReader, version:Int) {
        var node = {};

        var endOffset = (version >= 7500) ? reader.getUint64() : reader.getUint32();
        var numProperties = (version >= 7500) ? reader.getUint64() : reader.getUint32();

        (version >= 7500) ? reader.getUint64() : reader.getUint32(); // the returned propertyListLen is not used

        var nameLen = reader.getUint8();
        var name = reader.getString(nameLen);

        if (endOffset == 0) return null;

        var propertyList = [];

        for (i in 0...numProperties) {
            propertyList.push(parseProperty(reader));
        }

        var id = propertyList.length > 0 ? propertyList[0] : '';
        var attrName = propertyList.length > 1 ? propertyList[1] : '';
        var attrType = propertyList.length > 2 ? propertyList[2] : '';

        node.singleProperty = (numProperties == 1 && reader.getOffset() == endOffset) ? true : false;

        while (endOffset > reader.getOffset()) {
            var subNode = parseNode(reader, version);
            if (subNode != null) parseSubNode(name, node, subNode);
        }

        node.propertyList = propertyList; // raw property list used by parent

        if (Std.isOfType(id, Int)) node.id = id;
        if (attrName != '') node.attrName = attrName;
        if (attrType != '') node.attrType = attrType;
        if (name != '') node.name = name;

        return node;
    }

    private function parseSubNode(name:String, node:Dynamic, subNode:Dynamic) {
        if (subNode.singleProperty) {
            var value = subNode.propertyList[0];
            if (Std.isOfType(value, Array)) {
                node[subNode.name] = subNode;
                subNode.a = value;
            } else {
                node[subNode.name] = value;
            }
        } else if (name == 'Connections' && subNode.name == 'C') {
            var array = [];
            for (property in subNode.propertyList) {
                if (property != null) array.push(property);
            }
            if (node.connections == null) node.connections = [];
            node.connections.push(array);
        } else if (subNode.name == 'Properties70') {
            for (key in Reflect.fields(subNode)) {
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

            node[innerPropName] = {
                type: innerPropType1,
                type2: innerPropType2,
                flag: innerPropFlag,
                value: innerPropValue
            };
        } else if (node[subNode.name] == null) {
            if (Std.isOfType(subNode.id, Int)) {
                node[subNode.name] = {};
                node[subNode.name][subNode.id] = subNode;
            } else {
                node[subNode.name] = subNode;
            }
        } else {
            if (subNode.name == 'PoseNode') {
                if (!Std.isOfType(node[subNode.name], Array)) node[subNode.name] = [node[subNode.name]];
                node[subNode.name].push(subNode);
            } else if (node[subNode.name][subNode.id] == null) {
                node[subNode.name][subNode.id] = subNode;
            }
        }
    }

    private function parseProperty(reader:BinaryReader) {
        var type = reader.getString(1);
        var length;

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
            case 'b', 'c', 'd', 'f', 'i', 'l':
                var arrayLength = reader.getUint32();
                var encoding = reader.getUint32(); // 0: non-compressed, 1: compressed
                var compressedLength = reader.getUint32();

                if (encoding == 0) {
                    switch (type) {
                        case 'b', 'c':
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

                var data = fflate.unzlibSync(new BytesInput(reader.getArrayBuffer(compressedLength)));
                var reader2 = new BinaryReader(data);

                switch (type) {
                    case 'b', 'c':
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

            default:
                throw new Error('THREE.FBXLoader: Unknown property type ' + type);
        }
    }
}