// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ZXShader/Model/ObjSimpleIce"
{
    Properties
    {
        [BeginVertical]
        _MainTex ("主帖图", 2D) = "white" { }
        [HDR]_Color ("颜色", Color) = (1, 1, 1, 1)
        _Sat ("饱和度", Range(-1, 1)) = 0
        _Lum ("对比度", Range(-1, 1)) = 0
        _VirtualStrength ("平面阴影虚化强度", Range(0, 1)) = 0.3
        [EndVertical]

        [BeginVertical]
        [Toggle(_ALPHATEST_ON)] _CutOut("开启剔除", Float) = 0
        [Indent_add]
        [HideBy(_CutOut, 1)]_Cutoff("剔除程序", Range(0.0, 1.0)) = 0.5
        [Indent_sub]

        [Toggle(DEAD_DOSSLVE)] _DeadDosslve("开启死亡溶解", Float) = 0
        [Indent_add]
        [HideBy(_DeadDosslve, 1)]_Dissolution("动画进度", Range(0, 1)) = 0
        [HideBy(_DeadDosslve, 1)]_DissolveScale ("溶解高度缩放", Float) = 1
        [HideBy(_DeadDosslve, 1)]_DissolvePlane ("溶解平面高度", Float) = 0
        [Indent_sub]
        [EndVertical]

        [BeginVertical]
        [Tex(1)]_MatCap ("_MatCap", 2D) = "black" { }
        _MatCapPower ("_MatCapPower", Range(0, 3)) = 1
        _EnvirFrsBright ("_EnvirFrsBright", Range(0, 1)) = 1
        _EnvirBright ("_EnvirBright", Range(0, 3)) = 1
        _Metallic ("_Metallic", Range(0, 1)) = 1
        _Smoothness ("_Smoothness", Range(0, 1)) = 1
        [EndVertical]

        [BeginVertical]
        [Toggle(FOG_OFF)] _FogOff("Disable All Fog", Float) = 0  
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("__src", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("__dst", Float) = 10.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Back

        Pass
        {
            // Tags { "LightMode" = "ForwardBase" "RenderObject"="HeroModel"}
            ZTest LEqual

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
        
            #pragma multi_compile __ _ALPHATEST_ON //_ALPHABLEND_ON _ALPHAPREMULTIPLY_ON //暂时不会用到Fade
            #pragma multi_compile __ FOG_OFF _CAVE_LIGHTING_FOG FOG_LINEAR //_WILD_LIGHTING_FOG

            #pragma multi_compile_local __ DEAD_DOSSLVE
            #pragma multi_compile __ ZX_SIMPLELIGHT_COLOR

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1; 
                float3 worldPos : TEXCOORD2;
            #if defined(FOG_LINEAR) || defined(_CAVE_LIGHTING_FOG) || defined(_WILD_LIGHTING_FOG)
                float fogCoord : TEXCOORD3;
            #endif

            #if defined(DEAD_DOSSLVE)
                float ModelPos : TEXCOORD4;
            #endif
            };

            #include "HLSL/ObjSimpleInput.hlsl"
            
            TEXTURE2D(_MatCap);            
            SAMPLER(sampler_MatCap);
            
            half _MatCapPower;
            half _EnvirFrsBright;
            half _EnvirBright;

            half _Metallic;
            half _Smoothness;

            half4 ZxObjSimpleLightColor;
            half ZxObjSimpleLightStrength;

            #include "../../ZXShader/Character/Model/Library/GFunctionCore.hlsl"
            #include "../../ZXShader/Character/Model/Library/ModelIcePass.hlsl"


            v2f vert (appdata v)
            {
                
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs NormalInput = GetVertexNormalInputs(v.normal);

                o.vertex = mul(UNITY_MATRIX_M, v.vertex);

                //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half diss = _Dissolution * _DissolveScale * _DownDistance;
                o.ModelPos = (o.vertex.y - _DissolvePlane - diss);
                o.vertex.y -= diss;
            #endif
            
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);
                o.worldNormal = NormalInput.normalWS;
                o.worldPos = vertexInput.positionWS;

            #if defined(_WILD_LIGHTING_FOG)
                o.fogCoord = o.vertex.z;
            #elif defined(FOG_LINEAR)
                o.fogCoord = ComputeFogFactor(o.vertex.z);
            #endif

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv) * _Color;

            #if defined(_ALPHATEST_ON)
                clip (col.a - _Cutoff);
            #endif

                //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half dissolveAlpha = tex2D(_DissolveTex, i.uv).r * _DissolveColor.a * _Dissolution;
                half clipAlpha = col.a * (i.ModelPos - dissolveAlpha);
                clip(clipAlpha);
                col.rgb = lerp(col.rgb, _DissolveColor.rgb, step(clipAlpha, _DissolveWidth * 0.1));
            #endif

                //漫反射
                Light light = GetMainLight();
                half diffuse = dot(i.worldNormal,light.direction);

                float2 muv = MatCapUV(i.worldNormal, TransformWorldToView(i.worldPos));
                half3 spmatCap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, muv) * _MatCapPower;
                col.a = CalCulateAlpha(col.rgb, spmatCap, col.a, _Metallic, _Smoothness, diffuse);
                col.rgb += spmatCap;

                half2 dd = saturate(smoothstep(half2(0, 0), half2(0.7, -1), diffuse + 0.1)) * half2(1, 0.4);
                diffuse = saturate((dd.x + dd.y) * 0.4 + 0.6);

                half3 lColor = light.color;

            #if defined(ZX_SIMPLELIGHT_COLOR)
                lColor = lerp(light.color, ZxObjSimpleLightColor.rgb, ZxObjSimpleLightStrength);
            #endif
                //HSV转Color
                float3 hsv = RgbToHsv(col.rgb * diffuse * lColor);
                hsv.y = hsv.y + hsv.y * _Sat;
                hsv.z = hsv.z + hsv.z * _Lum;

                col.rgb = HsvToRgb(hsv);

                //雾效
            #if defined(_CAVE_LIGHTING_FOG)
                 col.rgb = MixFog(col.rgb, i.fogCoord);
            #elif defined(_WILD_LIGHTING_FOG)
                 col.rgb = MixFog(col.rgb, i.fogCoord);
            #elif defined(FOG_LINEAR)
                 col.rgb = MixFog(col.rgb, i.fogCoord);
            #endif

                return col;
            }
            ENDHLSL
        }
        
        // 阴影
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ _ALPHATEST_ON // _ALPHABLEND_ON _ALPHAPREMULTIPLY_O

            #pragma multi_compile_local __ DEAD_DOSSLVE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "HLSL/ObjSimpleInput.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f 
            {
                //V2F_SHADOW_CASTER;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

            #if defined(DEAD_DOSSLVE)
                float ModelPos : TEXCOORD4;
            #endif
            };

            v2f vert( appdata v )
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_M, v.vertex);

            //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half diss = _Dissolution * _DissolveScale * _DownDistance;
                o.ModelPos = (o.vertex.y - _DissolvePlane - diss);
                o.vertex.y -= diss;
            #endif

                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                half alpha = tex2D(_MainTex, i.uv).a * _Color.a;

            #if defined(_ALPHATEST_ON)
                clip (alpha - _Cutoff);
            #endif
 
            //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half dissolveAlpha = tex2D(_DissolveTex, i.uv).r * _DissolveColor.a * _Dissolution;
                clip(alpha * (i.ModelPos - dissolveAlpha));
            #endif

                return 0;
            }
            ENDHLSL
        }

        //平面阴影
        Pass
        {
            Name "PlaneShadow"
            Tags{"LightMode" = "PlaneShadow"}

			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			Cull Back
			ColorMask RGB
			
		    Offset -1, -1//使阴影在平面之上  

			Stencil
			{
				Ref 0			
				Comp Equal			
				WriteMask 255		
				ReadMask 255
				//Pass IncrSat
				Pass Invert
				Fail Keep
				ZFail Keep
			}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ALPHATEST_ON // _ALPHABLEND_ON _ALPHAPREMULTIPLY_O
            #pragma multi_compile_local _ DEAD_DOSSLVE
            #pragma multi_compile __ FOG_OFF FOG_LINEAR //_WILD_LIGHTING_FOG
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "HLSL/ObjSimpleInput.hlsl"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f 
            {
                //V2F_SHADOW_CASTER;
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;

            #if defined(DEAD_DOSSLVE)
                float2 ModelPos : TEXCOORD1;//世界坐标Y  溶解Y
            #else
                float ModelPos : TEXCOORD1;
            #endif

            #if defined(FOG_LINEAR)
                float3 fogCoord : TEXCOORD2;
            #endif
            };

            v2f vert( appdata v)
            {
                v2f o;

                o.vertex = mul(UNITY_MATRIX_M, v.vertex);

                //低于地面透明度为0
                o.ModelPos.x = step(0, o.vertex.y - ZxPlaneShadowParam.w);

                //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half diss = _Dissolution * _DissolveScale * _DownDistance;
                o.ModelPos.y = (o.vertex.y - _DissolvePlane - diss);
                o.vertex.y -= diss;
            #endif

                //平面阴影
                float3 lightDir = normalize(ZxPlaneShadowParam.xyz);
                float d = (ZxPlaneShadowParam.w - o.vertex.y) / lightDir.y;
				o.vertex.xyz = o.vertex.xyz + d * lightDir;

                //方法二
                // o.vertex = mul(_World2Ground,o.vertex); // 将物体在世界空间的矩阵转换到地面空间
                // o.vertex.xz = o.vertex.xz - (o.vertex.y / lightDir.y)*lightDir.xz;// 用三角形相似计算沿光源方向投射后的XZ
                // o.vertex.y = 0;// 使阴影保持在接受平面上
                // o.vertex = mul(_Ground2World, o.vertex); // 阴影顶点矩阵返回到世界空间

                //离人物越远的阴影越虚
                float3 center = float3(unity_ObjectToWorld[0].w , ZxPlaneShadowParam.w ,unity_ObjectToWorld[2].w);
                o.ModelPos.x *= 1 - saturate(distance(o.vertex.xyz, center) * _VirtualStrength);

                o.vertex = mul(UNITY_MATRIX_VP, o.vertex);

            #if defined(FOG_LINEAR)
                o.fogCoord = ComputeFogFactor(o.vertex.z);
            #endif

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                half alpha = tex2D(_MainTex, i.uv).a * _Color.a;

            #if defined(_ALPHATEST_ON)
                clip (alpha - _Cutoff);
            #endif

                //死亡溶解
            #if defined(DEAD_DOSSLVE)
                half dissolveAlpha = tex2D(_DissolveTex, i.uv).r * _DissolveColor.a * _Dissolution;
                clip(alpha * (i.ModelPos.y - dissolveAlpha));
            #endif

                half4 col = ZxObjSimpleShadowColor;
                
                //低于地面透明度为0 离人物越远的阴影越虚
                col.a *= i.ModelPos.x;

            #if defined(FOG_LINEAR)
                col.xyz = MixFog(col.rgb, i.fogCoord);
            #endif

                return col;
            }
            ENDHLSL
        }
    }

    CustomEditor "ObjSimpleEditor"
}
