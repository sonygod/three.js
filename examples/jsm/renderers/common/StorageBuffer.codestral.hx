import Buffer from './Buffer';

class StorageBuffer extends Buffer {

    public function new(name: String, attribute: Dynamic) {

        super(name, (attribute != null && attribute.hasOwnProperty('array')) ? attribute.array : null);

        this.attribute = attribute;

        this.isStorageBuffer = true;

    }

}

export default StorageBuffer;