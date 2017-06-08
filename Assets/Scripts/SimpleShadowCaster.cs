using UnityEngine;
using System.Collections;

namespace ShaderUtility
{
    public class SimpleShadowCaster : MonoBehaviour
    {
        //接受阴影的物体 测试的时候可以放这个脚本的物体本身  
        //如果是测试平面投影，这个地方应该放作为被投影物体地面  
        public Transform target;

        void Update()
        {
            GetComponent<Renderer>().sharedMaterial.SetMatrix("_World2Local", target.GetComponent<Renderer>().worldToLocalMatrix);
            GetComponent<Renderer>().sharedMaterial.SetMatrix("_Local2World", target.GetComponent<Renderer>().localToWorldMatrix);
        }  
    }
}
