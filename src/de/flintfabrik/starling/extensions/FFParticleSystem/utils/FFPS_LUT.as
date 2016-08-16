// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.extensions.FFParticleSystem.utils
{
    public class FFPS_LUT
    {
		
		public static var cos:Vector.<Number> = new Vector.<Number>(0x800, true);
		public static var sin:Vector.<Number> = new Vector.<Number>(0x800, true);
		private static var initialized:Boolean = false;
        
		/**
		 * Creats look up tables for sin and cos, to reduce function calls.
		 */
		public static function init():void
		{
			//run once
			if(!initialized){
				for (var i:int = 0; i < 0x800; ++i)
				{
					cos[i & 0x7FF] = Math.cos(i * 0.00306796157577128245943617517898); // 0.003067 = 2PI/2048
					sin[i & 0x7FF] = Math.sin(i * 0.00306796157577128245943617517898);
				}
				initialized = true;
			}
		}
		
        
    }
}
