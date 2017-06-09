// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

///	********************
///	作者：		董宇
///	邮箱：		dong_fc@163.com
///	ＱＱ：		9123783
///	--------------------
///	单方向光前表面 + RenderTexture反射 + 屏幕空间折射
///	--------------------
///	版本：		V1.1
///	时间：		2016-01-26
///	内容：		修改
///				1.将LIGHTMAP_ON改为!LIGHTMAP_OFF，避免LIGHTMAP_ON标签不工作的情况
///	--------------------
///	版本：		V1.0
///	时间：		2012-06-15
///	内容：		创建
///	********************

Shader "Custom/HS/Reflection/ReflectGround"
{
	Properties
	{
		_Color			("主颜色",				Color)			=	(1, 1, 1, 1)
		_MainTex		("主贴图",				2D)				=	"white" {}
		_MaskTex		("遮罩贴图",			2D)				=	"white" {}
		_ReflInten		("反射强度",			Float)			=	0.5
		_ReflColor		("反射颜色",			Color)			=	(1, 1, 1, 1)
		_ReflTexture	("反射贴图",			2D)				=	"alpha" {}
	}

	SubShader
	{
		Tags {"Queue"="Geometry" "RenderType"="Opaque" "IgnoreProjector"="False"}
//		Lighting Off
//		Fog {Mode Off}
		Cull Back
		Blend Off
		ZWrite On
		ZTest Lequal
		
		Pass
		{
			Name "BASE"
			
			CGPROGRAM
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			
				uniform			fixed4			_Color;
				uniform			sampler2D		_MainTex;
				uniform			fixed4			_MainTex_ST;
				uniform			sampler2D		_MaskTex;

			struct a2v
			{
				fixed4			vertex			:	POSITION;
				fixed4			texcoord0		:	TEXCOORD0;
#ifndef LIGHTMAP_OFF
				fixed4			texcoord1		:	TEXCOORD1;
#endif
			};

			struct v2f
			{
				fixed4			vertex			:	SV_POSITION;
				fixed2			uv				:	TEXCOORD0;
#ifndef LIGHTMAP_OFF
				fixed2			uvlight			:	TEXCOORD1;
#endif
			};

			v2f vert (a2v i)
			{
				v2f o;

				o.vertex						=	UnityObjectToClipPos(i.vertex);
				o.uv							=	TRANSFORM_TEX(i.texcoord0, _MainTex);
#ifndef LIGHTMAP_OFF
				o.uvlight						=	i.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
#endif
	
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4			lMainCol		=	tex2D(_MainTex, i.uv);
								lMainCol		*=	_Color;
#ifndef LIGHTMAP_OFF
				fixed3			lLightmap		=	DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvlight));
								lMainCol.rgb	*=	lLightmap;
#endif
								
				return lMainCol;
			}
			ENDCG
		}

		Tags {"Queue"="Geometry" "RenderType"="Opaque" "IgnoreProjector"="True"}
//		Lighting Off
//		Fog {Mode Off}
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite On
		ZTest Lequal
		
		Pass
		{
			Name "RTRL"
			
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			
				uniform			sampler2D		_MainTex;
				uniform			fixed4			_MainTex_ST;
				uniform			sampler2D		_MaskTex;
				
				uniform			fixed			_ReflInten;
				uniform			fixed4			_ReflColor;
				uniform			sampler2D		_ReflTexture;

			struct a2v
			{
				fixed4			vertex			:	POSITION;
				fixed4			uv				:	TEXCOORD0;
			};

			struct v2f
			{
				fixed4			vertex			:	SV_POSITION;
				fixed2			uv				:	TEXCOORD0;
				fixed4			oPos			:	TEXCOORD4;
			};

			v2f vert (a2v i)
			{
				v2f o;

				o.vertex						=	UnityObjectToClipPos(i.vertex);
				o.uv							=	TRANSFORM_TEX(i.uv, _MainTex);
				o.oPos							=	i.vertex;
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4			oPos			=	i.oPos;
				fixed4			pPos			=	UnityObjectToClipPos(oPos);
				fixed2			sPos			=	pPos.xy / pPos.w * 0.5 + 0.5;
				fixed2			lUV				=	sPos;
	#if UNITY_ANDROID
								lUV.y			=	1 - lUV.y;
	#endif
				fixed4			lReflCol		=	tex2D(_ReflTexture, lUV);
								lReflCol		*=	_ReflColor;
								lReflCol.a		*=	_ReflInten;
				fixed4			lMaskCol		=	tex2D(_MaskTex, i.uv);
								lReflCol.a		*=	lMaskCol.b;
								
				return lReflCol;
			}
			ENDCG
		}
	}
	Fallback Off
}