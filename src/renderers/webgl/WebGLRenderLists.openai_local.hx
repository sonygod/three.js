package three.js.src.renderers.webgl;

class WebGLRenderLists {

    private var lists:WeakMap<Dynamic, Array<WebGLRenderList>>;

    public function new() {
        lists = new WeakMap();
    }

    public function get(scene:Dynamic, renderCallDepth:Int):WebGLRenderList {
        var listArray = lists.get(scene);
        var list:WebGLRenderList;

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

    public function dispose():Void {
        lists = new WeakMap();
    }
}

class WebGLRenderList {

    private var renderItems:Array<Dynamic>;
    private var renderItemsIndex:Int;
    public var opaque:Array<Dynamic>;
    public var transmissive:Array<Dynamic>;
    public var transparent:Array<Dynamic>;

    public function new() {
        renderItems = [];
        renderItemsIndex = 0;
        opaque = [];
        transmissive = [];
        transparent = [];
    }

    public function init():Void {
        renderItemsIndex = 0;
        opaque = [];
        transmissive = [];
        transparent = [];
    }

    private function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Dynamic {
        var renderItem = renderItems[renderItemsIndex];

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

    public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (material.transmission > 0.0) {
            transmissive.push(renderItem);
        } else if (material.transparent) {
            transparent.push(renderItem);
        } else {
            opaque.push(renderItem);
        }
    }

    public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (material.transmission > 0.0) {
            transmissive.unshift(renderItem);
        } else if (material.transparent) {
            transparent.unshift(renderItem);
        } else {
            opaque.unshift(renderItem);
        }
    }

    public function sort(customOpaqueSort:Dynamic->Dynamic->Int, customTransparentSort:Dynamic->Dynamic->Int):Void {
        if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
        if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }

    public function finish():Void {
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

    private static function painterSortStable(a:Dynamic, b:Dynamic):Int {
        if (a.groupOrder != b.groupOrder) return a.groupOrder - b.groupOrder;
        if (a.renderOrder != b.renderOrder) return a.renderOrder - b.renderOrder;
        if (a.material.id != b.material.id) return a.material.id - b.material.id;
        if (a.z != b.z) return a.z - b.z;
        return a.id - b.id;
    }

    private static function reversePainterSortStable(a:Dynamic, b:Dynamic):Int {
        if (a.groupOrder != b.groupOrder) return a.groupOrder - b.groupOrder;
        if (a.renderOrder != b.renderOrder) return a.renderOrder - b.renderOrder;
        if (a.z != b.z) return b.z - a.z;
        return a.id - b.id;
    }
}