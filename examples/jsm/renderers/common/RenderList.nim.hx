import LightsNode from '../../nodes/Nodes.hx';

function painterSortStable( a:Dynamic, b:Dynamic ) {

	if ( a.groupOrder !== b.groupOrder ) {

		return a.groupOrder - b.groupOrder;

	} else if ( a.renderOrder !== b.renderOrder ) {

		return a.renderOrder - b.renderOrder;

	} else if ( a.material.id !== b.material.id ) {

		return a.material.id - b.material.id;

	} else if ( a.z !== b.z ) {

		return a.z - b.z;

	} else {

		return a.id - b.id;

	}

}

function reversePainterSortStable( a:Dynamic, b:Dynamic ) {

	if ( a.groupOrder !== b.groupOrder ) {

		return a.groupOrder - b.groupOrder;

	} else if ( a.renderOrder !== b.renderOrder ) {

		return a.renderOrder - b.renderOrder;

	} else if ( a.z !== b.z ) {

		return b.z - a.z;

	} else {

		return a.id - b.id;

	}

}

class RenderList {

	public var renderItems:Array<Dynamic>;
	public var renderItemsIndex:Int;

	public var opaque:Array<Dynamic>;
	public var transparent:Array<Dynamic>;

	public var lightsNode:LightsNode;
	public var lightsArray:Array<Dynamic>;

	public var occlusionQueryCount:Int;

	public function new() {

		this.renderItems = [];
		this.renderItemsIndex = 0;

		this.opaque = [];
		this.transparent = [];

		this.lightsNode = new LightsNode( [] );
		this.lightsArray = [];

		this.occlusionQueryCount = 0;

	}

	public function begin() {

		this.renderItemsIndex = 0;

		this.opaque.length = 0;
		this.transparent.length = 0;
		this.lightsArray.length = 0;

		this.occlusionQueryCount = 0;

		return this;

	}

	public function getNextRenderItem( object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic ) {

		var renderItem:Dynamic = this.renderItems[ this.renderItemsIndex ];

		if ( renderItem === null ) {

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

			this.renderItems[ this.renderItemsIndex ] = renderItem;

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

		this.renderItemsIndex ++;

		return renderItem;

	}

	public function push( object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic ) {

		var renderItem:Dynamic = this.getNextRenderItem( object, geometry, material, groupOrder, z, group );

		if ( object.occlusionTest === true ) this.occlusionQueryCount ++;

		( material.transparent === true || material.transmission > 0 ? this.transparent : this.opaque ).push( renderItem );

	}

	public function unshift( object:Dynamic, geometry:Dynamic, material:Dynamic, groupOrder:Dynamic, z:Dynamic, group:Dynamic ) {

		var renderItem:Dynamic = this.getNextRenderItem( object, geometry, material, groupOrder, z, group );

		( material.transparent === true ? this.transparent : this.opaque ).unshift( renderItem );

	}

	public function pushLight( light:Dynamic ) {

		this.lightsArray.push( light );

	}

	public function getLightsNode() {

		return this.lightsNode.fromLights( this.lightsArray );

	}

	public function sort( customOpaqueSort:Dynamic, customTransparentSort:Dynamic ) {

		if ( this.opaque.length > 1 ) this.opaque.sort( customOpaqueSort || painterSortStable );
		if ( this.transparent.length > 1 ) this.transparent.sort( customTransparentSort || reversePainterSortStable );

	}

	public function finish() {

		// update lights

		this.lightsNode.fromLights( this.lightsArray );

		// Clear references from inactive renderItems in the list

		for ( i in this.renderItemsIndex...this.renderItems.length ) {

			var renderItem:Dynamic = this.renderItems[ i ];

			if ( renderItem.id === null ) break;

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

export default RenderList;