Shader "Genshin/CharacterScene_Wall"
{
    Properties
    {
        [Header(Base)]
        _BaseColMidPos          ("Background Color Mid Position",float) = 0
        _BaseColorTop           ("Base Color Top", Color) = (0.5,0.5,0.5,0.5)
        [Header(Massive Smoke)]
        _MassiveSmokeNoise      ("Massive Smoke", 2D) = "white" {}
        _MassiveSmokeColor      ("Massive Smoke Color", Color) = (1,0,0,1)
        _MassiveSmokeMoveSpeed  ("Massive Smoke Move Speed", float) = 1
        _MassiveSmokeInt        ("Massive Smoke Intensity", float) = 1
        [Header(Light Smoke)]
        _LightSmokeNoise        ("Light Smoke" ,2D) = "white" {}
        _LightSmokeColor        ("Light Smoke Color", Color) = (0,1,0,1)
        _LightSmokeSpeed        ("Light Smoke Speed", float) = 1
        [Header(Stars)]
        _StarMask               ("Star Mask", 2D) = "white" {}
        _StarSpeed              ("Star Speed", float) = 1
    }
     SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"


            float _BaseColMidPos;
            float4 _BaseColorBot;
            float4 _BaseColorTop;
            sampler2D _MassiveSmokeNoise; float4 _MassiveSmokeNoise_ST;
            sampler2D _LightSmokeNoise; float4 _LightSmokeNoise_ST;
            sampler2D _StarMask; float4 _StarMask_ST;
            sampler2D _SingleStar; float4 _SingleStar_ST;
            float4 _MassiveSmokeColor;
            float4 _LightSmokeColor;
            float _MassiveSmokeMoveSpeed;
            float _StarSpeed;
            float _LightSmokeSpeed;
            float _MassiveSmokeInt;


            struct VertexOutput
            {
                float4 vertex : SV_POSITION;
                float3 posOS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 StarUV : TEXCOORD2;
                float2 lightSmokeUV : TEXCOORD3;
                float2 massiveSmokeUV : TEXCOORD4;
            };

            VertexOutput vert (appdata_full v)
            {
                VertexOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.StarUV = TRANSFORM_TEX(v.texcoord, _StarMask);
                o.massiveSmokeUV=  TRANSFORM_TEX(v.texcoord, _MassiveSmokeNoise);
                o.lightSmokeUV = TRANSFORM_TEX(v.texcoord, _LightSmokeNoise);
                o.posOS = v.vertex.xyz;
                return o;
            }

            float4 frag (VertexOutput i) : SV_Target
            {
                // 底色
                float SphereVerticalMask = pow(smoothstep(0.2, 1, saturate(i.posOS.y/9 + _BaseColMidPos)), 2);
                // float3 baseCol = lerp(_BaseColorBot, _BaseColorTop, SphereVerticalMask);
                float3 baseCol = _BaseColorTop;

                // 大烟
                float MassiveSmoke = tex2D(_MassiveSmokeNoise, float2(i.massiveSmokeUV.x - _Time.x * _MassiveSmokeMoveSpeed, i.massiveSmokeUV.y + _Time.x * _MassiveSmokeMoveSpeed/2)).r;
                float3 MassiveSmokeColor = MassiveSmoke * _MassiveSmokeColor * _MassiveSmokeInt * SphereVerticalMask;
                

                // 小烟
                float LightSmoke = tex2D(_LightSmokeNoise, float2(i.lightSmokeUV.x - _Time.x * _LightSmokeSpeed, i.lightSmokeUV.y)).g;
                LightSmoke = pow(LightSmoke, 2);
                float3 LightSmokeColor = LightSmoke * _LightSmokeColor;

                
                // 群星
                float StarMask = tex2D(_StarMask, float2(i.StarUV.x + _Time.x * _StarSpeed, i.StarUV.y)).r;
                float StarVisibilityNoise1 = tex2D(_LightSmokeNoise, float2(i.lightSmokeUV.x  - _Time.x, i.lightSmokeUV.y));
                float StarVisibilityNoise2 = tex2D(_LightSmokeNoise, float2(i.lightSmokeUV.x, i.lightSmokeUV.y + _Time.y/10));
                float StarVisibilityNoise = saturate(StarVisibilityNoise1 * StarVisibilityNoise2);

                float StarVisibilityMask1 = clamp(smoothstep(0.01, 0.2, abs(frac(i.uv.x - _Time.x) - 0.5) * 2.0), 0.5, 1.0);
                float StarVisibilityMask2 = clamp(smoothstep(0.01, 0.03,  StarVisibilityNoise), 0.3, 1.0);
                float StarVisibilityMask = saturate(StarVisibilityMask1 * StarVisibilityMask2);
                StarMask = pow(StarMask, 3);
                StarMask *= StarVisibilityMask;

                float StarVerticalMask = smoothstep(0.65, 1, saturate(i.posOS.y/9 + _BaseColMidPos));
                float StarColorMask = smoothstep(0.3, 1, abs(frac(i.uv.x * 3 - _Time.x * 0.8) - 0.5) * 2.0);
                float3 StarColor = StarMask * StarVerticalMask * lerp(float3(1,1,1), float3(1,0,0), StarColorMask);


                float3 FragColor = baseCol + MassiveSmokeColor + LightSmokeColor + StarColor;

                return float4(FragColor, 1);


                
                return float4(1,1,1,1);
            }
            ENDCG
        }
    }
}
