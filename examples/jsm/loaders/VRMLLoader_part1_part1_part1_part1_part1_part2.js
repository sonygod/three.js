class VRMLToASTVisitor extends BaseVRMLVisitor {

				constructor() {

					super();

					this.validateVisitor();

				}

				vrml( ctx ) {

					const data = {
						version: this.visit( ctx.version ),
						nodes: [],
						routes: []
					};

					for ( let i = 0, l = ctx.node.length; i < l; i ++ ) {

						const node = ctx.node[ i ];

						data.nodes.push( this.visit( node ) );

					}

					if ( ctx.route ) {

						for ( let i = 0, l = ctx.route.length; i < l; i ++ ) {

							const route = ctx.route[ i ];

							data.routes.push( this.visit( route ) );

						}

					}

					return data;

				}

				version( ctx ) {

					return ctx.Version[ 0 ].image;

				}

				node( ctx ) {

					const data = {
						name: ctx.NodeName[ 0 ].image,
						fields: []
					};

					if ( ctx.field ) {

						for ( let i = 0, l = ctx.field.length; i < l; i ++ ) {

							const field = ctx.field[ i ];

							data.fields.push( this.visit( field ) );

						}

					}

					// DEF

					if ( ctx.def ) {

						data.DEF = this.visit( ctx.def[ 0 ] );

					}

					return data;

				}

				field( ctx ) {

					const data = {
						name: ctx.Identifier[ 0 ].image,
						type: null,
						values: null
					};

					let result;

					// SFValue

					if ( ctx.singleFieldValue ) {

						result = this.visit( ctx.singleFieldValue[ 0 ] );

					}

					// MFValue

					if ( ctx.multiFieldValue ) {

						result = this.visit( ctx.multiFieldValue[ 0 ] );

					}

					data.type = result.type;
					data.values = result.values;

					return data;

				}

				def( ctx ) {

					return ( ctx.Identifier || ctx.NodeName )[ 0 ].image;

				}

				use( ctx ) {

					return { USE: ( ctx.Identifier || ctx.NodeName )[ 0 ].image };

				}

				singleFieldValue( ctx ) {

					return processField( this, ctx );

				}

				multiFieldValue( ctx ) {

					return processField( this, ctx );

				}

				route( ctx ) {

					const data = {
						FROM: ctx.RouteIdentifier[ 0 ].image,
						TO: ctx.RouteIdentifier[ 1 ].image
					};

					return data;

				}

			}