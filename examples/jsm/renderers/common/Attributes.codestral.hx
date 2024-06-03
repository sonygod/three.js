import DataMap from './DataMap';
import { AttributeType } from './Constants';
import { DynamicDrawUsage } from 'three';

class Attributes extends DataMap {

    public var backend:Backend;

    public function new(backend:Backend) {
        super();
        this.backend = backend;
    }

    public function delete(attribute:Attribute):Void {
        var attributeData = super.delete(attribute);
        if (attributeData != null) {
            this.backend.destroyAttribute(attribute);
        }
    }

    public function update(attribute:Attribute, type:AttributeType):Void {
        var data = this.get(attribute);
        if (data.version == null) {
            switch (type) {
                case AttributeType.VERTEX:
                    this.backend.createAttribute(attribute);
                    break;
                case AttributeType.INDEX:
                    this.backend.createIndexAttribute(attribute);
                    break;
                case AttributeType.STORAGE:
                    this.backend.createStorageAttribute(attribute);
                    break;
            }
            data.version = this._getBufferAttribute(attribute).version;
        } else {
            var bufferAttribute = this._getBufferAttribute(attribute);
            if (data.version < bufferAttribute.version || bufferAttribute.usage == DynamicDrawUsage) {
                this.backend.updateAttribute(attribute);
                data.version = bufferAttribute.version;
            }
        }
    }

    private function _getBufferAttribute(attribute:Attribute):Attribute {
        if (attribute.isInterleavedBufferAttribute) {
            attribute = attribute.data;
        }
        return attribute;
    }
}