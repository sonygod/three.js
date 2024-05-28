package three.js.src.renderers.webgl;

import haxe.ds.WeakMap;

class WebGLRenderList {
    private var renderItems:Array<RenderItem> = [];
    private var renderItemsIndex:Int = 0;
    public var opaque:Array<RenderItem> = [];
    public var transmissive:Array<RenderItem> = [];
    public var transparent:Array<RenderItem> = [];

    public function new() {}

    private function init():Void {
        renderItemsIndex = 0;
        opaque = [];
        transmissive = [];
        transparent = [];
    }

    private function getNextRenderItem(object:Any, geometry:Any, material:Any, groupOrder:Int, z:Float, group:Any):RenderItem {
        var renderItem:RenderItem = renderItems[renderItemsIndex];
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

    public function push(object:Any, geometry:Any, material:Any, groupOrder:Int, z:Float, group:Any):Void {
        var renderItem:RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.push(renderItem);
        } else if (material.transparent) {
            transparent.push(renderItem);
        } else {
            opaque.push(renderItem);
        }
    }

    public function unshift(object:Any, geometry:Any, material:Any, groupOrder:Int, z:Float, group:Any):Void {
        var renderItem:RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (material.transmission > 0.0) {
            transmissive.unshift(renderItem);
        } else if (material.transparent) {
            transparent.unshift(renderItem);
        } else {
            opaque.unshift(renderItem);
        }
    }

    public function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic):Void {
        if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
        if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }

    public function finish():Void {
        for (i in renderItemsIndex...renderItems.length) {
            var renderItem:RenderItem = renderItems[i];
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
    private var lists:WeakMap<Any, Array<WebGLRenderList>> = new WeakMap();

    public function get(scene:Any, renderCallDepth:Int):WebGLRenderList {
        var listArray:Array<WebGLRenderList> = lists.get(scene);
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

// Sorting functions
function painterSortStable(a:RenderItem, b:RenderItem):Int {
    if (a.groupOrder != b.groupOrder) return a.groupOrder - b.groupOrder;
    else if (a.renderOrder != b.renderOrder) return a.renderOrder - b.renderOrder;
    else if (a.material.id != b.material.id) return a.material.id - b.material.id;
    else if (a.z != b.z) return a.z - b.z;
    else return a.id - b.id;
}

function reversePainterSortStable(a:RenderItem, b:RenderItem):Int {
    if (a.groupOrder != b.groupOrder) return a.groupOrder - b.groupOrder;
    else if (a.renderOrder != b.renderOrder) return a.renderOrder - b.renderOrder;
    else if (a.z != b.z) return b.z - a.z;
    else return a.id - b.id;
}