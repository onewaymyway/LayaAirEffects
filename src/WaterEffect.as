package  
{
	import laya.effects.Water;
	import laya.utils.Stat;
	/**
	 * ...
	 * @author ww
	 */
	public class WaterEffect 
	{
		
		public function WaterEffect() 
		{
			Laya.init(1000, 900);
			Stat.show();
			test();
			
		}
		public var water:Water ;
		private function test():void
		{
			 water=new Water();
			water.init(800, 600, 1500);
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