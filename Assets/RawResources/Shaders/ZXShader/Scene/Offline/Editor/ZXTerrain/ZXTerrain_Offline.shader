Shader "ZXShader/Scene/ZXTerrain_Offline"
{
    Properties 
    {
        [Flod(0)] _tittle("离线渲染专用 禁止用于动态场景", Float) = 1
        [Flod(2)] _Control ("画板", Float) = 1
        [BeginVertical]
        [NoScaleOffset]_SplatMap01 ("画板(1)", 2D) = "black" {}
        [NoScaleOffset]_SplatMap02 ("画板(2)", 2D) = "black" {}
        [EndVertical]

        [Flod(9)] _Layer1 ("笔刷(1,R)", Float) = 1
        [BeginVertical]
        [Tex(1)]_Albedo01 ("笔刷", 2D) = "white" {}
        _Color1("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat1("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength1("法线强度", Range(0, 10)) = 1
        [Tex]_MOE1("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo01)]
        _Metallic1("金属度", Range(0.0, 1.0)) = 0
        _Smoothness1("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength1("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColor1("自发光", Color) = (0,0,0,1)
        [EndVertical]

        [Flod(9)] _Layer2 ("笔刷(2,G)", Float) = 1
        [BeginVertical]
        [Tex(1)]_Albedo02 ("笔刷", 2D) = "black" {}
        _Color2("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat2("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength2("法线强度", Range(0, 10)) = 1
        [Tex]_MOE2("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo02)]
        _Metallic2("金属度", Range(0.0, 1.0)) = 0
        _Smoothness2("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength2("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColor2("自发光", Color) = (0,0,0,1)
        [EndVertical]

        [Flod(9)] _Layer3 ("笔刷(3,B)", Float) = 1
        [BeginVertical]
        [Tex(1)]_Albedo03 ("笔刷", 2D) = "black" {}
        _Color3("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat3("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength3("法线强度", Range(0, 10)) = 1
        [Tex]_MOE3("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo03)]
        _Metallic3("金属度", Range(0.0, 1.0)) = 0
        _Smoothness3("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength3("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColor3("自发光", Color) = (0,0,0,1)
        [EndVertical]

        [Flod(9)] _Layer4 ("笔刷(4,R)", Float) = 0
        [BeginVertical]
        [Tex(1)]_Albedo04 ("笔刷", 2D) = "black" {}
        _Color4("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat4("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength4("法线强度", Range(0, 10)) = 1
        [Tex]_MOE4("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo04)]
        _Metallic4("金属度", Range(0.0, 1.0)) = 0
        _Smoothness4("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength4("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColo4("自发光", Color) = (0,0,0,1)
        [EndVertical]

        [Flod(9)] _Layer5 ("笔刷(5,G)", Float) = 0
        [BeginVertical]
        [Tex(1)]_Albedo05 ("笔刷", 2D) = "black" {}
        _Color5("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat5("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength5("法线强度", Range(0, 10)) = 1
        [Tex]_MOE5("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo05)]
        _Metallic5("金属度", Range(0.0, 1.0)) = 0
        _Smoothness5("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength5("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColor5("自发光", Color) = (0,0,0,1)

        [EndVertical]

        [Flod(9)] _Layer6 ("笔刷(6,B)", Float) = 0
        [BeginVertical]
        [Tex(1)]_Albedo06 ("笔刷", 2D) = "black" {}
        _Color6("颜色", Color) = (1,1,1,1)
        [Tex(1)]_BumpSplat6("法线(B:光滑)", 2D) = "bump" {}
        _NormalStrength6("法线强度", Range(0, 10)) = 1
        [Tex]_MOE6("R:金属 G:AO B:自发光", 2D) = "white" {}
        [Tex_ST(_Albedo06)]
        _Metallic6("金属度", Range(0.0, 1.0)) = 0
        _Smoothness6("光滑度", Range(0.0, 1.0)) = 0.5
        _OcclusionStrength6("AO强度", Range(0.0, 1.0)) = 1.0
        [HDR]_EmissionColor6("自发光", Color) = (0,0,0,1)
        [EndVertical]

        [Flod(6)] _Parameter("参数调整", Float) = 1
        [BeginVertical]
        [Toggle(_SELF_BRIGHT_ON)]   _SelfBright_ON("光照调整", Float) = 0
        [Indent_add]
        [HideBy(_SelfBright_ON, 1)] _BrightParam("光照参数(小,大,乘,加)", Vector) = (-2,-1,1,0)
        [HideBy(_SelfBright_ON, 1)] _BrightStrength("漫反射强度(乘)", Float) = 1
        [HideBy(_SelfBright_ON, 1)] _BrightOffset("漫反射强度(加)", Float) = 0
        [Indent_sub][EndVertical]

        [BeginVertical]
        [Toggle(_SOFT_OVER)] _SoftOver_ON("软接触面(需要地面为透明层)", Float) = 0
        [HideBy(_SoftOver_ON, 1)] _SoftStrength("强度", Range(0.01, 10)) = 3.5
        [EndVertical]

        [Flod(4)] _Advanced("额外设置", Float) = 0
        [BeginVertical]
        [ToggleOff(_SPECULARHIGHLIGHTS_OFF)] _SpecularHighlights("高光开关", Float) = 1.0
        [ToggleOff(_ENVIRONMENTREFLECTIONS_OFF)] _EnvironmentReflections("环境光反射", Float) = 1.0
        [ToggleOff(_LINEAR_SPACE)] _IsLinearSpace("线性环境", Float) = 1
    }

    SubShader 
    {
	    Tags {
		    "SplatCount" = "6"
		    "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
        }

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "Base"
            
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            


            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma target 3.0

            #pragma shader_feature _MAIN_LIGHT_SHADOWS
            #pragma shader_feature _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma shader_feature _ADDITIONAL_LIGHTS
            #pragma shader_feature _SHADOWS_SOFT
            #pragma shader_feature LIGHTMAP_ON
            #pragma shader_feature _LINEAR_SPACE
            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_featureWORLD_CLOUD_OFF _WORLD_CLOUD_ON
            #pragma shader_feature _SELF_BRIGHT_ON
            #pragma shader_feature_local _SOFT_OVER

        #if (defined(_MAIN_LIGHT_SHADOWS) || defined(MAIN_LIGHT_CALCULATE_SHADOWS))
            #define TERRAIN_RECEIVE_SHADOWS
        #endif

            sampler2D _SplatMap01;
            sampler2D _SplatMap02;

            Texture2D _Albedo01, _Albedo02, _Albedo03, _Albedo04, _Albedo05, _Albedo06;
            float4    _Albedo01_ST, _Albedo02_ST, _Albedo03_ST, _Albedo04_ST, _Albedo05_ST, _Albedo06_ST; 

            Texture2D _BumpSplat1, _BumpSplat2, _BumpSplat3, _BumpSplat4, _BumpSplat5, _BumpSplat6;
            float4    _BumpSplat1_ST, _BumpSplat2_ST, _BumpSplat3_ST, _BumpSplat4_ST, _BumpSplat5_ST, _BumpSplat6_ST;

            Texture2D _MOE1, _MOE2, _MOE3, _MOE4, _MOE5, _MOE6;
            float4    _MOE1_ST, _MOE2_ST, _MOE3_ST, _MOE4_ST, _MOE5_ST, _MOE6_ST;

            half4     _Color1, _Color2, _Color3, _Color4, _Color5, _Color6;
            half4     _EmissionColor1, _EmissionColor2, _EmissionColor3, _EmissionColor4, _EmissionColor5, _EmissionColor6;
            half      _Smoothness1, _Smoothness2, _Smoothness3, _Smoothness4, _Smoothness5, _Smoothness6;
            half      _Metallic1, _Metallic2, _Metallic3, _Metallic4, _Metallic5, _Metallic6;
            half      _OcclusionStrength1, _OcclusionStrength2, _OcclusionStrength3, _OcclusionStrength4, _OcclusionStrength5, _OcclusionStrength6;
            half      _NormalStrength1, _NormalStrength2, _NormalStrength3, _NormalStrength4, _NormalStrength5, _NormalStrength6;
            half      _SpecStrength1, _SpecStrength2, _SpecStrength3, _SpecStrength4, _SpecStrength5, _SpecStrength6;

            half4     _BrightParam;
            half      _BrightStrength;
            half      _BrightOffset;
            half      _Brightness;
            half      _SoftStrength;

            SamplerState sampler_Albedo01;
            SamplerState sampler_BumpSplat1;

            SamplerState sampler_MOE1;

            #include "Assets/RawResources/Shaders/ZXShader/Scene/HLSL/ZXLighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "HLSL/ZXTerrain_Offline.hlsl"

            struct a2v
            {
                float4 vertex       : POSITION;
                half3  normal       : NORMAL;
                half4  tangent      : TANGENT;	
                half2  uv           : TEXCOORD0;
                half2  lightmapUV   : TEXCOORD1;
            };

            struct v2f
            {
                float4  vertex     : SV_POSITION;
                half2   uv         : TEXCOORD0;
                half2   fogAndMore   : TEXCOORD1;//x:fog y:ModelY
                half4   TtoW[3]    : TEXCOORD2;

                float4 shadowCoord : TEXCOORD5;

                #if !defined(_WORLD_CLOUD_OFF) && defined(_WORLD_CLOUD_ON)
                    float3 positionWS : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);

                half4 screenPos : TEXCOORD8;

            };

            v2f vert(a2v v)
            {
                v2f o;

                VertexPositionInputs vertexPos = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal, v.tangent);

                half3 worldPos      = vertexPos.positionWS;
                half3 worldNormal   = normalInputs.normalWS;
                half3 worldTangent  = normalInputs.tangentWS;
                half3 worldBinormal = normalInputs.bitangentWS;

            #if !defined(_WORLD_CLOUD_OFF) && defined(_WORLD_CLOUD_ON)
                o.positionWS    = worldPos;
            #endif

                o.vertex        = vertexPos.positionCS;
                o.uv            = v.uv;
                o.screenPos     = ComputeScreenPos(o.vertex);

                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(worldNormal, o.vertexSH);

                //切线和世界坐标
                o.TtoW[0] = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW[1] = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW[2] = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                o.fogAndMore.x = o.vertex.z;

            #ifdef _SELF_BRIGHT_ON
                o.fogAndMore.y = GetBrightness(v.vertex.y);
            #endif

                //阴影
                    o.shadowCoord = float4(0, 0, 0, 0);
                #if defined(TERRAIN_RECEIVE_SHADOWS)
                    o.shadowCoord = GetShadowCoord(vertexPos);
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half2 mo;
                half3 mixedColor, emission;
                half4 ns;

                //地形贴图叠加
                TerrainMixColorPass(i.uv, mixedColor, ns, mo, emission);

                ns.z = sqrt(1.0 - saturate(dot(ns.xy, ns.xy)));
                half3 worldPos = half3(i.TtoW[0].w, i.TtoW[1].w, i.TtoW[2].w);
                half3 bump = normalize(half3(dot(i.TtoW[0].xyz, ns), dot(i.TtoW[1].xyz, ns), dot(i.TtoW[2].xyz, ns)));

                InputData inputData;
                inputData.normalWS              = bump;
                inputData.viewDirectionWS.xyz   = normalize(_WorldSpaceCameraPos - worldPos);
                inputData.viewDirectionWS.w     = i.fogAndMore.y;
                inputData.positionWS            = worldPos;
                inputData.shadowCoord           = i.shadowCoord;
                inputData.bakedGI               = SAMPLE_GI(i.lightmapUV, i.vertexSH, inputData.normalWS);

                half4 color = UniversalFragmentPBR(inputData, mixedColor, mo.r, ns.a, mo.g, emission, 1,1,1);

                color.rgb = MixFog(color.rgb, ComputeFogFactor(i.fogAndMore.x));

                //软接触面
            #if defined(_SOFT_OVER)
                half2 uv = i.screenPos.xy / i.screenPos.w;
                half depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
                half depthValue = LinearEyeDepth(depth, _ZBufferParams);
                half depthOffset = depthValue - i.screenPos.w;
                color.a *= saturate(depthOffset * _SoftStrength);
            #endif

                return color;
            }

            ENDHLSL
        }
    }
    
    CustomEditor "CustomShaderEditor"
}
