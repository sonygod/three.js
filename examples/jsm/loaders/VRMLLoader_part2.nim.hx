class VRMLToASTVisitor extends BaseVRMLVisitor {

	public function new() {

		super();

		this.validateVisitor();

	}

	public function vrml( ctx ) {

		var data = {
			version: this.visit( ctx.version ),
			nodes: [],
			routes: []
		};

		for ( i in 0...ctx.node.length ) {

			var node = ctx.node[ i ];

			data.nodes.push( this.visit( node ) );

		}

		if ( ctx.route != null ) {

			for ( i in 0...ctx.route.length ) {

				var route = ctx.route[ i ];

				data.routes.push( this.visit( route ) );

			}

		}

		return data;

	}

	public function version( ctx ) {

		return ctx.Version[ 0 ].image;

	}

	public function node( ctx ) {

		var data = {
			name: ctx.NodeName[ 0 ].image,
			fields: []
		};

		if ( ctx.field != null ) {

			for ( i in 0...ctx.field.length ) {

				var field = ctx.field[ i ];

				data.fields.push( this.visit( field ) );

			}

		}

		// DEF

		if ( ctx.def != null ) {

			data.DEF = this.visit( ctx.def[ 0 ] );

		}

		return data;

	}

	public function field( ctx ) {

		var data = {
			name: ctx.Identifier[ 0 ].image,
			type: null,
			values: null
		};

		var result;

		// SFValue

		if ( ctx.singleFieldValue != null ) {

			result = this.visit( ctx.singleFieldValue[ 0 ] );

		}

		// MFValue

		if ( ctx.multiFieldValue != null ) {

			result = this.visit( ctx.multiFieldValue[ 0 ] );

		}

		data.type = result.type;
		data.values = result.values;

		return data;

	}

	public function def( ctx ) {

		return ( ctx.Identifier || ctx.NodeName )[ 0 ].image;

	}

	public function use( ctx ) {

		return { USE: ( ctx.Identifier || ctx.NodeName )[ 0 ].image };

	}

	public function singleFieldValue( ctx ) {

		return processField( this, ctx );

	}

	public function multiFieldValue( ctx ) {

		return processField( this, ctx );

	}

	public function route( ctx ) {

		var data = {
			FROM: ctx.RouteIdentifier[ 0 ].image,
			TO: ctx.RouteIdentifier[ 1 ].image
		};

		return data;

	}

}