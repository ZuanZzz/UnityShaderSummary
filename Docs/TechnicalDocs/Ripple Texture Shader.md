# Under water ripple effect

# Effect

![image.png](image.png)

# Basic version implementation

## Knowledge point summary

### Train of though

this effect you should use shader to implement it, and for the part of shader, we should make sure there are basic texture and ripple texture you should display, and then you should know how to add the ripple texture to the basic texture, finally you should make the ripple texture to move what is like an animation.

so there are some key points.

### Key points

1. write the basic structure of shader
2. display the basic texture to let the model looks like a normal look
3. add the ripple texture to the basic texture
4. let the ripple texture move
5. set some values so that you can set the look feature
    1. Tilling
    2. offset
    3. speed
    4. *direction

## Shader代码

- Codes
    
    ```jsx
    Shader "UI/WaterRippleEffectWithTiling"
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
    
    ```
    

## Implementation Processing

### basic structure of Unityshader

- Codes
    
    ```csharp
    Shader "Custom/RippleTestShader_M"{ //shader name
         //display on the material inspector
        Properties{
            _BasicTex("Base Texture", 2D) = "white"{} //the base texture
            _RippleTex("Ripple Texture", 2D) = "whire"{} //the ripple texture
            _RippleSpeed("Ripple Speed", float) = 0.5 //the speed of the ripple
            _RippleStrength("Ripple Strength", float) = 0.3 //the strength of the ripple
        }
         //rendering order
        SubShader{
            Pass
            {  
                CGPROGRAM
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
                struct appdata{}
                struct v2f{}
    
                v2f vert(appdata v){}
                fixed4 frag(v2f i) : SV_Target{ }
    
                ENDCG
            }
    
        }
        Fallback "Transparent/Diffuse" //if the shader is not supported, use the Diffuse shader
    }
    ```
    
- QA
    - why should use vertex shader or fragment shader, when should use which one
    - why head file should be under the pragma
    - how do I know which head file should be included
    - how to define the struct

### Key codes 原理

- Vertex Shader
    - Vertex Shader to deal the translation of verts, translating the object position to the ClipSpace
    - At the same time, the texture coordinates are passed to the fragment shader for subsequent sampling.
    - **Object Space —> World Space —> Camera Space—>Clip Space  —>Screen Space(NDC)**
    
    ```csharp
    v2f vert(appdata v)
    {
        v2f o;
        o.pos = UnityObjectToClipPos(v.vertex); // 模型空间到裁剪空间
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);  // UV变换
        return o;
    }
    ```
    
    - **QA1**: How to write the vertext shader, why do I know I should pass the texture coordinates, and accordin to the Rendering Pipline, why do we only transfer the objectSpace.
    - **QA2**: if the space is point about model, how can I see the texture transform
- Fragment Shader
    1. sample basic texture
        
        ```csharp
        // use tex2D() to get the color of the texture
        // baseColor.a stores tranparent
        fixed4 baseColor = tex2D(_MainTex, i.uv);
        ```
        
    2. **calculate the offset of UV**
        
        ```csharp
        float2 rippleUV = i.uv;
        rippleUV.x += _Time.y * _RippleSpeed;    // The X-axis offset varies with time
        rippleUV.y += sin(_Time.y) * _RippleSpeed; // use sin() to simulate wave
        ```
        
    3. sample the ripple texture
        
        ```csharp
        fixed4 rippleColor = tex2D(_RippleTex, rippleUV);
        ```
        
    4. **calculate the final color and control the transparent**
        
        ```csharp
        finalColor.rgb += rippleColor.r * _RippleStrength * baseColor.a;
        finalColor.a = baseColor.a; // I only want rippleColor to display non-transparent area
        return finalColor;
        ```
        
        - use addition to simulate the superposition of light, so we use `baseColor+rippleColor`
        - **Why** only use the R value of rippleColor?
            - because the ripple texture is usually black and white (grayscale), so `r = g =b`
            - white area： the value is close to 1.0; black area: value = 0.0
        - **Why** should use multiplication
            - if use addition, it`s hard to control the value, so we usually use multiplication to be a 调节系数
        - **Why** should multiply to the baseColor.a
            - if the basic pixel is transparent totally( alpha = 0.0), so rippleColor cannot be displayed here
            - if the basic pixel is half trasparent ( alpha = 0.5), so rippleColor strength should be halved

### Version1(Error)

- Codes
    
    ```csharp
    Shader "Custom/RippleTestShader_M"{ //shader name
         //display on the material inspector
        Properties{
            _BasicTex("Base Texture", 2D) = "white"{} //the base texture
            _RippleTex("Ripple Texture", 2D) = "whire"{} //the ripple texture
            _RippleSpeed("Ripple Speed", float) = 0.5 //the speed of the ripple
            _RippleStrength("Ripple Strength", float) = 0.3 //the strength of the ripple
        }
         //rendering order
        SubShader{
            Pass
            {  
                CGPROGRAM
                // Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct appdata members vertex)
                #pragma exclude_renderers d3d11
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
    
                //think: how do I know how to define the struct
                //define the vertex data
                struct appdata{
                    float4 vertex ：POSITION; //the position of the vertex
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
    
                fixed4 frag(v2f i) : SV_Target{
                    // sample the base texture color and alpha
                    fixed4 baseColor = tex2D(_BasicTex, i.uv); 
                    // calculate the uv offset of the ripple
                    float2 rippleUV = i.uv;
                    // _Time.y is the time since the shader started
                    // _Time.x is the time since the shader started, but it is paused when the game is paused
                    rippleUV.x += _Time.y * _RippleSpeed; //calculate the x offset of the ripple
                    rippleUV.y += sin(_Time.y) * _RippleSpeed; //calculate the y offset of the ripple
                    // sample the ripple texture color and alpha
                    fixed4 rippleColor = tex2D(_RippleTex, rippleUV);
                    // calculate the final color of the pixel
                    fixed4 finalColor = baseColor;
                    finalColor.rgb += rippleColor.a * _RippleStrength * baseColor.a; //add the ripple color to the base color
                    // because the ripple texture is transparent, we need to multiply the alpha of the ripple texture
                    finalColor.a = baseColor.a; //calculate the final alpha
    
                    return finalColor; //return the final color
                }
    
                ENDCG
            }
    
        }
        Fallback "Transparent/Diffuse" //if the shader is not supported, use the Diffuse shader
    }
    ```
    
- Error
    - line5: “white” spelling error
    - …(didn`t solved)

