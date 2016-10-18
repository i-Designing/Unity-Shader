Shader "Custom/HS/HS_Toon" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Bump ("Bump", 2D) = "bump" {}
		_Tooniness ("Tooniness", Range(0.1,20)) = 4
		_Outline ("Outline", Range(0,1)) = 0.4
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Lambert finalcolor:final

		sampler2D _MainTex;
		sampler2D _Bump;
		float _Tooniness;
		float _Outline;

		struct Input {
			float2 uv_MainTex;
			float2 uv_Bump;
			float3 viewDir;
		};

		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			half4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Normal = UnpackNormal( tex2D(_Bump, IN.uv_Bump));
			
			half edge = saturate(dot (o.Normal, normalize(IN.viewDir)));   
            edge = edge < _Outline ? edge/4 : 1; 
			
			o.Albedo = c.rgb * edge;
			o.Alpha = c.a;
		}
		
		void final(Input IN, SurfaceOutput o, inout fixed4 color) {
            color = floor(color * _Tooniness)/_Tooniness;
        }
		ENDCG
	} 
	FallBack "Diffuse"
}
