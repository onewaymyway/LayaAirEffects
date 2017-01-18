package laya.effects {
	import laya.display.Graphics;
	import laya.display.Sprite;
	
	/**
	 * ...
	 * @author ww
	 */
	public class Water extends Sprite {
		
		public function Water() {
		
		}
		
		public var gridResolution = 20;
		public var rad = 30;
		public var maxParticles = 1000;
		/* ==== the RAM ==== */
		public var nBytes;
		public var buffer;
		public var particles_x ;
		public var particles_y;
		public var particles_pprevx;
		public var particles_pprevy;
		public var particles_velx;
		public var particles_vely;
		public var particles_vxl;
		public var particles_vyl;
		public var particles_q;
		public var grid = [];
		public var neighbors = [];
		public var nParticles = 0;
		// ==== screen ====
		
		public var nbX;
		public var nbY;
		
		public var worldWidth:int;
		public var worldHeight:int;
		
		var r1 = rad * 1.5;
		var r2 = r1 * 0.15;
		
		public function init(worldWidth:int, worldHeight:int, count:int = 1000):void {
			this.worldWidth = worldWidth;
			this.worldHeight = worldHeight;
			this.maxParticles = count;
			initBuffers();
			nbX = Math.round(worldWidth / gridResolution) + 1;
			nbY = Math.round(worldHeight / gridResolution) + 1;
			// ==== build grid ====
			for (var i = 0; i < nbX * nbY; i++) {
				grid[i] = new Cell();
			}
		}
		
		private function initBuffers():void {
			nBytes = 4 * maxParticles;
			buffer = new ArrayBuffer(10 * nBytes);
			particles_x = new Float32Array(buffer, 0 * nBytes, maxParticles);
			particles_y = new Float32Array(buffer, 1 * nBytes, maxParticles);
			particles_pprevx = new Float32Array(buffer, 2 * nBytes, maxParticles);
			particles_pprevy = new Float32Array(buffer, 3 * nBytes, maxParticles);
			particles_velx = new Float32Array(buffer, 4 * nBytes, maxParticles);
			particles_vely = new Float32Array(buffer, 5 * nBytes, maxParticles);
			particles_vxl = new Float32Array(buffer, 6 * nBytes, maxParticles);
			particles_vyl = new Float32Array(buffer, 7 * nBytes, maxParticles);
			particles_q = new Float32Array(buffer, 8 * nBytes, maxParticles);
		}
		
		// ==== cell constructor ====
		public function Cell() {
			this.len = 0;
			this.neighborsParticles = [];
		}
		
		// ==== create image particle ====
		
		public function pass1(n) {
			var px = particles_x[n];
			var py = particles_y[n];
			// ==== maintain spatial hashing grid ====
			var g = grid[((0.5 + py / gridResolution) | 0) * nbX + ((0.5 + px / gridResolution) | 0)];
			g.neighborsParticles[g.len++] = n;
			// ==== mouse pressed ====
			if (true) {
				var vx = px - this.mouseX;
				var vy = py - this.mouseY;
				var vlen = Math.sqrt(vx * vx + vy * vy);
				if (vlen >= 1 && vlen < 80) {
					particles_velx[n] += 0.5 * rad * (vx / vlen) / vlen;
					particles_vely[n] += 0.5 * rad * (vy / vlen) / vlen;
				}
			}
			// ==== apply gravity ====
			particles_vely[n] += 0.01;
			// ==== save previous position ====
			particles_pprevx[n] = px;
			particles_pprevy[n] = py;
			// ==== advance to predicted position ====
			particles_x[n] += particles_velx[n];
			particles_y[n] += particles_vely[n];
		}
		
		// ==== Double Density Relaxation Algorithm ====
		public function pass2(n) {
			var px = particles_x[n];
			var py = particles_y[n];
			var pressure = 0, presnear = 0, nl = 0;
			// ----- get grid position -----
			var xc = (0.5 + px / gridResolution) | 0;
			var yc = (0.5 + py / gridResolution) | 0;
			// ----- 3 x 3 grid cells -----
			for (var xd = -1; xd < 2; xd++) {
				for (var yd = -1; yd < 2; yd++) {
					var h = grid[(yc + yd) * nbX + (xc + xd)];
					if (h && h.len) {
						// ==== for each neighbours pair ====
						for (var a = 0, l = h.len; a < l; a++) {
							var pn = h.neighborsParticles[a];
							if (pn != n) {
								var vx = particles_x[pn] - px;
								var vy = particles_y[pn] - py;
								var vlen = Math.sqrt(vx * vx + vy * vy);
								if (vlen < rad) {
									// ==== compute density and near-density ====
									var q = 1 - (vlen / rad);
									pressure += q * q; // quadratic spike
									presnear += q * q * q; // cubic spike
									particles_q[pn] = q;
									particles_vxl[pn] = (vx / vlen) * q;
									particles_vyl[pn] = (vy / vlen) * q;
									neighbors[nl++] = pn;
								}
							}
						}
					}
				}
			}
			// ==== screen limits ====
			if (px < r2) {
				var q = 1 - Math.abs(px / r2);
				particles_x[n] += q * q * 0.5;
			}
			else if (px > worldWidth - r2) {
				var q = 1 - Math.abs((worldWidth - px) / r2);
				particles_x[n] -= q * q * 0.5;
			}
			if (py < r2) {
				var q = 1 - Math.abs(py / r2);
				particles_y[n] += q * q * 0.5;
			}
			else if (py > worldHeight - r2) {
				var q = 1 - Math.abs((worldHeight - py) / r2);
				particles_y[n] -= q * q * 0.5;
			}
			if (px < r2)
				particles_x[n] = r2;
			else if (px > worldWidth - r2)
				particles_x[n] = worldWidth - r2;
			if (py < r2)
				particles_y[n] = r2;
			else if (py > worldHeight - r2)
				particles_y[n] = worldHeight - r2;
			// ==== second pass of the relaxation ====
			pressure = (pressure - 3) * 0.5;
			presnear *= 0.5;
			for (var a = 0; a < nl; a++) {
				var np = neighbors[a];
				// ==== apply displacements ====
				var p = pressure + presnear * particles_q[np];
				var dx = (particles_vxl[np] * p) * 0.5;
				var dy = (particles_vyl[np] * p) * 0.5;
				particles_x[np] += dx;
				particles_y[np] += dy;
				particles_x[n] -= dx;
				particles_y[n] -= dy;
			}
		}
		
		public function pass3(n) {
			// ==== use previous position to compute next velocity ====
			particles_velx[n] = particles_x[n] - particles_pprevx[n];
			particles_vely[n] = particles_y[n] - particles_pprevy[n];
			// ==== draw particle ====
			//ctx.drawImage(particleImage, particles_x[n] - r1, particles_y[n] - r1);
		}
		
		// ==== main loop ====
		public function run() {
			var i, l;
			// ==== inject new particles ====
			if (nParticles < maxParticles) {
				particles_x[nParticles] = 0.5 * worldWidth + Math.random();
				particles_y[nParticles] = 0.5 * worldHeight + Math.random();
				nParticles++;
			}
			
			// ==== reset grid ====
			for (i = 0, l = nbX * nbY; i < l; i++)
				grid[i].len = 0;
			// ==== simulation passes ====
			for (i = 0; i < nParticles; i++)
				pass1(i);
			for (i = 0; i < nParticles; i++)
				pass2(i);
			for (i = 0; i < nParticles; i++)
				pass3(i);
			
			var g:Graphics = this.graphics;
			g.clear();
			var i:int, len:int;
			len = nParticles;
			for (i = 0; i < len; i++) {
				g.drawCircle(particles_x[i] - r1, particles_y[i] - r1, 5, "#ff0000");
			}
		}
	}

}