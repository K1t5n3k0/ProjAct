Shader "ZXShader/Scene/ZXTerrain"
{
    Properties 
    {
        [Flod(2)] _Control ("画板", Float) = 1
        [BeginVertical]
        [NoScaleOffset]_SplatMap01 ("画板(1)", 2D) = "black" {}
        [NoScaleOffset]_SplatMap02 ("画板(2)", 2D) = "black" {}
        [EndVertical]

        [Flod(5)] _Layer1 ("笔刷(1,R)", Float) = 1
        [BeginVertical]
        _Albedo01 ("笔刷", 2D) = "white" {}
        _BumpSplat1("法线", 2D) = "bump" {}
        [Indent_add]
        _Color1("颜色", Color) = (1,1,1,1)
        _NormalStrength1("法线强度", Range(0, 10)) = 1
        _SpecStrength1("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [Flod(5)] _Layer2 ("笔刷(2,G)", Float) = 1
        [BeginVertical]
        _Albedo02 ("笔刷", 2D) = "black" {}
        _BumpSplat2("法线", 2D) = "bump" {}
        [Indent_add]
        _Color2("颜色", Color) = (1,1,1,1)
        _NormalStrength2("法线强度", Range(0, 10)) = 1
        _SpecStrength2("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [Flod(5)] _Layer3 ("笔刷(3,B)", Float) = 1
        [BeginVertical]
        _Albedo03 ("笔刷", 2D) = "black" {}
        _BumpSplat3("法线", 2D) = "bump" {}
        [Indent_add]
        _Color3("颜色", Color) = (1,1,1,1)
        _NormalStrength3("法线强度", Range(0, 10)) = 1
        _SpecStrength3("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [Flod(5)] _Layer4 ("笔刷(4,R)", Float) = 0
        [BeginVertical]
        _Albedo04 ("笔刷", 2D) = "black" {}
        _BumpSplat4("法线", 2D) = "bump" {}
        [Indent_add]
        _Color4("颜色", Color) = (1,1,1,1)
        _NormalStrength4("法线强度", Range(0, 10)) = 1
        _SpecStrength4 ("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [Flod(5)] _Layer5 ("笔刷(5,G)", Float) = 0
        [BeginVertical]
        _Albedo05 ("笔刷", 2D) = "black" {}
        _BumpSplat5("法线", 2D) = "bump" {}
        [Indent_add]
        _Color5("颜色", Color) = (1,1,1,1)
        _NormalStrength5("法线强度", Range(0, 10)) = 1
        _SpecStrength5 ("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [Flod(5)] _Layer6 ("笔刷(6,B)", Float) = 0
        [BeginVertical]
        _Albedo06 ("笔刷", 2D) = "black" {}
        _BumpSplat6("法线", 2D) = "bump" {}
        [Indent_add]
        _Color6("颜色", Color) = (1,1,1,1)
        _NormalStrength6("法线强度", Range(0, 10)) = 1
        _SpecStrength6 ("高光亮度", Range(0,1)) = 1
        [Indent_sub]
        [EndVertical]

        [BeginVertical]
        _Brightness("接收光照强度", Range(0, 10)) = 1.22
        // _AmbientStrength("环境光亮度", Range(0, 1)) = 1
        _Gloss("高光大小", Range(1,1024)) = 5
        _SpecularColor("高光颜色", Color) = (0,0,0,0)

        [ToggleOff(_LINEAR_SPACE)] _IsLinearSpace("线性环境", Float) = 1
        [Toggle(_SPECULAR_MAP)] _SpecularMap("法线B通道添加粗糙度", Float) = 0
    }

    SubShader 
    {
	    Tags {
		    "SplatCount" = "6"
		    "Queue" = "Geometry-100"
            "RenderType" = "Opaque"
        }

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

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ _LINEAR_SPACE
            #pragma multi_compile _ _SPECULAR_MAP

            #pragma multi_compile _WORLD_CLOUD_OFF _WORLD_CLOUD_ON

        #if (defined(_MAIN_LIGHT_SHADOWS) || defined(MAIN_LIGHT_CALCULATE_SHADOWS))
            #define TERRAIN_RECEIVE_SHADOWS
        #endif

            #include "../HLSL/ZXLighting.hlsl"
            #include "HLSL/ZXTerrain.hlsl"

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
                half   fogCoord   : TEXCOORD1;
                half4   TtoW[3]    : TEXCOORD2;

                float4 shadowCoord : TEXCOORD5;

                #if !defined(_WORLD_CLOUD_OFF) && defined(_WORLD_CLOUD_ON)
                    float3 positionWS : TEXCOORD6;
                #endif

                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);
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

                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(worldNormal, o.vertexSH);

            #if defined(_LINEAR_SPACE)
                _Color1 = LinearToSRGB(_Color1);
                _Color2 = LinearToSRGB(_Color2);
                _Color3 = LinearToSRGB(_Color3);
                _Color4 = LinearToSRGB(_Color4);
                _Color5 = LinearToSRGB(_Color5);
                _Color6 = LinearToSRGB(_Color6);
            #endif
            
                //切线和世界坐标
                o.TtoW[0] = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW[1] = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW[2] = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                o.fogCoord = o.vertex.z;

                //阴影
                    o.shadowCoord = float4(0, 0, 0, 0);
                #if defined(TERRAIN_RECEIVE_SHADOWS)
                    o.shadowCoord = GetShadowCoord(vertexPos);
                #endif

                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                half3 mixedColor, mixedNormal;
                half specStrength = 0;

                //地形贴图叠加
                TerrainMixColorPass(i.uv, mixedColor, mixedNormal, specStrength);

                // mixedNormal.z = sqrt(1.0 - saturate(dot(mixedNormal.xy, mixedNormal.xy)));
                half3 bump = normalize(half3(dot(i.TtoW[0].xyz, mixedNormal), dot(i.TtoW[1].xyz, mixedNormal), dot(i.TtoW[2].xyz, mixedNormal)));
                
                half3 albedo = mixedColor;

                _SpecularColor = LinearToSRGB(_SpecularColor);

                //主光源
                half3 worldPos = half3(i.TtoW[0].w, i.TtoW[1].w, i.TtoW[2].w);
                Light mainLight = GetMainLight(i.shadowCoord);
                half3 lightDir = normalize(mainLight.direction);
                half3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
                half3 halfDir = normalize(viewDir + lightDir);

                half3 diffuseColor =  (saturate(dot(lightDir, bump))) * albedo * _Brightness;
                half3 specularColor = pow(max(0, dot(bump, halfDir)), _Gloss) * _SpecularColor.rgb * specStrength;

                half NdotL = saturate(dot(bump, lightDir));

                half shadowAttenuation = mainLight.shadowAttenuation;
                #if !defined(_WORLD_CLOUD_OFF) && defined(_WORLD_CLOUD_ON)
                    shadowAttenuation = min(shadowAttenuation, WorldCloudShadow(i.positionWS));
                #endif

                half3 radiance = LinearToSRGB(mainLight.color) * (shadowAttenuation * mainLight.distanceAttenuation * NdotL);

                // SampleLightmap(i.lightmapUV, bump);
                half3 color = (diffuseColor + specularColor) * radiance + SAMPLE_GI(i.lightmapUV, i.vertexSH, bump) * albedo;

                //点光源
                Light addLight;
                int n = GetAdditionalLightsCount(); 
                for(int j = 0; j < n; ++j)
                {
                    addLight = GetAdditionalLight(j, worldPos);
                    lightDir = normalize(addLight.direction);
                    halfDir = normalize(viewDir + lightDir);

                    diffuseColor = (saturate(dot(lightDir, bump))) * albedo;
                    specularColor = pow(max(0, dot(bump, halfDir)), _Gloss) * _SpecularColor.rgb * specStrength;
                    color += (diffuseColor + specularColor) * addLight.color * addLight.distanceAttenuation;
                }
                color = MixFog(color, ComputeFogFactor(i.fogCoord));

                return half4(color, 1);
            }

            ENDHLSL
        }
    }
    
    CustomEditor "CustomShaderEditor"
}
