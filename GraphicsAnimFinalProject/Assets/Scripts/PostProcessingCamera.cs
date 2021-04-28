using System.Collections;
using System.Collections.Generic;
using UnityEngine;

// Informations sources:
// 1) https://www.youtube.com/watch?v=IRbWGI4Rqeo

[ExecuteInEditMode]
public class PostProcessingCamera : MonoBehaviour
{
    public Material postProcessingMaterial;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, postProcessingMaterial);
    }
}
