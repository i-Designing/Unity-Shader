using UnityEngine;
using System.Collections;

namespace ShaderEffectUtility
{
    [ExecuteInEditMode]
    public class RTRL : MonoBehaviour
    {
        private static bool IsRendering = false;                                // 是否在渲染

        public bool IsDisablePixelLights = true;                                // 是否禁用像素光
        public LayerMask LayerMask = -1;                                        // 层遮罩
        public float ReflOffset = 0f;                                           // 反射偏移

        public bool BlurFlag = false;                                           // 模糊标识
        [Range(-4, 1)]
        public int BlurTextureSize = -1;                                        // 图像大小
        [Range(0, 10)]
        public int BlurSpread0 = 3;                                             // 扩展系数0
        [Range(0, 10)]
        public int BlurSpread1 = 1;                                             // 扩展系数1
        [Range(0, 10)]
        public int BlurIteration = 1;                                   // 迭代次数

        private Camera fMainCamera = null;                              // 主摄像机
        private Camera fRTCamera = null;                                // 渲染摄像机
        private Matrix4x4 fReflMatrix = Matrix4x4.zero;                 // 反射矩阵
        private Matrix4x4 fProjMatrix = Matrix4x4.zero;                 // 投影矩阵
        private RenderTexture fRT = null;                               // RenderTexture
        private int fRTWidth = 0;                                       // RenderTexture宽度
        private int fRTHeight = 0;                                      // RenderTexture高度
        public Shader fBlurShader = null;                               // 模糊Shader
        private Material fBlurMaterial = null;                          // 模糊材质

        private bool fOldBlurFlag = false;                              // 模糊标识
        private int fOldBlurTextureSize = 0;                            // 抓取图像大小
        //private int fOldBlurSpread0 =	0;								// 扩展系数0
        //private int fOldBlurSpread1 =	0;								// 扩展系数1
        //private int fOldBlurIteration	= 0;							// 迭代次数
        private int fOldScreenWidth = 0;                                // 屏幕宽度
        private int fOldScreenHeight = 0;                               // 屏幕高度

        void OnDisable()
        {
            if (this.fRT)
            {
                DestroyImmediate(this.fRT);
                this.fRT = null;
            }

            if (this.fRTCamera)
            {
                DestroyImmediate(this.fRTCamera);
                this.fRTCamera = null;
            }

            if (this.fBlurMaterial)
            {
                DestroyImmediate(this.fBlurMaterial);
                this.fBlurMaterial = null;
            }
        }

