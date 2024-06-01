import haxe.ds.WeakMap;
import haxe.ds.Vector;

class PainterSortStable {
  static function sort(a:Dynamic, b:Dynamic):Int {
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
}

class ReversePainterSortStable {
  static function sort(a:Dynamic, b:Dynamic):Int {
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

class WebGLRenderList {
  public var renderItems:Vector<Dynamic> = new Vector();
  public var renderItemsIndex:Int = 0;
  public var opaque:Vector<Dynamic> = new Vector();
  public var transmissive:Vector<Dynamic> = new Vector();
  public var transparent:Vector<Dynamic> = new Vector();

  public function new() {
  }

  public function init() {
    renderItemsIndex = 0;
    opaque.length = 0;
    transmissive.length = 0;
    transparent.length = 0;
  }

  public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Int, group:Dynamic):Dynamic {
    var renderItem = renderItems.get(renderItemsIndex);
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
      renderItems.set(renderItemsIndex, renderItem);
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

  public function push(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Int, group:Dynamic) {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    if (material.transmission > 0.0) {
      transmissive.push(renderItem);
    } else if (material.transparent == true) {
      transparent.push(renderItem);
    } else {
      opaque.push(renderItem);
    }
  }

  public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Int, group:Dynamic) {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
    if (material.transmission > 0.0) {
      transmissive.unshift(renderItem);
    } else if (material.transparent == true) {
      transparent.unshift(renderItem);
    } else {
      opaque.unshift(renderItem);
    }
  }

  public function sort(customOpaqueSort:Dynamic = null, customTransparentSort:Dynamic = null) {
    if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : PainterSortStable.sort);
    if (transmissive.length > 1) transmissive.sort(customTransparentSort != null ? customTransparentSort : ReversePainterSortStable.sort);
    if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : ReversePainterSortStable.sort);
  }

  public function finish() {
    for (i in 0...renderItems.length) {
      var renderItem = renderItems.get(i);
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
  public var lists:WeakMap<Dynamic, Vector<Dynamic>> = new WeakMap();

  public function new() {
  }

  public function get(scene:Dynamic, renderCallDepth:Int):WebGLRenderList {
    var listArray = lists.get(scene);
    var list:WebGLRenderList;
    if (listArray == null) {
      list = new WebGLRenderList();
      lists.set(scene, new Vector([list]));
    } else {
      if (renderCallDepth >= listArray.length) {
        list = new WebGLRenderList();
        listArray.push(list);
      } else {
        list = listArray.get(renderCallDepth);
      }
    }
    return list;
  }

  public function dispose() {
    lists = new WeakMap();
  }
}