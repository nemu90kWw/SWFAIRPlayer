package project 
{
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class SWFData 
	{
		private var bytes:ByteArray;
		
		public var format:String;
		public var version:uint;
		public var fileLength:Number;
		public var frameSize:Rectangle = new Rectangle(0, 0, 550, 400);
		public var frameRate:Number = 12;
		public var frameCount:uint;
		public var backgroundColor:uint = 0xFFFFFF;
		
		public function parse(bytes:ByteArray):void
		{
			this.bytes = bytes;
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			format = bytes.readMultiByte(3, "us-ascii");
			version = bytes.readUnsignedByte();
			fileLength = bytes.readUnsignedInt();
			
			var contentBytes:ByteArray = new ByteArray();
			contentBytes.endian = Endian.LITTLE_ENDIAN;
			bytes.readBytes(contentBytes);
			
			if(format == "CWS") {
				contentBytes.uncompress();
			}
			
			var rectBitLength:uint = contentBytes.readUnsignedByte() >> 3;
			contentBytes.position--;
			
			var rectField:Array = readBits(contentBytes, [5, rectBitLength, rectBitLength, rectBitLength, rectBitLength]);
			frameSize = new Rectangle(0, 0, rectField[2] / 20, rectField[4] / 20);
			
			contentBytes.position++;
			frameRate = contentBytes.readUnsignedByte();
			frameCount = contentBytes.readUnsignedShort();
			
			while(contentBytes.bytesAvailable > 0)
			{
				var recordHeader:uint = contentBytes.readUnsignedShort();
				var tagCode:uint = recordHeader >> 6;
				var bodyLength:uint = recordHeader & 0x3F;
				
				//SetBackgroundColor
				if(tagCode == 9)
				{
					var r:uint = contentBytes.readUnsignedByte();
					var g:uint = contentBytes.readUnsignedByte();
					var b:uint = contentBytes.readUnsignedByte();
					backgroundColor = (r << 16) + (g << 8) + b;
					break;
				}
				
				contentBytes.position += bodyLength;
			}
		}
		
		private function readBits(bytes:ByteArray, readLengthList:Array):Array
		{
			var results:Array = new Array();
			
			var i:int = 0;
			var byteLength:uint = 0;
			var bitIndex:int = 0;
			var params:Array = new Array();
			
			for each(i in readLengthList) {
				byteLength += i;
			}
			byteLength = Math.ceil(byteLength / 8);
			
			for(i = 0; i < byteLength; i++) {
				params.push(bytes.readUnsignedByte());
			}
			
			for(i = 0; i < readLengthList.length; i++)
			{
				results.push(0);
				for(var remain:int = readLengthList[i]; remain > 0; remain--)
				{
					results[i] = (results[i] << 1) + (params[Math.floor(bitIndex / 8)] & 128 >> (bitIndex % 8) ? 1 : 0);
					bitIndex++;
				}
			}
			
			return results;
		}
	}
}