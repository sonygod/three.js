package three.js.src.renderers.webgl;

import haxe.ds.WeakMap;
import haxe.ds.ArraySort;

class WebGLRenderList {
  var renderItems:Array<RenderItem> = [];
  var renderItemsIndex:Int = 0;

  var opaque:Array<RenderItem> = [];
  var transmissive:Array<RenderItem> = [];
  var transparent:Array<RenderItem> = [];

  public function new() {}

  function init():Void {
    renderItemsIndex = 0;
    opaque.splice(0, opaque.length);
    transmissive.splice(0, transmissive.length);
    transparent.splice(0, transparent.length);
  }

  function getNextRenderItem(object:Object3D, geometry:Geometry, material:Material, groupOrder:Int, z:Float, group:Object3D):RenderItem {
    var renderItem:RenderItem;
    if (renderItemsIndex >= renderItems.length) {
      renderItem = new RenderItem();
      renderItems[renderItemsIndex] = renderItem;
    } else {
      renderItem = renderItems[renderItemsIndex];
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

  function push(object:Object3D, geometry:Geometry, material:Material, groupOrder:Int, z:Float, group:Object3D):Void {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    if (material.transmission > 0.0) {
      transmissive.push(restaurantItem);
    } else if (material.transparent) {
      transparent.push(renderItem);
    } else {
      opaque.push(renderItem);
    }
  }

  function unshift(object:Object3D, geometry:Geometry, material:Material, groupOrder:Int, z:Float, group:Object3D):Void {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    if (material.transmission > 0.0) {
      transmissive.unshift(renderItem);
    } else if (material.transparent) {
      transparent.unshift(renderItem);
    } else {
      opaque.unshift(renderItem);
    }
  }

  function sort(customOpaqueSort:(a:RenderItem, b:RenderItem) -> Int, customTransparentSort:(a:RenderItem, b:RenderItem) -> Int):Void {
    if (opaque.length > 1) {
      opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
    }
    if (transmissive.length > 1) {
      transmissive.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }
    if (transparent.length > 1) {
      transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
    }
  }

  function finish():Void {
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

  public function get_opaque():Array<RenderItem> {
    return opaque;
  }

  public function get_transmissive():Array<RenderItem> {
    return transmissive;
  }

  public function get_transparent():Array<RenderItem> {
    return transparent;
  }

  public function init():Void {
    init();
  }

  public function push(object:Object3D, geometry:Geometry, material:Material, groupOrder:Int, z:Float, group:Object3D):Void {
    push(object, geometry, material, groupOrder, z, group);
  }

  public function unshift(object:Object3D, geometry:Geometry, material:Material, groupOrder:Int, z:Float, group:Object3D):Void {
    unshift(object, geometry, material, groupOrder, z, group);
  }

  public function finish():Void {
    finish();
  }

  public function sort(customOpaqueSort:(a:RenderItem, b:RenderItem) -> Int, customTransparentSort:(a:RenderItem, b:RenderItem) -> Int):Void {
    sort(customOpaqueSort, customTransparentSort);
  }
}

class WebGLRenderLists {
  var lists:WeakMap<Scene, Array<WebGLRenderList>> = new WeakMap();

  function get(scene:Scene, renderCallDepth:Int):WebGLRenderList {
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

  function dispose():Void {
    lists = new WeakMap();
  }
}

// Sorting functions
function painterSortStable(a:RenderItem, b:RenderItem):Int {
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

function reversePainterSortStable(a:RenderItem, b:RenderItem):Int {
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