// =================================================================================================
//
//	Starling Framework - Particle System Extension
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package de.flintfabrik.starling.display.FFParticleSystem
{
	public class Frame
    {
		
		public var particleHalfWidth:Number = 1.0;
        public var particleHalfHeight:Number = 1.0;
		public var textureX:Number = 0.0;
        public var textureY:Number = 0.0;
        public var textureWidth:Number = 1.0;
        public var textureHeight:Number = 1.0;
		
		public function Frame(particleWidth:Number = 64, particleHeight:Number = 64, x:Number = 0.0, y:Number = 0.0, width:Number = 64.0, height:Number = 64.0 ) {
			textureX = x/particleWidth;
			textureY = y/particleHeight;
			textureWidth = (x + width)/particleWidth;
			textureHeight = (y + height) / particleHeight;
			particleHalfWidth = (width) >> 1;
			particleHalfHeight = (height) >> 1;
		}
    }
}