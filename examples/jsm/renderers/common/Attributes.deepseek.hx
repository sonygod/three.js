import DataMap from './DataMap.hx';
import Constants.AttributeType;
import three.DynamicDrawUsage;

class Attributes extends DataMap {

	public function new(backend:Dynamic) {

		super();

		this.backend = backend;

	}

	public function delete(attribute:Dynamic):Void {

		var attributeData = super.delete(attribute);

		if (attributeData !== null) {

			this.backend.destroyAttribute(attribute);

		}

	}

	public function update(attribute:Dynamic, type:AttributeType):Void {

		var data = this.get(attribute);

		if (data.version == null) {

			if (type == AttributeType.VERTEX) {

				this.backend.createAttribute(attribute);

			} else if (type == AttributeType.INDEX) {

				this.backend.createIndexAttribute(attribute);

			} else if (type == AttributeType.STORAGE) {

				this.backend.createStorageAttribute(attribute);

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

	private function _getBufferAttribute(attribute:Dynamic):Dynamic {

		if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;

		return attribute;

	}

}

typedef Attributes = Attributes;