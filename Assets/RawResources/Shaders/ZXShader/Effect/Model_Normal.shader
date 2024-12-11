// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ZXShader/Effect/Model_Normal" 
{
	Properties 
    {
		_MainTex ("Main Tex", 2D) = "white" {}
        [HDR]_COLOR ("Color Tint", Color) = (1, 1, 1, 1)
        _MainRotation ("Main_Rotation", Range(0, 360)) = 0
        _Saturation ("饱和度", Range(0, 1)) = 1

        _AlphaChannel ("Alpha Channel", Vector) = (0,0,0,1)
        _UVOffset ("主纹理和法线UV偏移", Vector) = (0,0,0,0)

        [Enum(Zero,0,One,1,Two,2)] __MaskMode ("Mask Mode", Float) = 0
        _MaskTex ("Mask Texture", 2D) = "white" {}
        _MaskChannel ("Mask Channel", Vector) = (1,0,0,0)
        _MaskRotation ("Mask Rotation", Range(0, 360)) = 0

        _Mask2Tex ("Mask 2 Texture", 2D) = "white" {}
        _MaskStrength ("Mask Strength", Float ) = 0
        _Mask2Strength ("Mask 2 Strength", Float) = 0
		_UV2Offset ("两个遮罩UV偏移", Vector) = (0,0,0,0)

        [Toggle(USE_NOISE)] _UseNoise("Use Noise", Float) = 0
        _NoiseTex ("Noise", 2D) = "black" {}
        _NoiseParam ("Noise_power", Vector ) = (0,0,0,0)

        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", Int) = 1
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull", Int) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Int) = 4

		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpRotation("Bump Rotation", Range(0, 360)) = 0
		_BumpScale ("Bump Scale", Float) = 1.0

		_LightDir ("LightDir", Vector) = (0, 0, 0, 0)
		[HDR]_LightCol ("LightColor", Color) = (1,1,1,1)
		[HDR]_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
		[Enum(Never, 0, Color, 1, Alpha, 2)]_SetVertexColor ("SetVertexColor", Float) = 1
	}
	SubShader 
    {
		Tags 
        { 
		    "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

		Pass 
        { 
			Tags 
            { 
                "LightMode"="UniversalForward" 
            }

            LOD 100
		
			Blend SrcAlpha [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTest]
            ZWrite Off

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			#pragma multi_compile_local __ USE_MASK USE_DOUBLE_MASK
			#pragma multi_compile_local __ USE_NOISE

			#include "CGIncludes/Model_NormalImport.cginc"
		
			struct a2v 
            {
				float4 vertex : POSITION;
                half4 vertexColor : COLOR;

				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};
			
			struct v2f 
            {
				float4 pos : SV_POSITION;
                half4 vertexColor : COLOR;

				half4 uv : TEXCOORD0;//main normal

			#if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
				half4 uv2 : TEXCOORD4;//mask dissolve
			#endif

			#if defined(USE_NOISE)
				half2 uv3 : TEXCOORD5;//noise
			#endif

				float4 TtoW0 : TEXCOORD1;  
				float4 TtoW1 : TEXCOORD2;  
				float4 TtoW2 : TEXCOORD3; 

			};
			
			half2 Rotate(half2 uv, half2 angle)
			{
				uv -= 0.5;
				float2 CosSin = sin(half2(angle.xx) * 0.0174533 + half2(1.5708, 0));
				uv = mul(uv, float2x2(CosSin.x, -CosSin.y, CosSin.y, CosSin.x));
				uv += 0.5;
				return uv;
			}

			v2f vert(a2v v) 
            {
				v2f o;
				
				VertexPositionInputs vertexInputs 	= GetVertexPositionInputs(v.vertex);
				VertexNormalInputs normalInputs 	= GetVertexNormalInputs(v.normal, v.tangent);

				float3 worldPos = vertexInputs.positionWS;  
				half3 worldNormal = normalInputs.normalWS;  
				half3 worldTangent = normalInputs.tangentWS;  
				half3 worldBinormal = normalInputs.bitangentWS; 
				
                //切线和世界坐标
				o.pos = vertexInputs.positionCS;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				o.vertexColor = v.vertexColor * _COLOR;

				if(_SetVertexColor == 1)
				{
					o.vertexColor.rgb = pow(o.vertexColor.rgb, 0.4545);
				}
				else if(_SetVertexColor == 2)
				{
					o.vertexColor = pow(o.vertexColor, 0.4545);
				}

				//旋转和偏移
				//main normal
				o.uv = v.uv.xyxy;

				o.uv.xy = Rotate(o.uv.xy, _MainRotation);
				o.uv.zw = Rotate(o.uv.zw, _BumpRotation);

				o.uv.xy = TRANSFORM_TEX(o.uv.xy, _MainTex);
				o.uv.zw = TRANSFORM_TEX(o.uv.zw, _BumpMap);
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
				o.uv3 = TRANSFORM_TEX(v.uv, _NoiseTex) + _NoiseParam.zw * _Time.g;
			#endif
			
				return o;
			}
			
			half4 frag(v2f i) : SV_Target 
            {
				//光方向和视角方向	
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				half3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
				
				//法线
				half3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				
				half2 uv = i.uv.xy;

				//noise
			#if defined(USE_NOISE)
				half2 noise = tex2D(_NoiseTex, i.uv3).xy;
                uv = lerp(uv, noise, _NoiseParam.xy);
			#endif 

				half4 col = tex2D(_MainTex, uv) ;

				//Alpha通道、饱和度
                col.a = dot(_AlphaChannel, col);
                half gray = dot(col.rgb, float3(0.3,0.59,0.11));
				col.rgb = lerp(gray, col.rgb, _Saturation);

				col *= i.vertexColor;

				//Mask
			#if defined(USE_MASK) || defined(USE_DOUBLE_MASK)
				half mask = dot(tex2D(_MaskTex, i.uv2.xy), _MaskChannel);
                mask = mask - _MaskStrength;
				
				//Mask2
				#if defined(USE_DOUBLE_MASK)
					half mask2 = tex2D(_Mask2Tex, i.uv2.zw).r;
					mask2 = mask2 - _Mask2Strength;
					mask *= mask2;
				#endif
			#else
				half mask = 1 - _MaskStrength;
			#endif
				col.a = saturate(col.a * mask);

				half3 lightDir = normalize(_LightDir);

				//光照模型
				// half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * col;
				half3 diffuse = _LightCol.rgb * col * max(0, dot(bump, lightDir));
				half3 halfDir = normalize(lightDir + viewDir);
				half3 specular = _LightCol.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);
				
				return half4(diffuse + specular, col.a);
			}
			ENDHLSL
		}
	} 
	CustomEditor "ModelNormalShaderEditor"
}
