class WebGLRenderList {

    var renderItems:Array<Dynamic> = [];
    var renderItemsIndex:Int = 0;

    var opaque:Array<Dynamic> = [];
    var transmissive:Array<Dynamic> = [];
    var transparent:Array<Dynamic> = [];

    function new() {

    }

    function init() {

        renderItemsIndex = 0;

        opaque.length = 0;
        transmissive.length = 0;
        transparent.length = 0;

    }

    function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {

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

    function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {

        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (material.transmission > 0.0) {

            transmissive.push(renderItem);

        } else if (material.transparent) {

            transparent.push(renderItem);

        } else {

            opaque.push(renderItem);

        }

    }

    function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {

        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (material.transmission > 0.0) {

            transmissive.unshift(renderItem);

        } else if (material.transparent) {

            transparent.unshift(renderItem);

        } else {

            opaque.unshift(renderItem);

        }

    }

    function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic) {

        if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
        if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);

    }

    function finish() {

        for (i in Std.range(renderItemsIndex, renderItems.length)) {

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

    var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

    function new() {

    }

    function get(scene:Dynamic, renderCallDepth:Int) {

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

    function dispose() {

        lists = new WeakMap();

    }

}