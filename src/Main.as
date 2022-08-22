package
{
	import flash.desktop.NativeApplication;
	import flash.display.Screen;
	import flash.display.Sprite;
	import flash.events.InvokeEvent;
	import flash.text.TextField;
	
	public class Main extends Sprite 
	{
		public function Main() 
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
		}
		
		private function onInvoke(e:InvokeEvent):void
		{
			var text:TextField = new TextField();
			text.width = Screen.mainScreen.bounds.width;
			text.height = Screen.mainScreen.bounds.height;
			for each(var t:String in e.arguments)
			{
				text.text += t+"\n";
			}
			addChild(text);
		}
	}
}