package  
{
	import laya.effects.Water;
	import laya.net.Loader;
	import laya.utils.Handler;
	import laya.utils.Stat;
	import laya.webgl.WebGL;
	/**
	 * ...
	 * @author ww
	 */
	public class WaterEffect 
	{
		
		public function WaterEffect() 
		{
			WebGL.enable();
			Laya.init(1000, 900);
			Stat.show();
			test();
			Laya.loader.load("res/ball.png", new Handler(this, test));
		}
		public var water:Water ;
		private function test():void
		{
			 water = new Water();
			 water.tex = Loader.getRes("res/ball.png");
			//water.init(800, 600, 1500);
			water.init(800, 600, 2000);
			water.pos(100, 100);
			Laya.stage.addChild(water);
			Laya.timer.frameLoop(1, this, updateLoop);
		}
		private function updateLoop():void
		{
			water.run();
		}
	}

}