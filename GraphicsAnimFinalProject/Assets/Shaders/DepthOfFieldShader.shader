/// Script: DepthOfFieldShader.shader
/// Brief: Depth of Field Shader with Bokeh
/// Author: Egor Fesenko
/// Date: 05/01/2021
/// Sources:
///  1) Based on awesome tutorial and explanation of DOF shader: https://catlikecoding.com/unity/tutorials/advanced-rendering/depth-of-field/
///  2) https://www.exposureguide.com/focusing-basics/#:~:text=The%20f%2Dstops%20work%20as,a%20deeper%20depth%20of%20field.
///  3) https://developer.nvidia.com/gpugems/gpugems3/part-iv-image-effects/chapter-28-practical-post-process-depth-field
///  4) https://forum.unity.com/threads/what-is-the-command-of-cginclude.279175/
///  5) https://docs.unity3d.com/Manual/SL-DepthTextures.html
///  6) https://docs.unity3d.com/Manual/SL-ShaderSemantics.html

Shader "Hidden/DepthOfField"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

		CGINCLUDE // Inserts its contents into each pass
		#include "UnityCG.cginc"

		uniform sampler2D _MainTex;
		uniform	float4 _MainTex_TexelSize;
		uniform sampler2D _CameraDepthTexture;
		uniform sampler2D _CoCTex;
		uniform sampler2D _DoFTex;

		uniform float _FocusDist;
		uniform float _FocusRange;
		uniform float _BokehRad;

		struct appdata
		{
			float4 vertexPos : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Interpolators
		{
			float4 position : POSITION;
			float2 uv : TEXCOORD0;
		};

		Interpolators VertexFunc (appdata IN)
		{
			Interpolators OUT;
			OUT.position = UnityObjectToClipPos(IN.vertexPos);
			OUT.uv = IN.uv;
			return OUT;
		}
	ENDCG

	SubShader
	{
		Cull Off ZTest Always ZWrite Off

		Pass
		{ // (0) Circle Of Confusion Pass to get the strength of bokeh at the texel
			CGPROGRAM

			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			half FragmentFunc(Interpolators IN) : SV_Target
			{
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, IN.uv);
				depth = LinearEyeDepth(depth); //returns corresponding world scaled view space depth

				float coc = (depth - _FocusDist) / _FocusRange;
				coc = clamp(coc, -1, 1) * _BokehRad;

				/*if (coc < 0)
				{
					return coc * -half4(1, 0, 0, 1);
				}*/

				return coc;
			}

			ENDCG
		}

		Pass
		{ // (1) Pre-Filter Pass - Downsampling CoC to fit Bokeh resolution
			CGPROGRAM

			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			half Weigh (half3 c)
			{
				return 1 / (1 + max(max(c.r, c.g), c.b));
			}

			half4 FragmentFunc(Interpolators IN) : SV_Target
			{
				// Offset for downsampling
				float4 offset = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;

				// Four samples, offset to 4 directions -x-y/x-y/-xy/xy
				half3 sample0 = tex2D(_MainTex, IN.uv + offset.xy).rgb;
				half3 sample1 = tex2D(_MainTex, IN.uv + offset.zy).rgb;
				half3 sample2 = tex2D(_MainTex, IN.uv + offset.xw).rgb;
				half3 sample3 = tex2D(_MainTex, IN.uv + offset.zw).rgb;

				// Original weights of texels' brightness
				half weight0 = Weigh(sample0);
				half weight1 = Weigh(sample1);
				half weight2 = Weigh(sample2);
				half weight3 = Weigh(sample3);

				half3 color = sample0 * weight0 + sample1 * weight1 + sample2 * weight2 + sample3 * weight3; // total of all texels' brightnesses
				color /= (weight0 + weight1 + weight2 + weight3); // Making sure that brightness of the image stays close to the original

				// Four samples, offset to 4 directions -x-y/x-y/-xy/xy
				half coc0 = tex2D(_CoCTex, IN.uv + offset.xy).r;
				half coc1 = tex2D(_CoCTex, IN.uv + offset.zy).r;
				half coc2 = tex2D(_CoCTex, IN.uv + offset.xw).r;
				half coc3 = tex2D(_CoCTex, IN.uv + offset.zw).r;

				half cocMin = min(min(min(coc0, coc1), coc2), coc3);
				half cocMax = max(max(max(coc0, coc1), coc2), coc3);
				half coc = cocMax >= -cocMin ? cocMax : cocMin;

				return half4(color, coc);
			}

			ENDCG
		}

		Pass
		{ // (2) Bokeh Pass
			CGPROGRAM

			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			#define KERNEL_LARGE

			// Sammpling kernel,containing offsets within the unit circle
			// From https://github.com/Unity-Technologies/PostProcessing/blob/v2/PostProcessing/Shaders/Builtins/DiskKernels.hlsl
			#if defined(KERNEL_SMALL) // a center point with a ring of 5 samples around it and another ring of 10 samples around that
				static const int kSampleCount = 16;
				static const float2 kDiskKernel[kSampleCount] =
				{
					float2(0, 0),
					float2(0.54545456, 0),
					float2(0.16855472, 0.5187581),
					float2(-0.44128203, 0.3206101),
					float2(-0.44128197, -0.3206102),
					float2(0.1685548, -0.5187581),
					float2(1, 0),
					float2(0.809017, 0.58778524),
					float2(0.30901697, 0.95105654),
					float2(-0.30901703, 0.9510565),
					float2(-0.80901706, 0.5877852),
					float2(-1, 0),
					float2(-0.80901694, -0.58778536),
					float2(-0.30901664, -0.9510566),
					float2(0.30901712, -0.9510565),
					float2(0.80901694, -0.5877853),
				};
			#elif defined (KERNEL_MEDIUM)
				static const int kSampleCount = 22; // a center point with a ring of 7 samples around it and another ring of 14 samples around that
				static const float2 kDiskKernel[kSampleCount] =
				{
					float2(0, 0),
					float2(0.53333336, 0),
					float2(0.3325279, 0.4169768),
					float2(-0.11867785, 0.5199616),
					float2(-0.48051673, 0.2314047),
					float2(-0.48051673, -0.23140468),
					float2(-0.11867763, -0.51996166),
					float2(0.33252785, -0.4169769),
					float2(1, 0),
					float2(0.90096885, 0.43388376),
					float2(0.6234898, 0.7818315),
					float2(0.22252098, 0.9749279),
					float2(-0.22252095, 0.9749279),
					float2(-0.62349, 0.7818314),
					float2(-0.90096885, 0.43388382),
					float2(-1, 0),
					float2(-0.90096885, -0.43388376),
					float2(-0.6234896, -0.7818316),
					float2(-0.22252055, -0.974928),
					float2(0.2225215, -0.9749278),
					float2(0.6234897, -0.7818316),
					float2(0.90096885, -0.43388376),
				};
			#elif defined (KERNEL_LARGE)
				static const int kSampleCount = 43; // a center point with a ring of 21 samples around it and another ring of 21 samples around that
				static const float2 kDiskKernel[kSampleCount] =
				{
					float2(0,0),
					float2(0.36363637,0),
					float2(0.22672357,0.28430238),
					float2(-0.08091671,0.35451925),
					float2(-0.32762504,0.15777594),
					float2(-0.32762504,-0.15777591),
					float2(-0.08091656,-0.35451928),
					float2(0.22672352,-0.2843024),
					float2(0.6818182,0),
					float2(0.614297,0.29582983),
					float2(0.42510667,0.5330669),
					float2(0.15171885,0.6647236),
					float2(-0.15171883,0.6647236),
					float2(-0.4251068,0.53306687),
					float2(-0.614297,0.29582986),
					float2(-0.6818182,0),
					float2(-0.614297,-0.29582983),
					float2(-0.42510656,-0.53306705),
					float2(-0.15171856,-0.66472363),
					float2(0.1517192,-0.6647235),
					float2(0.4251066,-0.53306705),
					float2(0.614297,-0.29582983),
					float2(1,0),
					float2(0.9555728,0.2947552),
					float2(0.82623875,0.5633201),
					float2(0.6234898,0.7818315),
					float2(0.36534098,0.93087375),
					float2(0.07473,0.9972038),
					float2(-0.22252095,0.9749279),
					float2(-0.50000006,0.8660254),
					float2(-0.73305196,0.6801727),
					float2(-0.90096885,0.43388382),
					float2(-0.98883086,0.14904208),
					float2(-0.9888308,-0.14904249),
					float2(-0.90096885,-0.43388376),
					float2(-0.73305184,-0.6801728),
					float2(-0.4999999,-0.86602545),
					float2(-0.222521,-0.9749279),
					float2(0.07473029,-0.99720377),
					float2(0.36534148,-0.9308736),
					float2(0.6234897,-0.7818316),
					float2(0.8262388,-0.56332),
					float2(0.9555729,-0.29475483),
				};
			#endif

			half Weigh (half coc, half radius)
			{
				return saturate((coc - radius + 2) / 2);
			}

			half4 FragmentFunc(Interpolators IN) : SV_Target
			{
				half coc = tex2D(_MainTex, IN.uv).a;
				
				half3 bgColor = 0, fgColor = 0;
				half bgWeight = 0, fgWeight = 0; // level of influence on bg or fg
				for (int k = 0; k < kSampleCount; k++)
				{
					float2 offset = kDiskKernel[k] * _BokehRad; // in texels
					half radius = length(offset); // distance to the offset texel
					offset *= _MainTex_TexelSize.xy;

					half4 sample0 = tex2D(_MainTex, IN.uv + offset); // getting sample at the offset pos
					half bgw = Weigh(max(0, min(sample0.a, coc)), radius); // = 0 if out of CoC, = 0 to 1 if part of CoC
					bgColor += sample0.rgb * bgw;
					bgWeight += bgw;
					half fgw = Weigh(-sample0.a, radius); // = 0 if out of CoC, = 0 to 1 if part of CoC
					fgColor += sample0.rgb * fgw;
					fgWeight += fgw;
				}
				bgColor *= 1 / (bgWeight + (bgWeight == 0));
				fgColor *= 1 / (fgWeight + (fgWeight == 0));
				half bgfg = min(1, fgWeight * 3.14159265359 / kSampleCount);
				half3 color = lerp(bgColor, fgColor, bgfg);
				return half4(color, bgfg); // putting fg and bg mix value into alpha
			}

			ENDCG
		}

		Pass
		{ // (3) Post-Filter Pass - Bluring the Bokeh
			CGPROGRAM

			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			// Blur
			half4 FragmentFunc(Interpolators IN) : SV_Target
			{
				float4 offset = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
				half4 res =
					tex2D(_MainTex, IN.uv + offset.xy) +
					tex2D(_MainTex, IN.uv + offset.zy) +
					tex2D(_MainTex, IN.uv + offset.xw) +
					tex2D(_MainTex, IN.uv + offset.zw);
				return res * 0.25;
			}

			ENDCG
		}

		Pass
		{ // (4) Combine Pass - Getting final color of pixel based on CoC, recombing foreground and background
			CGPROGRAM

			#pragma vertex VertexFunc
			#pragma fragment FragmentFunc

			half4 FragmentFunc(Interpolators IN) : SV_Target
			{
				half4 source = tex2D(_MainTex, IN.uv); // Original color
				half4 dof = tex2D(_DoFTex, IN.uv); // 100% Depth of Field color
				half coc = tex2D(_CoCTex, IN.uv).x; // How close to the focus distance

				half dofStrength = smoothstep(0.1, 1, abs(coc)); // Getting dof strength based on coc
				half3 color = lerp(source.rgb, dof.rgb, dofStrength + dof.a - dofStrength * dof.a);

				return half4(color, source.a);
			}

			ENDCG
		}
	}
}