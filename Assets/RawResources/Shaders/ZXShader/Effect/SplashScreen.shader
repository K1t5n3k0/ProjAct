Shader "ZXShader/Effect/SplashScreen"
{
    Properties
    {
        [HDR]_COLOR ("Color", Color) = (1,1,1,1)
        [Enum(Never, 0, Color, 1, Alpha, 2)]_SetVertexColor ("SetVertexColor", Float) = 1
    }

    SubShader
    {
        Tags 
        {
            "IgnoreProjector"="True"
            "Queue"="Overlay+1"
            "RenderType"="Overlay"
            "PreviewType"="Plane"
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZTest Always
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 vertexColor : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
            fixed4 _COLOR;
			uniform half _SetVertexColor;
            CBUFFER_END 

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = float4(v.uv * 2 - 1, 0, v.vertex.w);
                o.vertexColor = v.vertexColor;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}
				else if(_SetVertexColor == 2)
				{
					o.vertexColor = pow(o.vertexColor, 0.4545);
				}
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.vertexColor * _COLOR;
            }
            ENDCG
        }
    }
}