        public void OnWillRenderObject()
        {
            if (IsRendering)
            {
                return;
            }

            if (!this.enabled ||
               !GetComponent<Renderer>() ||
               !GetComponent<Renderer>().sharedMaterial)
            {
                return;
            }

            this.fMainCamera = Camera.current;
            if (!this.fMainCamera)
            {
                return;
            }

            IsRendering = true;

            int lOldPixelLightCount;
            lOldPixelLightCount = QualitySettings.pixelLightCount;
            if (IsDisablePixelLights)
            {
                QualitySettings.pixelLightCount = 0;
            }

            this.SetRT();
            this.GenRTCamera();
            this.SetRTCamera();

            Vector3 oPos;
            Vector3 oNormal;
            float oIntercept;
            Vector3 cPos;
            Vector3 cNormal;
            float cIntercept;
            Vector3 lOldPos;
            Vector3 lNewPos;

            oNormal = transform.up;
            oPos = transform.position + oNormal * this.ReflOffset;
            oIntercept = -Vector3.Dot(oNormal, oPos);

            this.CalReflMatrix(oNormal, oIntercept);
            lOldPos = this.fMainCamera.transform.position;
            lNewPos = this.fReflMatrix.MultiplyPoint(lOldPos);
            this.fRTCamera.worldToCameraMatrix = this.fMainCamera.worldToCameraMatrix * this.fReflMatrix;

            cPos = this.fRTCamera.worldToCameraMatrix.MultiplyPoint(oPos);
            cNormal = this.fRTCamera.worldToCameraMatrix.MultiplyVector(oNormal).normalized;
            cIntercept = -Vector3.Dot(cNormal, cPos);
            this.CalProjMatrix(cNormal, cIntercept);
            this.fRTCamera.projectionMatrix = this.fProjMatrix;

            GL.invertCulling = true;
            this.fRTCamera.targetTexture = this.fRT;
            this.fRTCamera.transform.position = lNewPos;
            this.fRTCamera.transform.eulerAngles = new Vector3(0, this.fMainCamera.transform.eulerAngles.x, this.fMainCamera.transform.eulerAngles.z);
            this.fRTCamera.Render();
            this.fRTCamera.transform.position = lOldPos;

            if (this.BlurFlag)
            {
                if (!this.fBlurMaterial)
                {
                    this.fBlurMaterial = new Material(this.fBlurShader);
                    this.fBlurMaterial.hideFlags = HideFlags.HideAndDontSave;
                }

                RenderTexture lRT0;
                RenderTexture lRT1;

                lRT0 = RenderTexture.GetTemporary(this.fRTWidth, this.fRTHeight, 16);
                lRT1 = RenderTexture.GetTemporary(this.fRTWidth, this.fRTHeight, 16);

                Graphics.Blit(this.fRT, lRT0);

                this.fBlurMaterial.SetVector("_Offset", new Vector4((float)this.BlurSpread0 / (float)this.fRTWidth, 0f, 0f, 0f));
                Graphics.Blit(lRT0, lRT1, this.fBlurMaterial);
                this.fBlurMaterial.SetVector("_Offset", new Vector4(0f, (float)this.BlurSpread0 / (float)this.fRTHeight, 0f, 0f));
                Graphics.Blit(lRT1, lRT0, this.fBlurMaterial);

                for (int i = 1; i <= this.BlurIteration; i++)
                {
                    this.fBlurMaterial.SetVector("_Offset", new Vector4((float)this.BlurSpread1 * (float)i / (float)this.fRTWidth, 0f, 0f, 0f));
                    Graphics.Blit(lRT0, lRT1, this.fBlurMaterial);
                    this.fBlurMaterial.SetVector("_Offset", new Vector4(0f, (float)this.BlurSpread1 * (float)i / (float)this.fRTHeight, 0f, 0f));
                    Graphics.Blit(lRT1, lRT0, this.fBlurMaterial);
                }

                Graphics.Blit(lRT0, this.fRT);

                RenderTexture.ReleaseTemporary(lRT1);
                RenderTexture.ReleaseTemporary(lRT0);
            }
            GL.invertCulling = false;

            Material[] materials = GetComponent<Renderer>().sharedMaterials;
            foreach (Material mat in materials)
            {
                if (mat.HasProperty("_ReflTexture"))
                {
                    mat.SetTexture("_ReflTexture", this.fRT);
                }
            }

            if (IsDisablePixelLights)
            {
                QualitySettings.pixelLightCount = lOldPixelLightCount;
            }
            IsRendering = false;
        }

        private void SetRT()
        {
            if (this.fRT &&
               this.fOldBlurFlag.Equals(this.BlurFlag) &&
               this.fOldBlurTextureSize.Equals(this.BlurTextureSize) &&
               this.fOldScreenWidth.Equals(Screen.width) &&
               this.fOldScreenHeight.Equals(Screen.height))
            {
                return;
            }

            if (fRT)
            {
                DestroyImmediate(this.fRT);
                this.fRT = null;
            }

            if (this.BlurTextureSize == 0)
            {
                this.fRTWidth = Screen.width;
                this.fRTHeight = Screen.height;
            }
            else if (this.BlurTextureSize == -2)
            {
                this.fRTWidth = Screen.width / 4;
                this.fRTHeight = Screen.height / 4;
            }
            else if (this.BlurTextureSize == -1)
            {
                this.fRTWidth = Screen.width / 2;
                this.fRTHeight = Screen.height / 2;
            }
            else if (this.BlurTextureSize == 1)
            {
                this.fRTWidth = Screen.width * 2;
                this.fRTHeight = Screen.height * 2;
            }
            else if (this.BlurTextureSize == -3)
            {
                this.fRTWidth = Screen.width / 8;
                this.fRTHeight = Screen.height / 8;
            }
            else
            {
                this.fRTWidth = Screen.width / 16;
                this.fRTHeight = Screen.height / 16;
            }

            if (!this.BlurFlag)
            {
                this.fRTWidth = Screen.width;
                this.fRTHeight = Screen.height;
            }

            this.fRT = new RenderTexture(this.fRTWidth, this.fRTHeight, 16);
            this.fRT.name = "RT_" + this.name;
            this.fRT.hideFlags = HideFlags.HideAndDontSave;

            this.fOldBlurFlag = this.BlurFlag;
            this.fOldBlurTextureSize = this.BlurTextureSize;
            this.fOldScreenWidth = Screen.width;
            this.fOldScreenHeight = Screen.height;
        }

