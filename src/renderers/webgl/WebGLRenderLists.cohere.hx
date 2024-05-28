function painterSortStable(a: { groupOrder: Int, renderOrder: Int, material: { id: Int }, z: Float, id: Int }, b: { groupOrder: Int, renderOrder: Int, material: { id: Int }, z: Float, id: Int }): Int {
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

function reversePainterSortStable(a: { groupOrder: Int, renderOrder: Int, z: Float, id: Int }, b: { groupOrder: Int, renderOrder: Int, z: Float, id: Int }): Int {
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

class WebGLRenderList {
    var renderItems: Array<{ id: Null<Int>, object: Null<Dynamic>, geometry: Null<Dynamic>, material: Null<Dynamic>, groupOrder: Null<Int>, renderOrder: Null<Int>, z: Null<Float>, group: Null<Dynamic> }>;
    var renderItemsIndex: Int;
    var opaque: Array<{ id: Null<Int>, object: Null<Dynamic>, geometry: Null<Dynamic>, material: Null<Dynamic>, groupOrder: Null<Int>, renderOrder: Null<Int>, z: Null<Float>, group: Null<Dynamic> }>;
    var transmissive: Array<{ id: Null<Int>, object: Null<Dynamic>, geometry: Null<Dynamic>, material: Null<Dynamic>, groupOrder: Null<Int>, renderOrder: Null<Int>, z: Null<Float>, group: Null<Dynamic> }>;
    var transparent: Array<{ id: Null<Int>, object: Null<Dynamic>, geometry: Null<Dynamic>, material: Null<Dynamic>, groupOrder: Null<Int>, renderOrder: Null<Int>, z: Null<Float>, group: Null<Dynamic> }>;

    public function new() {
        renderItems = [];
        renderItemsIndex = 0;
        opaque = [];
        transmissive = [];
        transparent = [];
    }

    function getNextRenderItem(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): { id: Null<Int>, object: Null<Dynamic>, geometry: Null<Dynamic>, material: Null<Dynamic>, groupOrder: Null<Int>, renderOrder: Null<Int>, z: Null<Float>, group: Null<Dynamic> } {
        var renderItem = renderItems[renderItemsIndex];
        if (renderItem == null) {
            renderItem = { id: null, object: null, geometry: null, material: null, groupOrder: null, renderOrder: null, z: null, group: null };
            renderItems[renderItemsIndex] = renderItem;
        }
        renderItem.id = object.id;
        renderItem.object = object;
        renderItem.geometry = geometry;
        renderItem.material = material;
        renderItem.groupOrder = groupOrder;
        renderItem.renderOrder = object.renderOrder;
        renderItem.z = z;
        renderItem.group = group;
        renderItemsIndex++;
        return renderItem;
    }

    public function push(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic) {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.push(renderItem);
        } else if (material.transparent) {
            transparent.push(renderItem);
        } else {
            opaque.push(renderItem);
        }
    }

    public function unshift(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic) {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.unshift(renderItem);
        } else if (material.transparent) {
            transparent.unshift(renderItem);
        } else {
            opaque.unshift(renderItem);
        }
    }

    public function sort(customOpaqueSort: Null<Function>, customTransparentSort: Null<Function>) {
        if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : $bind(painterSortStable, null));
        if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : $bind(reversePainterSortStable, null));
        if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : $bind(reversePainterSortStable, null));
    }

    public function finish() {
        for (i in renderItemsIndex...renderItems.length) {
            var renderItem = renderItems[i];
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
    var lists: WeakMap<Dynamic, Array<WebGLRenderList>>;

    public function new() {
        lists = new WeakMap();
    }

    function get(scene: Dynamic, renderCallDepth: Int): WebGLRenderList {
        var listArray = lists.get(scene);
        var list: Null<WebGLRenderList> = null;
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

    public function dispose() {
        lists = new WeakMap();
    }
}

class RenderLists {
    public static function WebGLRenderLists(): WebGLRenderLists {
        return new WebGLRenderLists();
    }

    public static function WebGLRenderList(): WebGLRenderList {
        return new WebGLRenderList();
    }
}