import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.zip.Uncompress;

class BinaryParser {

    public function new() {}

    public function parse(buffer: Bytes): FBXTree {
        var reader = new BinaryReader(buffer);
        reader.skip(23); // skip magic 23 bytes

        var version = reader.getUint32();

        if (version < 6400) {
            throw "THREE.FBXLoader: FBX version not supported, FileVersion: " + version;
        }

        var allNodes = new FBXTree();

        while (!this.endOfContent(reader)) {
            var node = this.parseNode(reader, version);
            if (node != null) {
                allNodes.add(node.name, node);
            }
        }

        return allNodes;
    }

    // Check if reader has reached the end of content.
    function endOfContent(reader: BinaryReader): Bool {
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
    function parseNode(reader: BinaryReader, version: Int): Null<FBXNode> {
        var node: FBXNode = {
            id: null,
            attrName: null,
            attrType: null,
            name: null,
            singleProperty: false,
            propertyList: []
        };

        // The first three data sizes depends on version.
        var endOffset = (version >= 7500) ? reader.getUint64() : reader.getUint32();
        var numProperties = (version >= 7500) ? reader.getUint64() : reader.getUint32();

        (version >= 7500) ? reader.getUint64() : reader.getUint32(); // the returned propertyListLen is not used

        var nameLen = reader.getUint8();
        var name = reader.getString(nameLen);

        // Regards this node as NULL-record if endOffset is zero
        if (endOffset == 0) {
            return null;
        }

        var propertyList = [];

        for (i in 0...numProperties) {
            propertyList.push(this.parseProperty(reader));
        }

        // Regards the first three elements in propertyList as id, attrName, and attrType
        var id = propertyList.length > 0 ? propertyList[0] : null;
        var attrName = propertyList.length > 1 ? propertyList[1] : null;
        var attrType = propertyList.length > 2 ? propertyList[2] : null;

        // check if this node represents just a single property
        // like (name, 0) set or (name2, [0, 1, 2]) set of {name: 0, name2: [0, 1, 2]}
        node.singleProperty = (numProperties == 1 && reader.getOffset() == endOffset);

        while (endOffset > reader.getOffset()) {
            var subNode = this.parseNode(reader, version);
            if (subNode != null) {
                this.parseSubNode(name, node, subNode);
            }
        }

        node.propertyList = propertyList; // raw property list used by parent

        if (id != null) {
            node.id = id;
        }
        if (attrName != null) {
            node.attrName = attrName;
        }
        if (attrType != null) {
            node.attrType = attrType;
        }
        node.name = name;

        return node;
    }

    function parseSubNode(name: String, node: FBXNode, subNode: FBXNode): Void {
        // special case: child node is single property
        if (subNode.singleProperty) {
            var value = subNode.propertyList[0];

            if (Std.isOfType(value, Array)) {
                Reflect.setField(node, subNode.name, subNode);
                Reflect.setField(subNode, "a", value);
            } else {
                Reflect.setField(node, subNode.name, value);
            }
        } else if (name == "Connections" && subNode.name == "C") {
            var array = [];

            for (i in 1...subNode.propertyList.length) {
                array.push(subNode.propertyList[i]);
            }

            if (node.connections == null) {
                node.connections = [];
            }

            node.connections.push(array);
        } else if (subNode.name == "Properties70") {
            for (key in Reflect.fields(subNode)) {
                Reflect.setField(node, key, Reflect.field(subNode, key));
            }
        } else if (name == "Properties70" && subNode.name == "P") {
            var innerPropName = subNode.propertyList[0];
            var innerPropType1 = subNode.propertyList[1];
            var innerPropType2 = subNode.propertyList[2];
            var innerPropFlag = subNode.propertyList[3];
            var innerPropValue = null;

            if (StringTools.startsWith(innerPropName, "Lcl ")) {
                innerPropName = StringTools.replace(innerPropName, "Lcl ", "Lcl_");
            }
            if (StringTools.startsWith(innerPropType1, "Lcl ")) {
                innerPropType1 = StringTools.replace(innerPropType1, "Lcl ", "Lcl_");
            }

            if (innerPropType1 == "Color" || innerPropType1 == "ColorRGB" || innerPropType1 == "Vector"
                || innerPropType1 == "Vector3D" || StringTools.startsWith(innerPropType1, "Lcl_")) {
                innerPropValue = [
                    subNode.propertyList[4],
                    subNode.propertyList[5],
                    subNode.propertyList[6]
                ];
            } else {
                innerPropValue = subNode.propertyList[4];
            }

            // this will be copied to parent, see above
            Reflect.setField(node, innerPropName, {
                "type": innerPropType1,
                "type2": innerPropType2,
                "flag": innerPropFlag,
                "value": innerPropValue
            });
        } else if (Reflect.hasField(node, subNode.name) == false) {
            if (subNode.id != null) {
                Reflect.setField(node, subNode.name, {});
                Reflect.setField(Reflect.field(node, subNode.name), Std.string(subNode.id), subNode);
            } else {
                Reflect.setField(node, subNode.name, subNode);
            }
        } else {
            if (subNode.name == "PoseNode") {
                var nodeField = Reflect.field(node, subNode.name);
                if (Std.isOfType(nodeField, Array) == false) {
                    Reflect.setField(node, subNode.name, [nodeField]);
                }
                (cast(nodeField, Array<Dynamic>)).push(subNode);
            } else if (Reflect.hasField(Reflect.field(node, subNode.name), Std.string(subNode.id)) == false) {
                Reflect.setField(Reflect.field(node, subNode.name), Std.string(subNode.id), subNode);
            }
        }
    }

    function parseProperty(reader: BinaryReader): Dynamic {
        var type = reader.getString(1);
        var length: Int;

        switch (type) {
            case "C":
                return reader.getBoolean();
            case "D":
                return reader.getFloat64();
            case "F":
                return reader.getFloat32();
            case "I":
                return reader.getInt32();
            case "L":
                return reader.getInt64();
            case "R":
                length = reader.getUint32();
                return reader.getArrayBuffer(length);
            case "S":
                length = reader.getUint32();
                return reader.getString(length);
            case "Y":
                return reader.getInt16();
            case "b", "c", "d", "f", "i", "l":
                var arrayLength = reader.getUint32();
                var encoding = reader.getUint32(); // 0: non-compressed, 1: compressed
                var compressedLength = reader.getUint32();

                if (encoding == 0) {
                    switch (type) {
                        case "b", "c":
                            return reader.getBooleanArray(arrayLength);
                        case "d":
                            return reader.getFloat64Array(arrayLength);
                        case "f":
                            return reader.getFloat32Array(arrayLength);
                        case "i":
                            return reader.getInt32Array(arrayLength);
                        case "l":
                            return reader.getInt64Array(arrayLength);
                        default:
                    }
                }

                var data = Uncompress.run(reader.getArrayBuffer(compressedLength));
                var reader2 = new BinaryReader(data);

                switch (type) {
                    case "b", "c":
                        return reader2.getBooleanArray(arrayLength);
                    case "d":
                        return reader2.getFloat64Array(arrayLength);
                    case "f":
                        return reader2.getFloat32Array(arrayLength);
                    case "i":
                        return reader2.getInt32Array(arrayLength);
                    case "l":
                        return reader2.getInt64Array(arrayLength);
                    default:
                }

                break; // cannot happen but is required by the DeepScan

            default:
                throw "THREE.FBXLoader: Unknown property type " + type;
        }
        return null;
    }
}

// You'll need to define these classes as well
// They are not included in the original code snippet
// and their structure depends on how you want to use the parsed data

typedef FBXNode = {
    var id: Null<Int>;
    var attrName: Null<String>;
    var attrType: Null<String>;
    var name: String;
    var singleProperty: Bool;
    var propertyList: Array<Dynamic>;
    var connections: Null<Array<Array<Dynamic>>>;
}

class FBXTree {
    public function new() {}

