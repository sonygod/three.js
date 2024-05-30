package three.js.examples.jsm.renderers.common;

import three.js.nodes.Nodes.LightsNode;

class RenderList {
  public var renderItems:Array<RenderItem>;
  public var renderItemsIndex:Int;
  public var opaque:Array<RenderItem>;
  public var transparent:Array<RenderItem>;
  public var lightsNode:LightsNode;
  public var lightsArray:Array<Dynamic>;
  public var occlusionQueryCount:Int;

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
    opaque = [];
    transparent = [];
    lightsArray = [];
    occlusionQueryCount = 0;
    return this;
  }

  public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):RenderItem {
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

  public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {
    var renderItem:RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    if (object.occlusionTest) occlusionQueryCount++;
    (material.transparent || material.transmission > 0 ? transparent : opaque).push(renderItem);
  }

  public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic) {
    var renderItem:RenderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    (material.transparent ? transparent : opaque).unshift(renderItem);
  }

  public function pushLight(light:Dynamic) {
    lightsArray.push(light);
  }

  public function getLightsNode():LightsNode {
    return lightsNode.fromLights(lightsArray);
  }

  public function sort(customOpaqueSort:Dynamic, customTransparentSort:Dynamic) {
    if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
    if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
  }

  public function finish() {
    lightsNode.fromLights(lightsArray);
    for (i in renderItemsIndex...renderItems.length) {
      var renderItem:RenderItem = renderItems[i];
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

typedef RenderItem = {
  id:Int,
  object:Dynamic,
  geometry:Dynamic,
  material:Dynamic,
  groupOrder:Int,
  renderOrder:Int,
  z:Float,
  group:Dynamic
};

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