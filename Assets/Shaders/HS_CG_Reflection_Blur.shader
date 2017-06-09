// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

/// ********************
/// 作者：		董宇
/// 邮箱：		dong_fc@163.com
/// ＱＱ：		9123783
/// --------------------
/// Outline专用，模糊Shader
/// --------------------
/// 版本：		V1.0
/// 时间：		2015-09-06
/// 内容：		创建
/// ********************

Shader "Custom/HS/Reflection/Blur"
{
	Properties
	{
		_MainTex		("主贴图",				2D)				=	"white" {}
	}

	SubShader
	{
		Cull Off
		ZWrite Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			
			#include "UnityCG.cginc"
			
			uniform			sampler2D		_MainTex;
			uniform			fixed4			_Offset;
								
			struct a2v
			{
				fixed4			vertex			:	POSITION;
				float2			uv				:	TEXCOORD0;
			};

			struct v2f
			{
				float4			vertex			:	SV_POSITION;
				float2			uv				:	TEXCOORD0;
			};

			v2f vert (a2v i)
			{
				v2f o;
				o.vertex						=	UnityObjectToClipPos(i.vertex);
				o.uv							=	i.uv;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4	lMainTex0				=	tex2D(_MainTex, i.uv);
				fixed4	lMainTex1				=	tex2D(_MainTex, i.uv + fixed2( 1,  1) * _Offset.xy);
				fixed4	lMainTex2				=	tex2D(_MainTex, i.uv + fixed2(-1, -1) * _Offset.xy);
				fixed4	lMainTex3				=	tex2D(_MainTex, i.uv + fixed2( 2,  2) * _Offset.xy);
				fixed4	lMainTex4				=	tex2D(_MainTex, i.uv + fixed2(-2, -2) * _Offset.xy);
				fixed4	lMainTex5				=	tex2D(_MainTex, i.uv + fixed2( 3,  3) * _Offset.xy);
				fixed4	lMainTex6				=	tex2D(_MainTex, i.uv + fixed2(-3, -3) * _Offset.xy);
				fixed4	lColor;
						lColor.rgb				=	lMainTex0.rgb * lMainTex0.a * 0.40;
						lColor.rgb				+=	lMainTex1.rgb * lMainTex1.a * 0.15;
						lColor.rgb				+=	lMainTex2.rgb * lMainTex2.a * 0.15;
						lColor.rgb				+=	lMainTex3.rgb * lMainTex3.a * 0.10;
						lColor.rgb				+=	lMainTex4.rgb * lMainTex4.a * 0.10;
						lColor.rgb				+=	lMainTex5.rgb * lMainTex5.a * 0.05;
						lColor.rgb				+=	lMainTex6.rgb * lMainTex6.a * 0.05;
						lColor.a				=	lMainTex0.a * 0.40;
						lColor.a				+=	lMainTex1.a * 0.15;
						lColor.a				+=	lMainTex2.a * 0.15;
						lColor.a				+=	lMainTex3.a * 0.10;
						lColor.a				+=	lMainTex4.a * 0.10;
						lColor.a				+=	lMainTex5.a * 0.05;
						lColor.a				+=	lMainTex6.a * 0.05;
						lColor.rgb				/=	lColor.a;
				return lColor;
			}
			ENDCG
		}
	}
}
