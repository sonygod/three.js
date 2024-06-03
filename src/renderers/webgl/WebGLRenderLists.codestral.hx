class RenderItem {
    public var id: Int;
    public var object: Dynamic;
    public var geometry: Dynamic;
    public var material: Dynamic;
    public var groupOrder: Int;
    public var renderOrder: Int;
    public var z: Float;
    public var group: Dynamic;

    public function new(id: Int, object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, renderOrder: Int, z: Float, group: Dynamic) {
        this.id = id;
        this.object = object;
        this.geometry = geometry;
        this.material = material;
        this.groupOrder = groupOrder;
        this.renderOrder = renderOrder;
        this.z = z;
        this.group = group;
    }
}

class WebGLRenderList {
    private var renderItems: Array<RenderItem> = [];
    private var renderItemsIndex: Int = 0;
    private var opaque: Array<RenderItem> = [];
    private var transmissive: Array<RenderItem> = [];
    private var transparent: Array<RenderItem> = [];

    public function new() {}

    public function init(): Void {
        renderItemsIndex = 0;
        opaque = [];
        transmissive = [];
        transparent = [];
    }

    private function getNextRenderItem(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): RenderItem {
        var renderItem: RenderItem = renderItems[renderItemsIndex];
        if (renderItem == null) {
            renderItem = new RenderItem(object.id, object, geometry, material, groupOrder, object.renderOrder, z, group);
            renderItems[renderItemsIndex] = renderItem;
        } else {
            renderItem.id = object.id;
            renderItem.object = object;
            renderItem.geometry = geometry;
            renderItem.material = material;
            renderItem.groupOrder = groupOrder;
            renderItem.renderOrder = object.renderOrder;
            renderItem.z = z;
            renderItem.group = group;
        }
        renderItemsIndex++;
        return renderItem;
    }

    public function push(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): Void {
        var renderItem: RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.push(renderItem);
        } else if (material.transparent == true) {
            transparent.push(renderItem);
        } else {
            opaque.push(renderItem);
        }
    }

    public function unshift(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): Void {
        var renderItem: RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.unshift(renderItem);
        } else if (material.transparent == true) {
            transparent.unshift(renderItem);
        } else {
            opaque.unshift(renderItem);
        }
    }

    public function sort(customOpaqueSort: Function = null, customTransparentSort: Function = null): Void {
        if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
        if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }

    public function finish(): Void {
        for (var i: Int = renderItemsIndex, il = renderItems.length; i < il; i++) {
            var renderItem: RenderItem = renderItems[i];
            if (renderItem.id == null) break;
            renderItem.id = null;
            renderItem.object = null;
            renderItem.geometry = null;
            renderItem.material = null;
            renderItem.group = null;
        }
    }

    public function painterSortStable(a: RenderItem, b: RenderItem): Int {
        if (a.groupOrder != b.groupOrder) {
            return a.groupOrder - b.groupOrder;
        } else if (a.renderOrder != b.renderOrder) {
            return a.renderOrder - b.renderOrder;
        } else if (a.material.id != b.material.id) {
            return a.material.id - b.material.id;
        } else if (a.z != b.z) {
            return (a.z - b.z) as Int;
        } else {
            return a.id - b.id;
        }
    }

    public function reversePainterSortStable(a: RenderItem, b: RenderItem): Int {
        if (a.groupOrder != b.groupOrder) {
            return a.groupOrder - b.groupOrder;
        } else if (a.renderOrder != b.renderOrder) {
            return a.renderOrder - b.renderOrder;
        } else if (a.z != b.z) {
            return (b.z - a.z) as Int;
        } else {
            return a.id - b.id;
        }
    }
}

class WebGLRenderLists {
    private var lists: haxe.ds.WeakMap = new haxe.ds.WeakMap();

    public function new() {}

    public function get(scene: Dynamic, renderCallDepth: Int): WebGLRenderList {
        var listArray: Array<WebGLRenderList> = lists.get(scene);
        var list: WebGLRenderList;
        if (listArray == null) {
            list = new WebGLRenderList();
            lists.set(scene, [list]);
        } else {
            if (renderCallDepth >= listArray.length) {
                list = new WebGLRenderList();
                listArray.push(list);
            } else {
                list = listArray[renderCallDepth];
            }
        }
        return list;
    }

    public function dispose(): Void {
        lists = new haxe.ds.WeakMap();
    }
}