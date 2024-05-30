import js.Node;

class RenderList {
	var renderItems: Array<RenderItem>;
	var renderItemsIndex: Int;
	var opaque: Array<RenderItem>;
	var transparent: Array<RenderItem>;
	var lightsNode: LightsNode;
	var lightsArray: Array<Dynamic>;
	var occlusionQueryCount: Int;

	public function new() {
		renderItems = [];
		renderItemsIndex = 0;
		opaque = [];
		transparent = [];
		lightsNode = new LightsNode([]);
		lightsArray = [];
		occlusionQueryCount = 0;
	}

	public function begin(): RenderList {
		renderItemsIndex = 0;
		opaque.length = 0;
		transparent.length = 0;
		lightsArray.length = 0;
		occlusionQueryCount = 0;
		return this;
	}

	public function getNextRenderItem(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): RenderItem {
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

	public function push(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): Void {
		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
		if (object.occlusionTest == true) occlusionQueryCount++;
		if (material.transparent == true || material.transmission > 0) {
			transparent.push(renderItem);
		} else {
			opaque.push(renderItem);
		}
	}

	public function unshift(object: Dynamic, geometry: Dynamic, material: Dynamic, groupOrder: Int, z: Float, group: Dynamic): Void {
		var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);
		if (material.transparent == true) {
			transparent.unshift(renderItem);
		} else {
			opaque.unshift(renderItem);
		}
	}

	public function pushLight(light: Dynamic): Void {
		lightsArray.push(light);
	}

	public function getLightsNode(): LightsNode {
		return lightsNode.fromLights(lightsArray);
	}

	public function sort(customOpaqueSort: Dynamic, customTransparentSort: Dynamic): Void {
		if (opaque.length > 1) opaque.sort(customOpaqueSort != null ? customOpaqueSort : painterSortStable);
		if (transparent.length > 1) transparent.sort(customTransparentSort != null ? customTransparentSort : reversePainterSortStable);
	}

	public function finish(): Void {
		// update lights
		lightsNode.fromLights(lightsArray);

		// Clear references from inactive renderItems in the list
		var i = renderItemsIndex;
		while (i < renderItems.length) {
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
			i++;
		}
	}
}

typedef RenderItem = {
	id: Int,
	object: Dynamic,
	geometry: Dynamic,
	material: Dynamic,
	groupOrder: Int,
	renderOrder: Int,
	z: Float,
	group: Dynamic
}

function painterSortStable(a: RenderItem, b: RenderItem): Int {
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

function reversePainterSortStable(a: RenderItem, b: RenderItem): Int {
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

class LightsNode extends js.Node {
	// ...
}

class js.Node {
	// ...
}