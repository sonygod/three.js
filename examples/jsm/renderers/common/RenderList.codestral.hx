class RenderItem {
    public var id:Int;
    public var object:Dynamic;
    public var geometry:Dynamic;
    public var material:Dynamic;
    public var groupOrder:Int;
    public var renderOrder:Int;
    public var z:Float;
    public var group:Dynamic;

    public function new(id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic) {
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

class RenderList {
    public var renderItems:Array<RenderItem>;
    public var renderItemsIndex:Int;
    public var opaque:Array<RenderItem>;
    public var transparent:Array<Array<RenderItem>>;
    public var lightsNode:LightsNode;
    public var lightsArray:Array<Dynamic>;
    public var occlusionQueryCount:Int;

    public function new() {
        this.renderItems = new Array<RenderItem>();
        this.renderItemsIndex = 0;
        this.opaque = new Array<RenderItem>();
        this.transparent = new Array<Array<RenderItem>>();
        this.lightsNode = new LightsNode(new Array<Dynamic>());
        this.lightsArray = new Array<Dynamic>();
        this.occlusionQueryCount = 0;
    }

    public function begin():RenderList {
        this.renderItemsIndex = 0;
        this.opaque = new Array<RenderItem>();
        this.transparent = new Array<Array<RenderItem>>();
        this.lightsArray = new Array<Dynamic>();
        this.occlusionQueryCount = 0;
        return this;
    }

    public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):RenderItem {
        var renderItem = this.renderItems[this.renderItemsIndex];
        if (renderItem == null) {
            renderItem = new RenderItem(object.id, object, geometry, material, groupOrder, object.renderOrder, z, group);
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

    public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (Std.is(object.occlusionTest, Bool) && object.occlusionTest) this.occlusionQueryCount++;
        if (Std.is(material.transparent, Bool) && material.transparent || Std.is(material.transmission, Int) && material.transmission > 0) {
            this.transparent.push(renderItem);
        } else {
            this.opaque.push(renderItem);
        }
    }

    public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {
        var renderItem = this.getNextRenderItem(object, geometry, material, groupOrder, z, group);
        if (Std.is(material.transparent, Bool) && material.transparent) {
            this.transparent.unshift(renderItem);
        } else {
            this.opaque.unshift(renderItem);
        }
    }

    public function pushLight(light:Dynamic) {
        this.lightsArray.push(light);
    }

    public function getLightsNode():LightsNode {
        return this.lightsNode.fromLights(this.lightsArray);
    }

    public function sort(customOpaqueSort:Function = null, customTransparentSort:Function = null) {
        if (this.opaque.length > 1) this.opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
        if (this.transparent.length > 1) this.transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }

    public function finish() {
        this.lightsNode.fromLights(this.lightsArray);
        for (var i = this.renderItemsIndex, il = this.renderItems.length; i < il; i++) {
            var renderItem = this.renderItems[i];
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

static function painterSortStable(a:RenderItem, b:RenderItem):Int {
    if (a.groupOrder != b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder != b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.material.id != b.material.id) {
        return a.material.id - b.material.id;
    } else if (a.z != b.z) {
        return (a.z - b.z) > 0 ? 1 : -1;
    } else {
        return a.id - b.id;
    }
}

static function reversePainterSortStable(a:RenderItem, b:RenderItem):Int {
    if (a.groupOrder != b.groupOrder) {
        return a.groupOrder - b.groupOrder;
    } else if (a.renderOrder != b.renderOrder) {
        return a.renderOrder - b.renderOrder;
    } else if (a.z != b.z) {
        return (b.z - a.z) > 0 ? 1 : -1;
    } else {
        return a.id - b.id;
    }
}