    public function add(name: String, node: FBXNode): Void {
        Reflect.setField(this, name, node);
    }
}

class BinaryReader {
    var buffer: Bytes;
    var pos: Int;

    public function new(buffer: Bytes) {
        this.buffer = buffer;
        this.pos = 0;
    }

    public function size(): Int {
        return this.buffer.length;
    }

    public function getOffset(): Int {
        return this.pos;
    }

    public function skip(amount: Int): Void {
        this.pos += amount;
    }

    public function getUint8(): Int {
        return this.buffer.get(this.pos++);
    }

    public function getInt16(): Int {
        var value = this.buffer.getInt16(this.pos);
        this.pos += 2;
        return value;
    }

    public function getUint32(): Int {
        var value = this.buffer.getUInt32(this.pos);
        this.pos += 4;
        return value;
    }

    public function getInt32(): Int {
        var value = this.buffer.getInt32(this.pos);
        this.pos += 4;
        return value;
    }

    public function getFloat32(): Float {
        var value = this.buffer.getFloat(this.pos);
        this.pos += 4;
        return value;
    }

    public function getFloat64(): Float {
        var value = this.buffer.getDouble(this.pos);
        this.pos += 8;
        return value;
    }

    public function getInt64(): Int {
        // Assuming Int64 is represented as two Int32s in Haxe
        var low = this.buffer.getInt32(this.pos);
        this.pos += 4;
        var high = this.buffer.getInt32(this.pos);
        this.pos += 4;
        return (high << 32) | low;
    }

    public function getUint64(): Int {
        // Assuming Uint64 is represented as two Int32s in Haxe
        var low = this.buffer.getUInt32(this.pos);
        this.pos += 4;
        var high = this.buffer.getUInt32(this.pos);
        this.pos += 4;
        return (high << 32) | low;
    }

    public function getString(length: Int): String {
        var str = this.buffer.getString(this.pos, this.pos + length);
        this.pos += length;
        return str;
    }

    public function getBoolean(): Bool {
        return this.getUint8() != 0;
    }

    public function getArrayBuffer(length: Int): Bytes {
        var data = this.buffer.sub(this.pos, length);
        this.pos += length;
        return data;
    }

    public function getBooleanArray(length: Int): Array<Bool> {
        var array = [];
        for (i in 0...length) {
            array.push(this.getBoolean());
        }
        return array;
    }

    public function getFloat32Array(length: Int): Array<Float> {
        var array = [];
        for (i in 0...length) {
            array.push(this.getFloat32());
        }
        return array;
    }

    public function getFloat64Array(length: Int): Array<Float> {
        var array = [];
        for (i in 0...length) {
            array.push(this.getFloat64());
        }
        return array;
    }

    public function getInt32Array(length: Int): Array<Int> {
        var array = [];
        for (i in 0...length) {
            array.push(this.getInt32());
        }
        return array;
    }

    public function getInt64Array(length: Int): Array<Int> {
        var array = [];
        for (i in 0...length) {
            array.push(this.getInt64());
        }
        return array;
    }
}