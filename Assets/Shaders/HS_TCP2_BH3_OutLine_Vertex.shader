// Toony Colors Pro+Mobile 2
// (c) 2014-2016 Jean Moreno

Shader "Custom/HS/Cartoon/HS_TCP2_BH3_OutLine_Vertex"
{
	Properties
	{
		//TOONY COLORS
		_Color ("Color", Color) = (0.5,0.5,0.5,1.0)
		_HColor ("Highlight Color", Color) = (0.6,0.6,0.6,1.0)
		_SColor ("Black Shadow Color", Color) = (0.3,0.3,0.3,1.0)
		_SSColor("Red Shadow Color", Color) = (0.3, 0.3, 0.3,1.0)
		
		//DIFFUSE
		_MainTex ("Main Texture (RGB)", 2D) = "white" {}
		_Mask1 ("Mask 1 (Specular)", 2D) = "black" {}
		
		//TOONY COLORS RAMP
		_RampThreshold ("#RAMPF# Ramp Threshold", Range(0,1)) = 0.5
		_RampSmooth ("#RAMPF# Ramp Smoothing", Range(0.001,1)) = 0.1
		
		//SPECULAR
		_SpecColor ("#SPEC# Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("#SPEC# Shininess", Range(0.0,2)) = 0.1
		_SpecSmooth ("#SPECT# Smoothness", Range(0,1)) = 0.05
		
		//OUTLINE
		_OutlineColor ("#OUTLINE# Outline Color", Color) = (0.2, 0.2, 0.2, 1.0)
		_Outline ("#OUTLINE# Outline Width", Range(0,2)) = 1
		
		//Outline Textured
		//_TexLod ("#OUTLINETEX# Texture LOD", Range(0,10)) = 5
		
		//ZSmooth
		_ZSmooth ("#OUTLINEZ# Z Correction", Range(-3.0,3.0)) = -0.5
		
		//Z Offset
		_Offset1 ("#OUTLINEZ# Z Offset 1", Float) = 0
		_Offset2 ("#OUTLINEZ# Z Offset 2", Float) = 0		
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		
		//描边使用两个Pass，第一个pass沿法线挤出一点，只输出描边的颜色  
		Pass
		{
			//剔除正面，只渲染背面，对于大多数模型适用，不过如果需要背面的，就有问题了  
			Cull Front
			Offset[_Offset1],[_Offset2]

			CGPROGRAM
			#include "UnityCG.cginc"  
			fixed4 _OutlineColor;
			float _Outline;
			float _ZSmooth;

			//使用vert函数和frag函数  
			#pragma vertex vert  
			#pragma fragment frag  

			struct v2f
			{
				float4 pos : SV_POSITION;
			};

			v2f vert(appdata_full v)
			{
				v2f o;
				float4 pos = mul( UNITY_MATRIX_MV, v.vertex);
				float3 normal = mul( (float3x3)UNITY_MATRIX_IT_MV, v.normal);
				normal.z = -_ZSmooth;

				float width =  _Outline * 0.01 * (1.0 - v.color.b);
				pos = pos + float4(normalize(normal),0) * width;
				o.pos = mul(UNITY_MATRIX_P, pos);

				/*if(v.color.b < 0.5)
					o.pos.xy += offset * _Outline;*/
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//这个Pass直接输出描边颜色  
				return _OutlineColor;
			}
			ENDCG
		}

		CGPROGRAM
		
		#pragma surface surf ToonyColorsCustom vertex:vert
		#pragma target 3.0
		#pragma glsl
		
		#pragma multi_compile TCP2_SPEC_TOON
		
		//================================================================
		// VARIABLES
		
		fixed4 _Color;
		sampler2D _MainTex;
		sampler2D _Mask1;
		
		fixed _Shininess;
		
		struct Input
		{
			half2 uv_MainTex;
			float4 vertColor;
		};
		
		//================================================================
		// CUSTOM LIGHTING
		
		//Lighting-related variables
		fixed4 _HColor;
		fixed4 _SColor;
		fixed4 _SSColor;
		float _RampThreshold;
		float _RampSmooth;
		fixed _SpecSmooth;
		
		//Custom SurfaceOutput
		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			half Specular;
			fixed Gloss;
			fixed Alpha;
			fixed TexThreshold;
			fixed3 VertColor;
		};
		
		inline half4 LightingToonyColorsCustom (inout SurfaceOutputCustom s, half3 lightDir, half3 viewDir, half atten)
		{
			s.Normal = normalize(s.Normal);
			fixed ndl = max(0, dot(s.Normal, lightDir)*0.5 + 0.5);
			
			ndl += s.TexThreshold;
			fixed3 ramp = smoothstep(_RampThreshold-_RampSmooth*0.5, _RampThreshold+_RampSmooth*0.5, ndl);
		#if !(POINT) && !(SPOT)
			ramp *= atten;
		#endif
			
			//Shadows intensity through alpha
			_SColor = lerp(_HColor, _SColor, _SColor.a);

			//If the b channel of vertex color is 0.0, we use _SColor to compute shadow color
			//else the b channel of vertex color is 1.0, we use _SSColor to compute shadow color
			if(s.VertColor.r > 0.5)
				ramp = lerp(_SSColor.rgb, _HColor.rgb, ramp);
			else
				ramp = lerp(_SColor.rgb, _HColor.rgb, ramp);
			
			//Specular
			half3 h = normalize(lightDir + viewDir);
			float ndh = max(0, dot (s.Normal, h));
			float spec = pow(ndh, s.Specular*128.0) * s.Gloss * 2.0;
			spec = smoothstep(0.5-_SpecSmooth*0.5, 0.5+_SpecSmooth*0.5, spec);
			spec *= atten;
			fixed4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * ramp;
		#if (POINT || SPOT)
			c.rgb *= atten;
		#endif
			c.rgb += _LightColor0.rgb * _SpecColor.rgb * spec;
			c.a = s.Alpha + _LightColor0.a * _SpecColor.a * spec;
			return c;
		}
				
		//================================================================

		void vert(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertColor = v.color;
		}

		// SURFACE FUNCTION		
		void surf (Input IN, inout SurfaceOutputCustom o)
		{
			fixed4 mainTex = tex2D(_MainTex, IN.uv_MainTex);
			
			fixed4 mask1 = tex2D(_Mask1, IN.uv_MainTex);
			o.Albedo = mainTex.rgb * _Color.rgb;
			o.Alpha = mainTex.a * _Color.a;
			
			//Specular
			o.Gloss = mask1.b;
			o.Specular = _Shininess;

			//TEXTURED THRESHOLD
			o.TexThreshold = mask1.g - 0.5;

			o.VertColor = IN.vertColor;
		}
		
		ENDCG
		
		//Outlines
		//UsePass "Hidden/Toony Colors Pro 2/Outline Only/OUTLINE"
	}
	
	Fallback "Diffuse"
	//CustomEditor "TCP2_MaterialInspector"
}
