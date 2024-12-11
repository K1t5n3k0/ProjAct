// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ZXShader/Effect/Trail"
{
    Properties
    {
        [Label(Trail)]
        [Popup(AlphaBlend, 10, Additive, 1)] _DstBlend ("混合模式", Int) = 10
        [Popup(LessEqual, 4, Always, 8)] _ZTest("深度测试", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("裁剪方式", Int) = 0

		[Space]_MainTex ("拖尾贴图", 2D) = "white" {}

        [Indent_add]
        [HDR]_COLOR ("颜色", Color) = (1, 1, 1, 1)
        _MainRotation ("旋转", Range(0, 360)) = 0
        _Saturation ("饱和度", Range(0, 1)) = 1
        _MoveDirection("移动方向", Vector) = (1,0,0,0)
        _Strength ("拉伸", Range(0, 3)) = 0
        [AlphaChannel]_AlphaChannel ("透明通道", Vector) = (0,0,0,1)
        [Indent_sub]

        _UVOffset ("主纹理UV偏移(XY)", Vector) = (0,0,0,0)

        [Popup(Zero,0,One,1,Two,2)][Keyword(USE_MASK,1,USE_DOUBLE_MASK,2)] __MaskMode ("遮罩模式", Float) = 0
        [HideBy(__MaskMode, 1)]_MaskTex ("遮罩贴图", 2D) = "white" {}

        [indent_add]
        [AlphaChannel(__MaskMode, 1)]_MaskChannel ("透明通道", Vector) = (1,0,0,0)
        _MaskStrength ("遮罩强度", Float ) = 0
        [HideBy(__MaskMode, 1)]_MaskRotation ("旋转", Range(0, 360)) = 0
        [indent_sub]

        [HideBy(__MaskMode, 2)]_Mask2Tex ("溶解贴图", 2D) = "white" {}

        [indent_add]
        [HideBy(__MaskMode, 2)]_Mask2Strength ("溶解强度", Float) = 0
        [indent_sub]

		[HideBy(__MaskMode, 1)]_UV2Offset ("遮罩和溶解UV偏移", Vector) = (0,0,0,0)

        [Space][Toggle(USE_NOISE)]_UseNoise("开启扰乱", Float) = 0
        [HideBy(_UseNoise, 1)]_NoiseTex ("噪声贴图", 2D) = "black" {}
        [HideBy(_UseNoise, 1)]_NoiseParam ("扰乱强度和UV偏移", Vector ) = (0,0,0,0)

        [Enum(Never, 0, Color, 1, Alpha, 2)]_SetVertexColor ("SetVertexColor", Float) = 1
    }
    SubShader
    {
        Tags 
        { 
		    "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "DisableBatching" = "True"
        }

            LOD 100
		
			Blend SrcAlpha [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTest]
            ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "CGIncludes/ParticleCg.cginc"
            


			#pragma multi_compile_local __ USE_MASK USE_DOUBLE_MASK
			#pragma multi_compile_local __ USE_NOISE

        CBUFFER_START(UnityPerMaterial)
			//Main
			sampler2D _MainTex;
			float4 _MainTex_ST;

			uniform fixed4 _COLOR;
			uniform fixed  _Saturation;
			uniform half _MainRotation;

			uniform fixed4 _AlphaChannel;
            uniform half4  _UVOffset;
            uniform half4  _UV2Offset;
			uniform half _SetVertexColor;

            //Mask
            uniform sampler2D   _MaskTex;
            uniform float4      _MaskTex_ST;
            uniform fixed4      _MaskChannel;
			uniform half        _MaskRotation;
			//Dissolve
			uniform sampler2D   _Mask2Tex;
            uniform float4      _Mask2Tex_ST;
            uniform fixed      _Mask2Strength;
			uniform fixed       _MaskStrength;

			//Noise
			uniform sampler2D   _NoiseTex;
            uniform float4      _NoiseTex_ST;
            half4       _NoiseParam;

            float _Strength;
            float3 _MoveDirection;
            float _Rotation;

        CBUFFER_END 

			struct a2v 
            {
				float4 vertex : POSITION;
                half4 vertexColor : COLOR;
				float2 uv : TEXCOORD0;
			};

			struct v2f 
            {
				float4 vertex : SV_POSITION;
                half4 vertexColor : COLOR;

			#if defined(USE_NOISE)
				half4 uv : TEXCOORD0;//main noise
            #else
                half2 uv : TEXCOORD0;//main noise
			#endif

			#if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
				half4 uv2 : TEXCOORD1;//mask dissolve
			#endif 

			};

            v2f vert (a2v v)
            {
                v2f o;
   
                o.vertexColor = v.vertexColor * _COLOR;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}
				else if(_SetVertexColor == 2)
				{
					o.vertexColor = pow(o.vertexColor, 0.4545);
				}

                o.uv = v.uv.xyxy;

                //广告牌
				// float3 normalDir = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				// normalDir.x = 0;
				// normalDir = normalize(normalDir);

				// float3 rightDir =  half3(1, 0, 0);
				// float3 upDir = normalize(cross(rightDir, normalDir));
				// rightDir = normalize(cross(normalDir, upDir));

                // float3x3 billboardMatrix = float3x3(rightDir, upDir, normalDir);
				// float3 localPos = mul(billboardMatrix, v.vertex);

                //拖尾
                //float4 extension = mul(UNITY_MATRIX_M, float4(_Strength * v.uv.x, 0, 0, 0));
                float a = _Strength * v.uv.x;
                float3 extension = float3(UNITY_MATRIX_M[0].x * a, UNITY_MATRIX_M[1].x * a, UNITY_MATRIX_M[2].x * a);

                o.vertex = mul(UNITY_MATRIX_M, v.vertex);

                o.vertex.xyz += extension;
 
                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);
   
				//旋转和偏移
				o.uv = v.uv.xyxy;
				o.uv.xy = Rotate(o.uv.xy, _MainRotation);
				o.uv.xy = TRANSFORM_TEX(o.uv.xy, _MainTex);
				o.uv += _UVOffset * _Time.y;

				//mask mask2
			#if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
				o.uv2 = v.uv.xyxy;
				o.uv2.xy = Rotate(o.uv2.xy, _MaskRotation);
				o.uv2.xy = TRANSFORM_TEX(o.uv2.xy, _MaskTex);
			#if defined(USE_DOUBLE_MASK)
				o.uv2.zw = TRANSFORM_TEX(o.uv2.zw, _Mask2Tex);
			#endif
				o.uv2 += _UV2Offset * _Time.y;
			#endif

				//noise
			#if defined(USE_NOISE)
				o.uv.zw = TRANSFORM_TEX(v.uv, _NoiseTex) + _NoiseParam.zw * _Time.g;
			#endif

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.uv.xy;

            //noise
			#if defined(USE_NOISE)
				fixed2 noise = tex2D(_NoiseTex, i.uv.zw).xy;
                uv = lerp(uv, noise, _NoiseParam.xy);
			#endif 

                // sample the texture
                fixed4 col = tex2D(_MainTex, uv) * i.vertexColor;

				//Alpha通道、饱和度
                col.a = dot(_AlphaChannel, col);
				col.rgb = Staturation(col.rgb, _Saturation);

				//Mask
			#if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
				fixed mask = dot(tex2D(_MaskTex, i.uv2.xy), _MaskChannel);
                mask = mask - _MaskStrength;
				//Mask2
				#if defined(USE_DOUBLE_MASK)
					fixed mask2 = tex2D(_Mask2Tex, i.uv2.zw).r;
					mask2 = mask2 - _Mask2Strength;
					mask *= mask2;
				#endif
			#else
				fixed mask = 1 - _MaskStrength;
			#endif
                col.a = saturate(col.a * mask);
                return col;
            }
            ENDCG
        }
    }

    CustomEditor "ZXEffectShaderEditor"
}
