import DataMap from "./DataMap";
import Constants from "./Constants";
import three.DynamicDrawUsage;

class Attributes extends DataMap {

	public backend:Dynamic;

	public function new(backend:Dynamic) {
		super();
		this.backend = backend;
	}

	public function delete(attribute:Dynamic):Dynamic {
		var attributeData = super.delete(attribute);
		if (attributeData != null) {
			this.backend.destroyAttribute(attribute);
		}
		return attributeData;
	}

	public function update(attribute:Dynamic, type:Int) {
		var data = this.get(attribute);
		if (data.version == null) {
			if (type == Constants.AttributeType.VERTEX) {
				this.backend.createAttribute(attribute);
			} else if (type == Constants.AttributeType.INDEX) {
				this.backend.createIndexAttribute(attribute);
			} else if (type == Constants.AttributeType.STORAGE) {
				this.backend.createStorageAttribute(attribute);
			}
			data.version = this._getBufferAttribute(attribute).version;
		} else {
			var bufferAttribute = this._getBufferAttribute(attribute);
			if (data.version < bufferAttribute.version || bufferAttribute.usage == DynamicDrawUsage.DynamicDraw) {
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

class Dynamic {
	public function createAttribute(attribute:Dynamic):Void { }
	public function createIndexAttribute(attribute:Dynamic):Void { }
	public function createStorageAttribute(attribute:Dynamic):Void { }
	public function destroyAttribute(attribute:Dynamic):Void { }
	public function updateAttribute(attribute:Dynamic):Void { }
}