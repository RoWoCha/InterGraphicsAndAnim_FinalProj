	Shader "Custom/ParallaxOcclusionMapping"
	{
		// Informations sources:
		// 1) https://www.youtube.com/watch?v=CpRuYJHGL10
		// 2) https://catlikecoding.com/unity/tutorials/rendering/part-20/
		// 3) https://github.com/hamish-milne/POMUnity

		Properties 
		{
				_MainTexture ("Diffuse map (RGB)", 2D) = "white" {}
				_HeightMap ("Height map (R)", 2D) = "white" {}	
				_Parallax ("Height scale", Range (0.005, 0.1)) = 0.08
				_ParallaxSamples ("Parallax samples", Range (10, 100)) = 40

		}
		SubShader 
		{
			Pass
			{
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM
				#pragma vertex vertexFunc
				#pragma fragment fragmentFunc

				sampler2D _MainTexture;	
				sampler2D _HeightMap;
				float _Parallax;
				float _ParallaxSamples;
				uniform float4 _LightColor0;

				struct appdata 
				{
					float4 vertex: POSITION;
					float3 normal: NORMAL;
					float2 texcoord: TEXCOORD0;
					float4 tangent  : TANGENT;
				};
			
				struct v2f 
				{
					float4 pos: SV_POSITION;
					float2 tex: TEXCOORD0;
					float4 posWorld: TEXCOORD1;
					float3 tSpace0 : TEXCOORD2;
					float3 tSpace1 : TEXCOORD3;
					float3 tSpace2 : TEXCOORD4;
					float3 normal  : TEXCOORD5;
				};

				v2f vertexFunc(appdata IN) 
				{
					v2f OUT;

					OUT.posWorld = mul(unity_ObjectToWorld, IN.vertex);

					fixed3 worldNormal = mul(IN.normal.xyz, (float3x3)unity_WorldToObject);
					fixed3 worldTangent =  normalize(mul((float3x3)unity_ObjectToWorld,IN.tangent.xyz ));
					fixed3 worldBitangent = cross(worldNormal, worldTangent) * IN.tangent.w;

					OUT.tSpace0 = float3(worldTangent.x, worldBitangent.x, worldNormal.x);
					OUT.tSpace1 = float3(worldTangent.y, worldBitangent.y, worldNormal.y);
					OUT.tSpace2 = float3(worldTangent.z, worldBitangent.z, worldNormal.z);
		
					OUT.pos = UnityObjectToClipPos( IN.vertex );
					OUT.tex = IN.texcoord;
					OUT.normal = IN.normal;
	
					return OUT;
				}

				float4 fragmentFunc(v2f IN): SV_TARGET 
				{
					float3 normalDirection = normalize(IN.normal);
					fixed3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - IN.posWorld.xyz);
					fixed3 viewDir = IN.tSpace0.xyz * worldViewDir.x + IN.tSpace1.xyz * worldViewDir.y  + IN.tSpace2.xyz * worldViewDir.z;
					float2 vParallaxDirection = normalize( viewDir.xy );
					float fLength = length( viewDir );
					float fParallaxLength = sqrt( fLength * fLength - viewDir.z * viewDir.z ) / viewDir.z;
					float2 vParallaxOffsetTS = vParallaxDirection * fParallaxLength * _Parallax ;   
					float nMinSamples = 6;
					float nMaxSamples = min(_ParallaxSamples, 100);
					int nNumSamples = (int)(lerp( nMinSamples, nMaxSamples, 1-dot(worldViewDir , IN.normal ) ));
					float fStepSize = 1.0 / (float)nNumSamples;   
					int    nStepIndex = 0;
					float fCurrHeight = 0.0;
					float fPrevHeight = 1.0;
					float2 vTexOffsetPerStep = fStepSize * vParallaxOffsetTS;
					float2 vTexCurrentOffset = IN.tex.xy;
					float  fCurrentBound     = 1.0;
					float  fParallaxAmount   = 0.0;
					float2 pt1 = 0;
					float2 pt2 = 0;
					float2 dx = ddx(IN.tex.xy);
					float2 dy = ddy(IN.tex.xy);
					for (nStepIndex = 0; nStepIndex < nNumSamples; nStepIndex++)
					{
						vTexCurrentOffset -= vTexOffsetPerStep;
						fCurrHeight = tex2D( _HeightMap, vTexCurrentOffset,dx,dy).r;
						fCurrentBound -= fStepSize;
						if ( fCurrHeight > fCurrentBound ) 
						{   
							pt1 = float2( fCurrentBound, fCurrHeight );
							pt2 = float2( fCurrentBound + fStepSize, fPrevHeight );
							nStepIndex = nNumSamples + 1;   //Exit loop
							fPrevHeight = fCurrHeight;
						}
						else
						{
							fPrevHeight = fCurrHeight;
						}
					}  
					float fDelta2 = pt2.x - pt2.y;
					float fDelta1 = pt1.x - pt1.y;  
					float fDenominator = fDelta2 - fDelta1;
					if ( fDenominator == 0.0f )
					{
						fParallaxAmount = 0.0f;
					}
					else
					{
						fParallaxAmount = (pt1.x * fDelta2 - pt2.x * fDelta1 ) / fDenominator;
					}
					IN.tex.xy -= vParallaxOffsetTS * (1 - fParallaxAmount );
					float3 lightDirection = normalize( _WorldSpaceLightPos0.xyz );
					float3 diffuseReflection =  _LightColor0.rgb * saturate( dot( normalDirection, lightDirection ) );
					float3 color = diffuseReflection +  UNITY_LIGHTMODEL_AMBIENT.rgb;
					float4 tex = tex2D( _MainTexture, IN.tex.xy );
					return float4( tex.xyz * color , 1.0);
				} 			
				ENDCG
			}
		}
	}