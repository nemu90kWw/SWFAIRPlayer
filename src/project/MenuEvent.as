package project 
{
	import flash.display.NativeMenuItem;
	import flash.events.Event;

	public class MenuEvent extends Event
	{
		public static const CHANGE_SPEED:String = "change_speed";
		public static const CHANGE_SCALE:String = "change_scale";
		public static const RENDERING_STATE_CHANGE:String = "rendering_state_change";
		
		public var item:NativeMenuItem;
		
		public function MenuEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, item:NativeMenuItem = null)
		{
			super(type, bubbles, cancelable);
			
			this.item = item;
		}
	}
}