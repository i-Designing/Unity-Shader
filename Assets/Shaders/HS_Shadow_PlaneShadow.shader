// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/HS/PlaneShadow"
{
    Properties
    {
		_ShadowColor ("Shadow Color", Color) = (0,0,0,1)
    }
    
    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode" = "ForwardBase"
                "RenderType"="Transparent"
                "Queue" = "Transparent+10"        
            }
               
            ZTest on             
            Blend SrcAlpha OneMinusSrcAlpha
            Offset -3.0, -1.0
                             
            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Replace
                Fail Keep
                ZFail Keep
                ReadMask 1
                WriteMask 1
            }
             
            CGPROGRAM
 
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
 
            #include "UnityCG.cginc"
 
            uniform float4x4 worldToShadow; //will be set by a script
            uniform fixed4 _ShadowColor;
              
            float4 vert(appdata_base v) : POSITION
            {
                float4 posW = mul(unity_ObjectToWorld, v.vertex);
                float4 posWS = mul(worldToShadow, posW);
                return mul (UNITY_MATRIX_VP, posWS);
            }
 
            fixed4 frag(float4 sp:WPOS) : COLOR {                
                return _ShadowColor;
            }
 
            ENDCG
        }// Pass        
    } // SubShader    
} // Shader