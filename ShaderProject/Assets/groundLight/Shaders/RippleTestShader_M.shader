Shader "Custom/RippleTestShader_M" 
{    //display on the material inspector
    Properties{
        _BasicTex("Base Texture", 2D) = "white"{} //the base texture
        _RippleTex("Ripple Texture", 2D) = "white"{} //the ripple texture
        _RippleSpeed("Ripple Speed", float) = 0.5 //the speed of the ripple
        _RippleStrength("Ripple Strength", float) = 0.6 //the strength of the ripple
    }
     //rendering order
    SubShader{
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha //blend mode

        Pass
        {  
            CGPROGRAM
            // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct appdata members vertex)
            // #pragma exclude_renderers d3d11
            // think: why should use vertex shader or fragment shader, when should use which one
            #pragma vertex vert //vertex shader
            #pragma fragment frag  //fragment shader

            // think: why head file should be under the pragma
            // think: how do I know which head file should be included
            #include "UnityCG.cginc" //include the UnityCG.cginc file

            // define the properties
            sampler2D _BasicTex; //the base texture
            sampler2D _RippleTex; //the ripple texture
            float _RippleSpeed; //the speed of the ripple
            float _RippleStrength; //the strength of the ripple
            float4 _BasicTex_ST; //the width and height of the screen

            //think: why should define the uv
            //define the vertex data
            struct appdata{
                float4 vertex : POSITION; //the position of the vertex
                float2 uv : TEXCOORD0; //the texture coordinate
            }
            
            struct v2f{
                float4 pos : SV_POSITION; //the position of the vertex
                float2 uv : TEXCOORD0; //the texture coordinate
            }

            v2f vert(appdata v){
                v2f o; //define the output
                o.pos = UnityObjectToClipPos(v.vertex); //transform the vertex position from object space to clip space
                o.uv = TRANSFORM_TEX(v.uv, _BasicTex); //transform the texture coordinate
                return o; //return the output
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the base texture color and alpha
                fixed4 baseColor = tex2D(_BasicTex, i.uv); 
                // calculate the uv offset of the ripple
                float2 rippleUV = i.uv;
                // _Time.y is the time since the shader started
                // _Time.x is the time since the shader started, but it is paused when the game is paused
                rippleUV.x += _Time.y * _RippleSpeed; //calculate the x offset of the ripple
                rippleUV.y += sin(_Time.y) * _RippleSpeed; //calculate the y offset of the ripple
                rippleUV = frac(rippleUV); //clamp the uv offset to the range [0, 1]
                // sample the ripple texture color and alpha
                fixed4 rippleColor = tex2D(_RippleTex, rippleUV);
                // calculate the final color of the pixel

                fixed4 finalColor = baseColor;
                finalColor.rgb += rippleColor.r * _RippleStrength * baseColor.a; //add the ripple color to the base color
                // because the ripple texture is transparent, we need to multiply the alpha of the ripple texture
                finalColor.a = baseColor.a; //blend the alpha of the base and ripple textures

                return finalColor; //return the final color
            }


            ENDCG
        }

    }
    Fallback "Transparent/Diffuse" //if the shader is not supported, use the Diffuse shader
}