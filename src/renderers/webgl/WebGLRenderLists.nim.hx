import haxe.ds.WeakMap;

class WebGLRenderList {
    var renderItems:Array<Dynamic>;
    var renderItemsIndex:Int;
    var opaque:Array<Dynamic>;
    var transmissive:Array<Dynamic>;
    var transparent:Array<Dynamic>;

    public function new() {
        this.renderItems = [];
        this.renderItemsIndex = 0;
        this.opaque = [];
        this.transmissive = [];
        this.transparent = [];
    }

    public function init() {
        this.renderItemsIndex = 0;
        this.opaque.length = 0;
        this.transmissive.length = 0;
        this.transparent.length = 0;
    }

    public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic):Dynamic {
        var renderItem = this.renderItems[this.renderItemsIndex];
        if (renderItem == null) {
            renderItem = {
                id: object.id,
                object: object,
                geometry: geometry,
                material: material,
                groupOrder: groupOrder,
                renderOrder: object.renderOrder,
                z: z,
                group: group
            };
            this.renderItems[this.renderItemsIndex] = renderItem;
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
        this.renderItemsIndex++;
        return renderItem;
    }

    public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic) {
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            this.transmissive.push(renderItem);
        } else if (material.transparent == true) {
            this.transparent.push(renderItem);
        } else {
            this.opaque.push(renderItem);
        }
    }

    public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic) {
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            this.transmissive.unshift(renderItem);
        } else if (material.transparent == true) {
            this.transparent.unshift(renderItem);
        } else {
            this.opaque.unshift(renderItem);
        }
    }

    public function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic) {
        if (this.opaque.length > 1) this.opaque.sort(customOpaqueSort || painterSortStable);
        if (this.transmissive.length > 1) this.transmissive.sort(customTransparentSort || reversePainterSortStable);
        if (this.transparent.length > 1) this.transparent.sort(customTransparentSort || reversePainterSortStable);
    }

    public function finish() {
        for (i in this.renderItemsIndex..this.renderItems.length) {
            var renderItem = this.renderItems[i];
            if (renderItem.id == null) break;
            renderItem.id = null;
            renderItem.object = null;
            renderItem.geometry = null;
            renderItem.material = null;
            renderItem.group = null;
        }
    }
}

class WebGLRenderLists {
    var lists:WeakMap<Dynamic, Array<WebGLRenderList>>;

    public function new() {
        this.lists = new WeakMap<Dynamic, Array<WebGLRenderList>>();
    }

    public function get(scene:Dynamic, renderCallDepth:Dynamic):WebGLRenderList {
        var listArray = this.lists.get(scene);
        var list:WebGLRenderList;
        if (listArray == null) {
            list = new WebGLRenderList();
            this.lists.set(scene, [list]);
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

    public function dispose() {
        this.lists = new WeakMap<Dynamic, Array<WebGLRenderList>>();
    }
}

function painterSortStable(a:Dynamic, b:Dynamic):Int {
    if (a.groupOrder != b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder != b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.material.id != b.material.id) {
        return a.material.id - b.material.id;
    } else if (a.z != b.z) {
        return a.z - b.z;
    } else {
        return a.id - b.id;
    }
}

function reversePainterSortStable(a:Dynamic, b:Dynamic):Int {
    if (a.groupOrder != b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder != b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.z != b.z) {
        return b.z - a.z;
    } else {
        return a.id - b.id;
    }
}