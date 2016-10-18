Shader "Custom/ToonShader" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MainBump ("Bump", 2D) = "bump" {}
		// 该变量主要使用来降低颜色种类的
		_Tooniness ("Tooniness", Range(0.1,20)) = 4
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Lambert finalcolor:final

		sampler2D _MainTex;
		sampler2D _MainBump;
		// 添加_Tooniness的引用
		float _Tooniness;

		struct Input {
			float2 uv_MainTex;
			float2 uv_MainBump;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		
		// 增加的final函数，修改像素的颜色
		void final(Input IN, SurfaceOutput o, inout fixed4 color) {
			color = floor(color * _Tooniness)/_Tooniness;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
