package laya.effects {
	import laya.display.Graphics;
	import laya.display.Sprite;
	import laya.resource.Texture;
	
	/**
	 * ...
	 * @author ww
	 */
	public class Water extends Sprite {
		
		public function Water() {
		
		}
		
		public var gridResolution:int = 20;
		public var rad:int = 30;
		public var maxParticles:int = 1000;
		/* ==== the RAM ==== */
		public var nBytes:int;
		public var buffer:ArrayBuffer;
		public var particles_x:Float32Array ;
		public var particles_y:Float32Array;
		public var particles_pprevx:Float32Array;
		public var particles_pprevy:Float32Array;
		public var particles_velx:Float32Array;
		public var particles_vely:Float32Array;
		public var particles_vxl:Float32Array;
		public var particles_vyl:Float32Array;
		public var particles_q:Float32Array;
		public var grid = [];
		public var neighbors = [];
		public var nParticles = 0;
		// ==== screen ====
		
		public var nbX:int;
		public var nbY:int;
		
		public var worldWidth:int;
		public var worldHeight:int;
		
		var r1:Number = rad * 1.5;
		var r2:Number = r1 * 0.15;
		
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
		

		
		// ==== create image particle ====
		
		public function pass1(n) {
			var px:int = particles_x[n];
			var py:int = particles_y[n];
			// ==== maintain spatial hashing grid ====
			var g:Cell = grid[((0.5 + py / gridResolution) | 0) * nbX + ((0.5 + px / gridResolution) | 0)];
			g.neighborsParticles[g.len++] = n;
			// ==== mouse pressed ====
			if (true) {
				var vx = px - this.mouseX;
				var vy = py - this.mouseY;
				var vlen = Math.sqrt(vx * vx + vy * vy);
				if (vlen >= 1 && vlen < 80) {
					//particles_velx[n] -= 0.5 * rad * (vx / vlen) / vlen;
					//particles_vely[n] -= 0.5 * rad * (vy / vlen) / vlen;
					//particles_vely[n] -= 0.5 * rad * (vx / vlen) / vlen;
					//particles_velx[n] -= 0.5 * rad * (vy / vlen) / vlen;
					particles_vely[n] -= 4*gravityY;
					particles_velx[n] -= 4*gravityX;
				}
				if(vlen>80&&vlen<120)
				{
					vlen=60
					//particles_velx[n] += 0.5 * rad * (vx / vlen) / vlen;
					//particles_vely[n] += 0.5 * rad * (vy / vlen) / vlen;
				}
			}
			// ==== apply gravity ====
			particles_vely[n] += gravityY;
			particles_velx[n] += gravityX;
			// ==== save previous position ====
			particles_pprevx[n] = px;
			particles_pprevy[n] = py;
			// ==== advance to predicted position ====
			particles_x[n] += particles_velx[n];
			particles_y[n] += particles_vely[n];
		}
		public var gravityY:Number = 0.01;
		public var gravityX:Number = 0.05;
		// ==== Double Density Relaxation Algorithm ====
		public function pass2(n) {
			var px:Number = particles_x[n];
			var py:Number = particles_y[n];
			var pressure :Number= 0, presnear:Number = 0, nl:Number = 0;
			// ----- get grid position -----
			var xc:Number = (0.5 + px / gridResolution) | 0;
			var yc:Number = (0.5 + py / gridResolution) | 0;
			// ----- 3 x 3 grid cells -----
			for (var xd:int = -1; xd < 2; xd++) {
				for (var yd:int = -1; yd < 2; yd++) {
					var h:Cell = grid[(yc + yd) * nbX + (xc + xd)];
					if (h && h.len) {
						// ==== for each neighbours pair ====
						for (var a = 0, l = h.len; a < l; a++) {
							var pn = h.neighborsParticles[a];
							if (pn != n) {
								var vx:Number = particles_x[pn] - px;
								var vy:Number = particles_y[pn] - py;
								var vlen:Number = Math.sqrt(vx * vx + vy * vy);
								if (vlen < rad) {
									// ==== compute density and near-density ====
									var q:Number = 1 - (vlen / rad);
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
			var q:Number;
			if (px < r2) {
				q = 1 - Math.abs(px / r2);
				particles_x[n] += q * q * 0.5;
			}
			else if (px > worldWidth - r2) {
				q = 1 - Math.abs((worldWidth - px) / r2);
				particles_x[n] -= q * q * 0.5;
			}
			if (py < r2) {
				q = 1 - Math.abs(py / r2);
				particles_y[n] += q * q * 0.5;
			}
			else if (py > worldHeight - r2) {
				q = 1 - Math.abs((worldHeight - py) / r2);
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
			for (var a:int = 0; a < nl; a++) {
				var np:int = neighbors[a];
				// ==== apply displacements ====
				var p:Number = pressure + presnear * particles_q[np];
				var dx:Number = (particles_vxl[np] * p) * 0.5;
				var dy:Number = (particles_vyl[np] * p) * 0.5;
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
		public var tex:Texture;
		// ==== main loop ====
		public function run() {
			var i:int, l:int;
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
			var len:int;
			len = nParticles;
			for (i = 0; i < len; i++) {
				//g.drawCircle(particles_x[i] - r1, particles_y[i] - r1, 5, "#ff0000");
				g.drawTexture(tex, particles_x[i] - r1, particles_y[i] - r1);
			}
		}
	}

}