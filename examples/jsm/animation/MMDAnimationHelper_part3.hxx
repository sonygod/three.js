class GrantSolver {

	var mesh:Dynamic;
	var grants:Array<Dynamic>;

	public function new(mesh:Dynamic, ?grants:Array<Dynamic>) {
		this.mesh = mesh;
		this.grants = grants != null ? grants : [];
	}

	/**
	 * Solve all the grant bones
	 * @return {GrantSolver}
	 */
	public function update():GrantSolver {
		var grants = this.grants;
		for (i in 0...grants.length) {
			this.updateOne(grants[i]);
		}
		return this;
	}

	/**
	 * Solve a grant bone
	 * @param {Object} grant - grant parameter
	 * @return {GrantSolver}
	 */
	public function updateOne(grant:Dynamic):GrantSolver {
		var bones = this.mesh.skeleton.bones;
		var bone = bones[grant.index];
		var parentBone = bones[grant.parentIndex];
		if (grant.isLocal) {
			// TODO: implement
			if (grant.affectPosition) {
			}
			// TODO: implement
			if (grant.affectRotation) {
			}
		} else {
			// TODO: implement
			if (grant.affectPosition) {
			}
			if (grant.affectRotation) {
				this.addGrantRotation(bone, parentBone.quaternion, grant.ratio);
			}
		}
		return this;
	}

	public function addGrantRotation(bone:Dynamic, q:Dynamic, ratio:Float):GrantSolver {
		_q.set(0, 0, 0, 1);
		_q.slerp(q, ratio);
		bone.quaternion.multiply(_q);
		return this;
	}

}

static var _q:Dynamic = new Dynamic();