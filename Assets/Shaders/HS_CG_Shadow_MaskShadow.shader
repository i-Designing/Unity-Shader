Shader "Custom/HS/Shadow/MaskShadow" 
{
    Properties 
    {
	 
    }
   
    SubShader 
    {    
        Tags 
        { 
            "LightMode" = "ForwardBase"
            "RenderType"="Transparent" 
            "IgnoreProjector"="True"
            "Queue" = "Transparent+9" 
        }
    
        Pass 
        {            
            Offset -1.0, -3.0
            ColorMask 0
            ZTest on
      		
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
         	
            float4 vert(appdata_base v) : POSITION 
            {
                return mul (UNITY_MATRIX_MVP, v.vertex);
            }

            fixed4 frag(float4 sp:WPOS) : COLOR {
                return fixed4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
}