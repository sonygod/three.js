import haxe.io.Bytes;
import haxe.Unserializer;

class BinaryParser {
    public function parse(buffer: Bytes): FBXTree {
        var reader = new BinaryReader(buffer);
        reader.skip(23); // skip magic 23 bytes

        var version = reader.getUint32();

        if (version < 6400) {
            throw "THREE.FBXLoader: FBX version not supported, FileVersion: " + version;
        }

        var allNodes = new FBXTree();

        while (!endOfContent(reader)) {
            var node = parseNode(reader, version);
            if (node != null) allNodes.add(node.name, node);
        }

        return allNodes;
    }

    private function endOfContent(reader: BinaryReader): Bool {
        if (reader.size() % 16 == 0) {
            return ((reader.getOffset() + 160 + 16) & ~0xf) >= reader.size();
        } else {
            return reader.getOffset() + 160 + 16 >= reader.size();
        }
    }

    private function parseNode(reader: BinaryReader, version: Int): Dynamic {
        var node = { };

        var endOffset = version >= 7500 ? reader.getUint64() : reader.getUint32();
        var numProperties = version >= 7500 ? reader.getUint64() : reader.getUint32();

        version >= 7500 ? reader.getUint64() : reader.getUint32(); // the returned propertyListLen is not used

        var nameLen = reader.getUint8();
        var name = reader.getString(nameLen);

        if (endOffset == 0) return null;

        var propertyList = [];

        for (var i = 0; i < numProperties; i++) {
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

        node.propertyList = propertyList;

        if (Std.isInt(id)) node.id = id;
        if (attrName != '') node.attrName = attrName;
        if (attrType != '') node.attrType = attrType;
        if (name != '') node.name = name;

        return node;
    }

    private function parseSubNode(name: String, node: Dynamic, subNode: Dynamic): Void {
        // Implementation depends on the structure of the FBXTree and other classes used in the original JavaScript code
    }

    private function parseProperty(reader: BinaryReader): Dynamic {
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
            case 'b':
            case 'c':
            case 'd':
            case 'f':
            case 'i':
            case 'l':
                // Haxe doesn't support compressed data directly, so this part needs to be implemented differently
                break;
            default:
                throw "THREE.FBXLoader: Unknown property type " + type;
        }
    }
}

class BinaryReader {
    private var unserializer: Unserializer;

    public function new(buffer: Bytes) {
        this.unserializer = new Unserializer(buffer);
    }

    public function getOffset(): Int {
        return this.unserializer.position;
    }

    public function size(): Int {
        return this.unserializer.length;
    }

    public function skip(bytes: Int): Void {
        this.unserializer.skip(bytes);
    }

    public function getUint8(): Int {
        return this.unserializer.readByte();
    }

    public function getUint16(): Int {
        return this.unserializer.readUInt16();
    }

    public function getUint32(): Int {
        return this.unserializer.readUInt32();
    }

    public function getUint64(): Int {
        var low = this.unserializer.readUInt32();
        var high = this.unserializer.readUInt32();
        return (high << 32) | low;
    }

    public function getInt16(): Int {
        return this.unserializer.readShort();
    }

    public function getInt32(): Int {
        return this.unserializer.readInt32();
    }

    public function getInt64(): Int {
        var low = this.unserializer.readUInt32();
        var high = this.unserializer.readUInt32();
        return (high << 32) | low;
    }

    public function getFloat32(): Float {
        return this.unserializer.readFloat();
    }

    public function getFloat64(): Float {
        return this.unserializer.readDouble();
    }

    public function getBoolean(): Bool {
        return this.unserializer.readBool();
    }

    public function getString(length: Int): String {
        return this.unserializer.readUTFBytes(length);
    }

    public function getArrayBuffer(length: Int): Bytes {
        return this.unserializer.readBytes(length);
    }
}