import haxe.ds.WeakMap;

class WebGLRenderList {

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

function painterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

function reversePainterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

class WebGLRenderLists {

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

function painterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

function reversePainterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

class WebGLRenderLists {

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();
	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

function painterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

function reversePainterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

class WebGLRenderLists {

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group
		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

function painterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

function reversePainterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

class WebGLRenderLists {

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent ==
	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

function painterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

function reversePainterSortStable(a:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }, b:{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }):Int {

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

class WebGLRenderLists {

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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

	public var renderItems:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var renderItemsIndex:Int = 0;

	public var opaque:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transmissive:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];
	public var transparent:Array<{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic }> = [];

	public function new() {
	}

	public function init():Void {

		renderItemsIndex = 0;

		opaque.length = 0;
		transmissive.length = 0;
		transparent.length = 0;

	}

	public function getNextRenderItem(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):{ id:Int, object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, renderOrder:Int, z:Float, group:Dynamic } {

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

		} else if (material.transparent == true) {

			transparent.push(renderItem);

		} else {

			opaque.push(renderItem);

		}

	}

	public function unshift(object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Int, z:Float, group:Dynamic):Void {

		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

		if (material.transmission > 0.0) {

			transmissive.unshift(renderItem);

		} else if (material.transparent == true) {

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

		// Clear references from inactive renderItems in the list

		for (var i = renderItemsIndex; i < renderItems.length; i++) {

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

	public var lists:WeakMap<Dynamic, Array<WebGLRenderList>> = new WeakMap();

	public function new() {
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