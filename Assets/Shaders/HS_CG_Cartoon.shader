Shader "Custom/HS/Cartoon/HS_CG_Cartoon" {
	Properties 
	{
		_Color("Main Color",color)=(1,1,1,1)//物体的颜色
		_Outline("Thick of Outline",range(0,0.1))=0.02//挤出描边的粗细
		_Factor("Factor",range(0,1))=0.5//挤出多远
		_ToonEffect("Toon Effect",range(0,1))=0.5//卡通化程度（二次元与三次元的交界线）
		_Steps("Steps of toon",range(0,9))=3//色阶层数
	}

	SubShader 
	{
		pass
		{	//处理光照前的pass渲染
			Tags{"LightMode"="Always"}
			Cull Front
			ZWrite On

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float _Outline;
			float _Factor;
			struct v2f 
			{
				float4 pos:SV_POSITION;
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				//计算该点位置朝向
				float3 dir=normalize(v.vertex.xyz);
				//计算法线方向
				float3 dir2=v.normal;
				//计算该点位置朝向和法线方向的点积，通过正负值可以确定是指向还是背离几何中心的，正为背离，负为指向
				float D=dot(dir,dir2);
				//乘上正负值，真正的方向值
				dir=dir*sign(D);
				//把该点位置朝向与法线方向按外部变量_Factor的比重混合，来控制挤出多远
				dir=dir*_Factor+dir2*(1-_Factor);
				//把物体背面的点向外挤出
				v.vertex.xyz+=dir*_Outline;
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				return o;
			}

			float4 frag(v2f i):COLOR
			{
				float4 c=0;
				return c;
			}
			ENDCG
		}//end of pass

		pass
		{	//平行光的的pass渲染
			Tags{"LightMode"="ForwardBase"}
			Cull Back

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _LightColor0;
			float4 _Color;
			float _Steps;
			float _ToonEffect;

			struct v2f 
			{
				float4 pos:SV_POSITION;
				float3 lightDir:TEXCOORD0;
				float3 viewDir:TEXCOORD1;
				float3 normal:TEXCOORD2;
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				//切换到世界坐标
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				o.normal=v.normal;
				o.lightDir=ObjSpaceLightDir(v.vertex);
				o.viewDir=ObjSpaceViewDir(v.vertex);

				return o;
			}

			float4 frag(v2f i):COLOR
			{
				float4 c=1;
				float3 N=normalize(i.normal);
				float3 viewDir=normalize(i.viewDir);
				float3 lightDir=normalize(i.lightDir);
				//求出正常的漫反射颜色
				float diff=max(0,dot(N,i.lightDir));
				//做亮化处理
				diff=(diff+1)/2;
				//使颜色平滑的在[0,1]范围之内
				diff=smoothstep(0,1,diff);
				//把颜色做离散化处理，把diffuse颜色限制在_Steps种（_Steps阶颜色），简化颜色，这样的处理使色阶间能平滑的显示
				float toon=floor(diff*_Steps)/_Steps;
				//根据外部我们可控的卡通化程度值_ToonEffect，调节卡通与现实的比重
				diff=lerp(diff,toon,_ToonEffect);
				//把最终颜色混合
				c=_Color*_LightColor0*(diff);
				return c;
			}
			ENDCG
		}//end of pass

		pass
		{	//附加点光源的pass渲染
			Tags{"LightMode"="ForwardAdd"}
			Blend One One
			Cull Back
			ZWrite Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _LightColor0;
			float4 _Color;
			float _Steps;
			float _ToonEffect;

			struct v2f 
			{
				float4 pos:SV_POSITION;
				float3 lightDir:TEXCOORD0;
				float3 viewDir:TEXCOORD1;
				float3 normal:TEXCOORD2;
			};

			v2f vert (appdata_full v) 
			{
				v2f o;
				//切换到世界坐标
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				o.normal=v.normal;
				o.viewDir=ObjSpaceViewDir(v.vertex);
				o.lightDir=_WorldSpaceLightPos0-v.vertex;

				return o;
			}

			float4 frag(v2f i):COLOR
			{
				float4 c=1;
				float3 N=normalize(i.normal);
				float3 viewDir=normalize(i.viewDir);
				//求出距离光源的距离
				float dist=length(i.lightDir);
				//单位化光源的方向
				float3 lightDir=normalize(i.lightDir);
				//求出正常的漫反射颜色
				float diff=max(0,dot(N,i.lightDir));
				//做亮化处理
				diff=(diff+1)/2;
				//使颜色平滑的在[0,1]范围之内
				diff=smoothstep(0,1,diff);
				//根据距光源的距离求出衰减
				float atten=1/(dist);
				float toon=floor(diff*atten*_Steps)/_Steps;
				diff=lerp(diff,toon,_ToonEffect);

				//求出半角向量
				half3 h = normalize (lightDir + viewDir);
				float nh = max (0, dot (N, h));
				//求出高光强度
				float spec = pow (nh, 32.0);
				//把高光也离散化
				float toonSpec=floor(spec*atten*2)/ 2;
				//调节卡通与现实高光的比重
				spec=lerp(spec,toonSpec,_ToonEffect);

				//求出最终颜色
				c=_Color*_LightColor0*(diff+spec);
				return c;
			}
			ENDCG
		}//end of pass
	}
	FallBack "Diffuse"
}