        private void GenRTCamera()
        {
            if (this.fRTCamera)
            {
                return;
            }
            GameObject lGO;
            lGO = new GameObject();
            lGO.name = "RTCamera_" + this.name;
            lGO.hideFlags = HideFlags.HideAndDontSave;
            this.fRTCamera = lGO.AddComponent<Camera>();
            this.fRTCamera.enabled = false;
        }

        private void SetRTCamera()
        {
            if (!this.fRTCamera)
            {
                return;
            }

            this.fRTCamera.clearFlags = this.fMainCamera.clearFlags;
            this.fRTCamera.backgroundColor = this.fMainCamera.backgroundColor;
            this.fRTCamera.cullingMask = this.LayerMask.value;
            this.fRTCamera.orthographic = this.fMainCamera.orthographic;
            this.fRTCamera.fieldOfView = this.fMainCamera.fieldOfView;
            this.fRTCamera.orthographicSize = this.fMainCamera.orthographicSize;
            this.fRTCamera.nearClipPlane = this.fMainCamera.nearClipPlane;
            this.fRTCamera.farClipPlane = this.fMainCamera.farClipPlane;
            this.fRTCamera.depth = this.fMainCamera.depth - 1f;
            this.fRTCamera.renderingPath = this.fMainCamera.renderingPath;
            this.fRTCamera.useOcclusionCulling = this.fMainCamera.useOcclusionCulling;
            this.fRTCamera.hdr = this.fMainCamera.hdr;
        }

        private float Sign(float vValue)
        {
            if (vValue == 0)
            {
                return 0.0f;
            }
            if (vValue > 0)
            {
                return 1.0f;
            }
            return -1.0f;
        }

        private void CalProjMatrix(Vector3 vNormal, float vIntercept)
        {
            Vector4 lPlane;
            Vector4 lQ;
            Vector4 lC;

            this.fProjMatrix = this.fMainCamera.projectionMatrix;
            lPlane = new Vector4(vNormal.x, vNormal.y, vNormal.z, vIntercept);
            lQ = this.fMainCamera.projectionMatrix.inverse * new Vector4(this.Sign(lPlane.x), this.Sign(lPlane.y), 1.0f, 1.0f);
            lC = lPlane * (2.0F / (Vector4.Dot(lPlane, lQ)));
            this.fProjMatrix.SetRow(2, lC - this.fProjMatrix.GetRow(3));
        }

        private void CalReflMatrix(Vector3 vNormal, float vIntercept)
        {
            this.fReflMatrix.m00 = (1F - 2F * vNormal.x * vNormal.x);
            this.fReflMatrix.m01 = (-2F * vNormal.x * vNormal.y);
            this.fReflMatrix.m02 = (-2F * vNormal.x * vNormal.z);
            this.fReflMatrix.m03 = (-2F * vNormal.x * vIntercept);

            this.fReflMatrix.m10 = (-2F * vNormal.y * vNormal.x);
            this.fReflMatrix.m11 = (1F - 2F * vNormal.y * vNormal.y);
            this.fReflMatrix.m12 = (-2F * vNormal.y * vNormal.z);
            this.fReflMatrix.m13 = (-2F * vNormal.y * vIntercept);

            this.fReflMatrix.m20 = (-2F * vNormal.z * vNormal.x);
            this.fReflMatrix.m21 = (-2F * vNormal.z * vNormal.y);
            this.fReflMatrix.m22 = (1F - 2F * vNormal.z * vNormal.z);
            this.fReflMatrix.m23 = (-2F * vNormal.z * vIntercept);

            this.fReflMatrix.m30 = 0F;
            this.fReflMatrix.m31 = 0F;
            this.fReflMatrix.m32 = 0F;
            this.fReflMatrix.m33 = 1F;
        }
    }
}