## QA

## Extra Learning

- Calculating about color
- color model
- Alpha blending
- color science

# 注意

## UGUI添加材质透明部分呈纯黑色

1、在给 UGUI 添加 Material 时，如果 Material 中的 Shader 不做特殊处理的话，那么此组件将会变成纯黑色。
2、如果需要添加 Material ，则需要在 Shader 中做 UGUI 专门的处理。
3、在 Shader 中添加上述代码，这时再将 Material 再绑定到 UGUI上即可。

```jsx
	Properties 
    {
	    //UI部分添加
		[Header(UIProperties)]
		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255
		//UI部分添加
	}
	SubShader 
    {
        //UI部分添加
		Cull Off//剔除
		Lighting Off//光照关闭
		ZWrite Off//深度写入关闭
		Blend One OneMinusSrcAlpha//混合模式
        //UI部分添加
    }
```

## UGUI渲染层级

UI的层级显示受渲染顺序和Shader设置的影响。对于UI，Unity的Canvas渲染系统会根据 `Render Queue` 和 `Sorting Order` 来决定渲染顺序。你提到的问题可能是因为你的Shader的 `Render Queue` 设置导致它跳出了Canvas的正常渲染层级。

### 问题的根本原因

在你的Shader中，`Tags` 部分设置了：

```
shader
CopyEdit
Tags { "Queue" = "Overlay" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

```

`Queue` 的值为 `Overlay`，这个值意味着它被设置为非常高的渲染队列（默认是 4000）。而Canvas的默认渲染队列通常是 3000（`Transparent`），当你的Shader的队列高于其他UI元素时，它会覆盖所有在Canvas中的UI层级。

### 解决方法

要让这个Shader的层级行为与其他UI Shader一致，你需要调整它的渲染队列。

### 方法1：降低 `Render Queue`

将 `Queue` 从 `Overlay` 调整为 `Transparent`（3000）：

```
shader
CopyEdit
Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

```

这样可以让它与其他透明的UI元素使用相同的渲染队列，层级会按照Canvas的 `Sorting Order` 和 `Hierarchy` 顺序渲染。

### 方法2：动态调整材质的渲染队列

如果你的项目需要动态控制不同材质的渲染顺序，可以通过代码调整材质的渲染队列：

```csharp
csharp
CopyEdit
Material mat = yourMaterialReference;
mat.renderQueue = 3000; // 设置为Canvas的默认队列

```

这种方法允许更灵活地管理材质渲染顺序。

### 方法3：添加Stencil缓冲支持（推荐）

Unity UI Shader 通常利用Stencil缓冲来确保正确的渲染顺序和遮罩效果。你已经定义了Stencil相关属性，但没有实际在Shader中启用它。修改 `Pass` 的代码如下：

```
shader
CopyEdit
Pass
{
    Stencil
    {
        Ref [_Stencil]
        Comp [_StencilComp]
        Pass [_StencilOp]
        ReadMask [_StencilReadMask]
        WriteMask [_StencilWriteMask]
    }
    CGPROGRAM
    #pragma vertex vert
    #pragma fragment frag
    ...
    ENDCG
}

```

这段代码将Stencil配置整合到渲染流程中，确保与Canvas渲染系统的Stencil机制保持一致。

### 方法4：使用Canvas的 `Additional Shader Channels`

确保你的Canvas设置中，启用了 `Additional Shader Channels`，包括 `UV1` 和 `Tangent`。这些选项可以确保你的Shader在UI渲染过程中接收到正确的数据。

### 总结

推荐优先尝试 **方法1** 或 **方法3**，确保Shader的 `Render Queue` 与Canvas的默认设置一致，并正确使用Stencil缓冲。这样既能保留你Shader的特效，又不会破坏UI层级显示。如果还有问题，可以进一步调整Canvas设置或提供具体的项目场景以进行更细化的优化。