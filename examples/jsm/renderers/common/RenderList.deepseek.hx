import three.nodes.LightsNode;

function painterSortStable(a:Dynamic, b:Dynamic):Int {
    if (a.groupOrder !== b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder !== b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.material.id !== b.material.id) {
        return a.material.id - b.material.id;
    } else if (a.z !== b.z) {
        return a.z - b.z;
    } else {
        return a.id - b.id;
    }
}

function reversePainterSortStable(a:Dynamic, b:Dynamic):Int {
    if (a.groupOrder !== b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder !== b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.z !== b.z) {
        return b.z - a.z;
    } else {
        return a.id - b.id;
    }
}

class RenderList {
    var renderItems:Array<Dynamic>;
    var renderItemsIndex:Int;
    var opaque:Array<Dynamic>;
    var transparent:Array<Dynamic>;
    var lightsNode:LightsNode;
    var lightsArray:Array<Dynamic>;
    var occlusionQueryCount:Int;

    public function new() {
        renderItems = [];
        renderItemsIndex = 0;
        opaque = [];
        transparent = [];
        lightsNode = new LightsNode([]);
        lightsArray = [];
        occlusionQueryCount = 0;
    }

    public function begin():RenderList {
        renderItemsIndex = 0;
        opaque.length = 0;
        transparent.length = 0;
        lightsArray.length = 0;
        occlusionQueryCount = 0;
        return this;
    }

    public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Dynamic {
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
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (object.occlusionTest == true) occlusionQueryCount++;
        (material.transparent == true || material.transmission > 0 ? this.transparent : this.opaque).push(renderItem);
    }

    public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        (material.transparent == true ? this.transparent : this.opaque).unshift(renderItem);
    }

    public function pushLight(light:Dynamic):Void {
        lightsArray.push(light);
    }

    public function getLightsNode():LightsNode {
        return lightsNode.fromLights(lightsArray);
    }

    public function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic):Void {
        if (opaque.length > 1) opaque.sort(customOpaqueSort || painterSortStable);
        if (transparent.length > 1) transparent.sort(customTransparentSort || reversePainterSortStable);
    }

    public function finish():Void {
        lightsNode.fromLights(lightsArray);
        for (i in Std.range(renderItemsIndex, renderItems.length)) {
            var renderItem = renderItems[i];
            if (renderItem.id == null) break;
            renderItem.id = null;
            renderItem.object = null;
            renderItem.geometry = null;
            renderItem.material = null;
            renderItem.groupOrder = null;
            renderItem.renderOrder = null;
            renderItem.z = null;
            renderItem.group = null;
        }
    }
}