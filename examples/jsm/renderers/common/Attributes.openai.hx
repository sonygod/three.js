package three.js.examples.jms.renderers.common;

import DataMap;
import Constants.AttributeType;
import three.DynamicDrawUsage;

class Attributes extends DataMap {
    public var backend:Dynamic;

    public function new(backend:Dynamic) {
        super();
        this.backend = backend;
    }

    override public function delete(attribute:Dynamic) {
        var attributeData = super.delete(attribute);
        if (attributeData != null) {
            backend.destroyAttribute(attribute);
        }
    }

    public function update(attribute:Dynamic, type:Int) {
        var data = get(attribute);
        if (data.version == null) {
            switch (type) {
                case AttributeType.VERTEX:
                    backend.createAttribute(attribute);
                case AttributeType.INDEX:
                    backend.createIndexAttribute(attribute);
                case AttributeType.STORAGE:
                    backend.createStorageAttribute(attribute);
            }
            data.version = _getBufferAttribute(attribute).version;
        } else {
            var bufferAttribute = _getBufferAttribute(attribute);
            if (data.version < bufferAttribute.version || bufferAttribute.usage == DynamicDrawUsage) {
                backend.updateAttribute(attribute);
                data.version = bufferAttribute.version;
            }
        }
    }

    private function _getBufferAttribute(attribute:Dynamic) {
        if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;
        return attribute;
    }
}