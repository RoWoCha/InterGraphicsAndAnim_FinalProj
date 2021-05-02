/// Script: PostProcessingCamera.cs
/// Brief: Uses postProcessing shader to update colours of camera texture
/// Author: Egor Fesenko
/// Date: 04/28/2021
/// Sources:
/// 1) https://www.youtube.com/watch?v=IRbWGI4Rqeo

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostProcessingCamera : MonoBehaviour
{
    public Material postProcessingMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, postProcessingMaterial);
    }
}
