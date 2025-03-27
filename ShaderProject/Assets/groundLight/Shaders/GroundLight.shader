Shader "UI/GroundLight"
{
    Properties
    {
        // 基础贴图
        _MainTex("Base Texture", 2D) = "white" {}
        // 水波纹贴图
        _RippleTex("Ripple Texture", 2D) = "white" {}
        // 水波纹UV控制
        _RippleTiling("Ripple Tiling", Vector) = (1, 1, 0, 0) // 修正数据类型为Vector
        _RippleOffset("Ripple Offset", Vector) = (0, 0, 0, 0) // 修正数据类型为Vector
        // 动态流动参数
        _RippleSpeed("Ripple Speed", Float) = 0.5
        _RippleStrength("Ripple Strength", Float) = 0.3

        // UGUI所需的Stencil参数
        [Header(UIProperties)]
        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255
    }
    SubShader
    {
        Tags { "Queue" = "Overlay" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        LOD 100

        // UI的基本设置
        Blend SrcAlpha OneMinusSrcAlpha // 混合模式
        Cull Off // 禁用背面剔除
        Lighting Off // 禁用光照
        ZWrite Off // 禁用深度写入

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _RippleTex;
            float4 _RippleTiling; // 水波纹的Tiling（缩放），修正为float4
            float4 _RippleOffset; // 水波纹的UV偏移，修正为float4
            float _RippleSpeed;
            float _RippleStrength;

            // UGUI所需Stencil参数
            float _StencilComp;
            float _Stencil;
            float _StencilOp;
            float _StencilWriteMask;
            float _StencilReadMask;

            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 顶点着色器
            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            // 片段着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 采样基础贴图颜色
                fixed4 baseColor = tex2D(_MainTex, i.uv);

                // 如果基础贴图完全透明，直接返回透明
                if (baseColor.a == 0)
                {
                    return fixed4(0, 0, 0, 0);
                }

                // 计算水波纹UV（加入Tiling和Offset）
                float2 rippleUV = i.uv * _RippleTiling.xy + _RippleOffset.xy; // 使用Tiling和Offset的前两个分量
                rippleUV.x += _Time.y * _RippleSpeed; // 动态偏移
                rippleUV.y += sin(_Time.y) * _RippleSpeed;

                // 采样水波纹贴图
                fixed4 rippleColor = tex2D(_RippleTex, rippleUV);

                // 叠加水波纹效果
                fixed4 finalColor = baseColor;
                finalColor.rgb += rippleColor.r * _RippleStrength * baseColor.a;
                finalColor.a = baseColor.a; // 保持基础透明度

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Diffuse"
}
