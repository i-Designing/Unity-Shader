using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Game
{
    /// <summary>
    /// Initializes and Updates the plane shadow material if neccessary.
    /// </summary>

    public class UpdateShadowMaterial : MonoBehaviour
    {
        /// <summary>
        /// The layer mask where to find the floor.
        /// </summary>
        //public int LayerMask = 1 << 15;
        public LayerMask floorMask;

        /// <summary>
        /// A bias value where to start the raycast to find the floor
        /// </summary>
        public float ShadowBias = 1.5f;


        private GameObject Floor_;

        /// <summary>
        /// The current floor detected by the raycast, is used to detect if the floor changed.
        /// </summary>
        public GameObject Floor
        {
            get
            {
                return Floor_;
            }
        }

        /// <summary>
        /// If AutoUpdateFloor is false the script will just calculate and update the shadow material once and then destroys itself.
        /// If true it will constantly shot a ray and if ground changed will update the shadow material
        /// </summary>
        public bool AutoUpdateFloor = false;

        /// <summary>
        /// Indicates if the shadow should be calculated using all submeshes, if not it will just use the first subMesh.
        /// </summary>
        public bool IncludeAllSubMeshes = false;

        /// <summary>
        /// Sets the light which should be used for the light calculation.
        /// </summary>
        private Light LightObject_;
        public Light LightObject
        {
            get
            {
                if (LightObject_ == null)
                {
                    LightObject_ = FindLight();
                }
                return LightObject_;
            }

            set
            {
                LightObject_ = value;
            }
        }

        /// <summary>
        /// Internal storage for the current shadowmatrix
        /// </summary>
        private Matrix4x4 shadowMatrix;

        /// <summary>
        /// Returns the renderComponent of this gameObject
        /// </summary>
        private Renderer RenderComponent_;
        Renderer RenderComponent
        {
            get
            {
                if (null == RenderComponent_)
                {
                    RenderComponent_ = gameObject.GetComponent<Renderer>();
                }
                return RenderComponent_;
            }
        }

        // internal
        private Vector3 FloorNormal_;
        private Vector3 FloorPoint_;
        private bool FloorDirty_ = false;

        /// <summary>
        /// Gets or sets the floor normal used for the calculation of the shadow matrix.
        /// </summary>
        /// <value>The floor normal.</value>
        public Vector3 FloorNormal
        {
            set
            {
                FloorNormal_ = value;
                FloorDirty_ = true;
            }

            get
            {
                return FloorNormal_;
            }
        }

        /// <summary>
        /// Gets or sets the floor point used for the calculation of the shadow matrix.
        /// </summary>
        /// <value>The floor point.</value>
        public Vector3 FloorPoint
        {
            set
            {
                FloorPoint_ = value;
                FloorDirty_ = true;
            }

            get
            {
                return FloorPoint_;
            }
        }

        // Update is called once per frame
        void LateUpdate()
        {
            if (AutoUpdateFloor || !Floor)
            {
                CheckFloor();
            }

            if (FloorDirty_)
            {
                UpdateShadowMatrix();
            }

            if (!AutoUpdateFloor && Floor)
            {
                Destroy(this);
            }
        }

        // Use this for initialization
        void Start()
        {
            AddShadowMaterialToList();
            UpdateShadowMatrix();
        }

        /// <summary>
        /// Updates the shadow matrix and uploads the result to the material.
        /// </summary>
        void UpdateShadowMatrix()
        {
            LightObject.shadows = LightShadows.None;

            calculateShadowMatrix(LightObject, FloorPoint_, FloorNormal_);
            RenderComponent_.sharedMaterials[0].SetMatrix("worldToShadow", shadowMatrix);
        }


        /// <summary>
        /// Adds the shadow material to material list. SubMeshes will be reconfigured so that each subMeshIndex is increased by one.
        /// Tht is done, because shadow material must be the first submesh.
        /// </summary>
        void AddShadowMaterialToList()
        {
            Material SharedShadowMaterial = Resources.Load<Material>("Materials/PlaneShadow");
            Shader ShadowPlaneShader = SharedShadowMaterial.shader;

            if (RenderComponent.sharedMaterials[0] &&
                RenderComponent.sharedMaterials[0].shader.Equals(ShadowPlaneShader))
            {
                return;
            }

            MeshFilter mf = gameObject.GetComponent<MeshFilter>();

            if (null != mf && mf.mesh.subMeshCount > 1)
            {
                Mesh mesh = mf.mesh;
                mesh.subMeshCount++;

                List<int> triangles = new List<int>();
                List<int> indices = new List<int>();

                MeshTopology mt = MeshTopology.Triangles;

                for (int j = mesh.subMeshCount - 2; j >= 0; --j)
                {
                    if (j == 0)
                    {
                        mt = mf.mesh.GetTopology(j);
                    }
                    else
                    {
                        if (mt != mf.mesh.GetTopology(j))
                        {
                            Debug.LogError("Inconsitent Mesh Topology");
                        }
                    }
                    int[] subMesh = mf.sharedMesh.GetTriangles(j);
                    int[] subIndices = mf.sharedMesh.GetIndices(j);
                    triangles.AddRange(subMesh);
                    indices.AddRange(subIndices);
                    mesh.SetTriangles(subMesh, j + 1);
                    mesh.SetIndices(subIndices, mt, j + 1);
                }

                if (IncludeAllSubMeshes)
                {
                    mesh.SetTriangles(triangles.ToArray(), 0);
                    mesh.SetIndices(indices.ToArray(), mt, 0);
                }

                mf.mesh = mesh;
            }

            Material[] newList = new Material[RenderComponent.sharedMaterials.Length + 1];

            newList[0] = new Material(SharedShadowMaterial);
            for (int i = 1; i < newList.Length; ++i)
            {
                newList[i] = RenderComponent_.sharedMaterials[i - 1];
            }
            RenderComponent_.sharedMaterials = newList;
        }

        /// <summary>
        /// Returns the direction of the light used for the raycast when trying to detect the floor.
        /// </summary>
        /// <returns>The light dir_.</returns>
        Vector3 GetLightDir_()
        {
            if (!LightObject) 
                return Vector3.down;

            Vector4 lightPos;

            if (LightObject.type == LightType.Directional)
            {
                lightPos = LightObject.transform.TransformDirection(Vector3.back);
                lightPos.w = 0.0f;
                return -Vector3.Normalize(lightPos);
            }
            else
            {
                lightPos = LightObject.transform.position;
                Vector3 tmp = transform.position - new Vector3(lightPos.x, lightPos.y, lightPos.z);
                return Vector3.Normalize(tmp);
                //lightPos.w = 1.0f;
            }
        }

        /// <summary>
        ///  returns the first directional light
        /// </summary>
        /// <returns>The light.</returns>
        Light FindLight()
        {
            //Light[] lights = Light.GetLights(LightType.Directional, ~0x0);
            Light[] lights = FindObjectsOfType(typeof(Light)) as Light[];

            foreach (Light light in lights)
            {
                if (light.type == LightType.Directional)
                {
                    Debug.Log("Light Found:" + light.name);
                    return light;
                }
            }
            Debug.LogError("LightObject is null");
            return null;
        }

        /// <summary>
        /// Using a raycast from the direction of the light to detect the floor.
        /// </summary>
        void CheckFloor()
        {
            Vector3 lightDir = GetLightDir_();
            RaycastHit hit;
            Vector3 objectPosition = transform.position + Vector3.up * ShadowBias;

            if (Physics.Raycast(objectPosition, lightDir, out hit, Mathf.Infinity, floorMask.value))
            {
                //Debug.DrawLine(hit.point, hit.point+ hit.normal * 3.0f, Color.cyan);
                //Debug.DrawLine(hit.point, objectPosition, Color.red);
                if (Floor_ != hit.collider.gameObject)
                {
                    Floor_ = hit.collider.gameObject;
                }

                FloorNormal = hit.normal;
                FloorPoint = hit.point;
                //Debug.Log ("Found Surface at " + hit.ToString() );
                //Debug.Log ("Shadow Matrix is now :\n\r" + shadowMatrix.ToString());
            }
            else
            {
                Debug.Log("Error: could not find the surface");
                calculateShadowMatrix(LightObject, Vector3.zero, Vector3.up);
            }
        }


        /// <summary>
        /// Actual function to calculate the shadow matrix used in the material.
        /// A shadow matrix is a transform matrix to transform worldSpace vertices to shadowSpace (plane projection) on floor.
        /// </summary>
        /// <param name="theLight">The light.</param>
        /// <param name="point">Point.</param>
        /// <param name="normal">Normal.</param>
        void calculateShadowMatrix(Light theLight, Vector3 point, Vector3 normal)
        {
            Vector3 L, n, E;
            float c, d;

            switch (theLight.type)
            {
                case LightType.Point:
                    // Calculate the projection matrix
                    // Let L be the position of the light
                    // P the position of a vertex of the object we want to shadow
                    // E a point of the plane (not seen in the figure)
                    // n the normal vector of the plane

                    L = theLight.transform.position;
                    n = -normal;
                    E = point;

                    d = Vector3.Dot(L, n);
                    c = Vector3.Dot(E, n) - d;

                    shadowMatrix[0, 0] = L.x * n.x + c;
                    shadowMatrix[1, 0] = L.y * n.x;
                    shadowMatrix[2, 0] = L.z * n.x;
                    shadowMatrix[3, 0] = n.x;

                    shadowMatrix[0, 1] = L.x * n.y;
                    shadowMatrix[1, 1] = L.y * n.y + c;
                    shadowMatrix[2, 1] = L.z * n.y;
                    shadowMatrix[3, 1] = n.y;

                    shadowMatrix[0, 2] = L.x * n.z;
                    shadowMatrix[1, 2] = L.y * n.z;
                    shadowMatrix[2, 2] = L.z * n.z + c;
                    shadowMatrix[3, 2] = n.z;

                    shadowMatrix[0, 3] = -L.x * (c + d);
                    shadowMatrix[1, 3] = -L.y * (c + d);
                    shadowMatrix[2, 3] = -L.z * (c + d);
                    shadowMatrix[3, 3] = -d;
                    break;

                case LightType.Spot:
                    goto case LightType.Directional;

                case LightType.Directional:
                    // Calculate the projection matrix
                    // Let L be the direction of the light
                    // P the position of a vertex of the object we want to shadow
                    // E a point of the plane (not seen in the figure)
                    // n the normal vector of the plane

                    L = theLight.transform.forward;
                    n = -normal;
                    E = point;

                    d = Vector3.Dot(L, n);
                    c = Vector3.Dot(E, n);

                    /*
                     [d - n.x * L.x,  -n.y * L.x,     -n.z * L.x,     c * L.x]
                     [-n.x * L.y,     d - n.y * L.y,  -n.z * L.y,     c * L.y]
                     [-n.x * L.z,     -n.y * L.z,     d - n.z * L.z,  c * L.z]
                     [0,              0,              0,              d      ]
                     */

                    shadowMatrix[0, 0] = d - n.x * L.x;
                    shadowMatrix[1, 0] = -n.x * L.y;
                    shadowMatrix[2, 0] = -n.x * L.z;
                    shadowMatrix[3, 0] = 0;

                    shadowMatrix[0, 1] = -n.y * L.x;
                    shadowMatrix[1, 1] = d - n.y * L.y;
                    shadowMatrix[2, 1] = -n.y * L.z;
                    shadowMatrix[3, 1] = 0;

                    shadowMatrix[0, 2] = -n.z * L.x;
                    shadowMatrix[1, 2] = -n.z * L.y;
                    shadowMatrix[2, 2] = d - n.z * L.z;
                    shadowMatrix[3, 2] = 0;

                    shadowMatrix[0, 3] = c * L.x;
                    shadowMatrix[1, 3] = c * L.y;
                    shadowMatrix[2, 3] = c * L.z;
                    shadowMatrix[3, 3] = d;
                    break;
            }
        }
    }
}
