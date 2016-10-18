using UnityEngine;
using System.Collections;

public class Take : MonoBehaviour {

	// Use this for initialization
	void Start () {
		GetComponent<Animation>().Play ();
	}
	
	// Update is called once per frame
	void Update () {
		if (!GetComponent<Animation>().IsPlaying("Take 001"))
		    GetComponent<Animation>().Play ();
	}
}
