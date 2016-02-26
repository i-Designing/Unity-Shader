Shader "Custom/Diffuse Color" {
	Properties {  
        _EmissiveColor ("Emissive Color", Color) = (1,1,1,1)  
        _AmbientColor  ("Ambient Color", Color) = (1,1,1,1)  
        _MySliderValue ("This is a Slider", Range(0,10)) = 2.5  
    }
	
    SubShader {
      Tags { "RenderType" = "Opaque" }
      CGPROGRAM
      #pragma surface surf Lambert
	  
	  float4 _EmissiveColor;  
      float4 _AmbientColor;  
      float _MySliderValue; 
		
      struct Input {
          float4 color : COLOR;
      };
	  
      void surf (Input IN, inout SurfaceOutput o) {
          //We can then use the properties values in our shader  
          float4 c;  
          c =  pow((_EmissiveColor + _AmbientColor), _MySliderValue);  
          o.Albedo = c.rgb;  
          o.Alpha = c.a; 
      }
      ENDCG
    }
    Fallback "Diffuse"
}