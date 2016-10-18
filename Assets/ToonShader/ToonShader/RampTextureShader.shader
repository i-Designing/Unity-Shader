Shader "Custom/RampTextureShader" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_MainBump ("Bump", 2D) = "bump" {}
		// 该变量主要使用来降低颜色种类的
		_Tooniness ("Tooniness", Range(0.1,20)) = 4
		_ColorMerge ("ColorMerge", Range(0.1,20)) = 8
		// 使用ramp texture
		_Ramp ("Ramp Texture", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf Toon

		sampler2D _MainTex;
		sampler2D _MainBump;
		// 添加_Tooniness的引用
		float _Tooniness;
		// 添加_ColorMerge的引用
		float _ColorMerge;
		// 添加_Ramp的引用
		sampler2D _Ramp;

		struct Input {
			float2 uv_MainTex;
			float2 uv_MainBump; 
		};

		void surf (Input IN, inout SurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal( tex2D(_MainBump, IN.uv_MainBump));
			o.Albedo = floor(c.rgb*_ColorMerge)/_ColorMerge;
			o.Alpha = c.a;
		}
		
		half4 LightingToon(SurfaceOutput s, half3 lightDir, half atten) {
			half4 c;
			half NdotL = dot(s.Normal, lightDir);
			NdotL = saturate(tex2D(_Ramp, float2(NdotL,0.5)));
			
			c.rgb = s.Albedo * _LightColor0.rgb * NdotL * atten * 2;
			c.a = s.Alpha;
			return c;
		}
		
		ENDCG
	} 
	FallBack "Diffuse"
}
