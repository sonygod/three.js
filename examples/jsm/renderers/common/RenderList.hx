package three.js.examples.jsm.renderers.common;

import three.nodes.Nodes;

class RenderList {

    public var renderItems:Array<Dynamic> = [];
    public var renderItemsIndex:Int = 0;

    public var opaque:Array<Dynamic> = [];
    public var transparent:Array<Dynamic> = [];

    public var lightsNode:LightsNode;
    public var lightsArray:Array<Dynamic> = [];

    public var occlusionQueryCount:Int = 0;

    public function new() {
        lightsNode = new LightsNode([]);
    }

    public function begin():RenderList {
        renderItemsIndex = 0;

        opaque.splice(0, opaque.length);
        transparent.splice(0, transparent.length);
        lightsArray.splice(0, lightsArray.length);

        occlusionQueryCount = 0;

        return this;
    }

    public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Float, z:Float, group:Dynamic):Dynamic {
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

    public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Float, z:Float, group:Dynamic):Void {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (object.occlusionTest) occlusionQueryCount++;

        if (material.transparent) transparent.push(renderItem);
        else opaque.push(renderItem);
    }

    public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Float, z:Float, group:Dynamic):Void {
        var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

        if (material.transparent) transparent.unshift(renderItem);
        else opaque.unshift(renderItem);
    }

    public function pushLight(light:Dynamic):Void {
        lightsArray.push(light);
    }

    public function getLightsNode():LightsNode {
        return lightsNode.fromLights(lightsArray);
    }

    public function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic):Void {
        if (opaque.length > 1) {
            opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        }
        if (transparent.length > 1) {
            transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
        }
    }

    public function finish():Void {
        // update lights
        lightsNode.fromLights(lightsArray);

        // Clear references from inactive renderItems in the list
        for (i in renderItemsIndex...renderItems.length) {
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

    private function painterSortStable(a:Dynamic, b:Dynamic):Int {
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

    private function reversePainterSortStable(a:Dynamic, b:Dynamic):Int {
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

}