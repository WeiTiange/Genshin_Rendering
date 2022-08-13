// Written By 框Ko
// email:  formatt@foxmail.com
// 基于对 https://zhuanlan.zhihu.com/p/109101851中的改进
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.IO;


public enum WRITETYPE
{
    VertexColor = 0,
    Tangent = 1,
    // Texter=2,
}
public class SmoothNormalTools : EditorWindow
{

    public WRITETYPE wt;
    // public bool customMesh;

    [MenuItem("Tools/平滑法线工具")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(SmoothNormalTools));//显示现有窗口实例。如果没有，请创建一个。
    }


    void OnGUI()
    {

        GUILayout.Space(5);
        GUILayout.Label("1、请在Scene中选择需要平滑法线的物体", EditorStyles.boldLabel);
        // mesh = (MeshFilter)EditorGUILayout.ObjectField(mesh,typeof(MeshFilter),true);
        GUILayout.Space(10);
        GUILayout.Label("2、请选择需要写入平滑后的物体空间法线数据的目标", EditorStyles.boldLabel);
        wt = (WRITETYPE)EditorGUILayout.EnumPopup("写入目标", wt);
        GUILayout.Space(10);



        switch (wt)
        {
            case WRITETYPE.Tangent://执行写入到 顶点切线
                GUILayout.Label("  将会把平滑后的法线写入到顶点切线中", EditorStyles.boldLabel);
                break;
            case WRITETYPE.VertexColor:// 写入到顶点色
                GUILayout.Label("  将会把平滑后的法线写入到顶点色的RGB中，A保持不变", EditorStyles.boldLabel);
                break;
                // case WRITETYPE.Texter://写入到自定义贴图
                //             GUILayout.Label ("  写入贴图的相关设置：", EditorStyles.boldLabel);
                // break;
        }
        if (GUILayout.Button("3、平滑法线(预览效果）"))
        {//执行平滑
            SmoothNormalPrev(wt);
        }

        GUILayout.Label("之后可能会报Null Reference错误，");
        GUILayout.Label("需要导出Mesh并在MeshFilter中覆盖，这样才能永久保存");
        GUILayout.Space(10);
        GUILayout.Label("  会将mesh保存到Assets/SmoothNormalTools/下", EditorStyles.boldLabel);
        GUILayout.Space(5);
        // customMesh = EditorGUILayout.BeginToggleGroup ("Optional Settings", customMesh);
        // EditorGUILayout.EndToggleGroup ();
        if (GUILayout.Button("4、导出Mesh"))
        {
            selectMesh();
        }

    }
    public void SmoothNormalPrev(WRITETYPE wt)//Mesh选择器 修改并预览
    {


        if (Selection.activeGameObject == null)
        {//检测是否获取到物体
            Debug.LogError("请选择物体");
            return;
        }
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var meshFilter in meshFilters)//遍历两种Mesh 调用平滑法线方法
        {
            Mesh mesh = meshFilter.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            write2mesh(mesh, averageNormals);
        }
        foreach (var skinMeshRender in skinMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            write2mesh(mesh, averageNormals);
        }
    }

    public Vector3[] AverageNormal(Mesh mesh)
    {

        var averageNormalHash = new Dictionary<Vector3, Vector3>();
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
            {
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] =
                    (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
            }
        }

        var averageNormals = new Vector3[mesh.vertexCount];
        for (var j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
            // averageNormals[j] = averageNormals[j].normalized;
        }

        return averageNormals;

    }

    public void write2mesh(Mesh mesh, Vector3[] averageNormals)
    {
        switch (wt)
        {
            case WRITETYPE.Tangent://执行写入到 顶点切线
                var tangents = new Vector4[mesh.vertexCount];
                for (var j = 0; j < mesh.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh.tangents = tangents;
                break;
            case WRITETYPE.VertexColor:// 写入到顶点色
                Color[] _colors = new Color[mesh.vertexCount];
                Color[] _colors2 = new Color[mesh.vertexCount];
                _colors2 = mesh.colors;
                for (var j = 0; j < mesh.vertexCount; j++)
                {
                    _colors[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, _colors2[j].a);
                }
                mesh.colors = _colors;
                break;
        }
    }

    public void selectMesh()
    {

        if (Selection.activeGameObject == null)
        {//检测是否获取到物体
            Debug.LogError("请选择物体");
            return;
        }
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var meshFilter in meshFilters)//遍历两种Mesh 调用平滑法线方法
        {
            Mesh mesh = meshFilter.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            exportMesh(mesh, averageNormals);

        }
        foreach (var skinMeshRender in skinMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            exportMesh(mesh, averageNormals);
        }
    }



    public void Copy(Mesh dest, Mesh src)
    {
        dest.Clear();
        dest.vertices = src.vertices;

        List<Vector4> uvs = new List<Vector4>();

        src.GetUVs(0, uvs); dest.SetUVs(0, uvs);
        src.GetUVs(1, uvs); dest.SetUVs(1, uvs);
        src.GetUVs(2, uvs); dest.SetUVs(2, uvs);
        src.GetUVs(3, uvs); dest.SetUVs(3, uvs);

        dest.normals = src.normals;
        dest.tangents = src.tangents;
        dest.boneWeights = src.boneWeights;
        dest.colors = src.colors;
        dest.colors32 = src.colors32;
        dest.bindposes = src.bindposes;

        dest.subMeshCount = src.subMeshCount;

        for (int i = 0; i < src.subMeshCount; i++)
            dest.SetIndices(src.GetIndices(i), src.GetTopology(i), i);

        dest.name = src.name;
    }
    public void exportMesh(Mesh mesh, Vector3[] averageNormals)
    {
        Mesh mesh2 = new Mesh();
        Copy(mesh2, mesh);
        switch (wt)
        {
            case WRITETYPE.Tangent://执行写入到 顶点切线
                Debug.Log("写入到切线中");
                var tangents = new Vector4[mesh2.vertexCount];
                for (var j = 0; j < mesh2.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh2.tangents = tangents;
                break;
            case WRITETYPE.VertexColor:// 写入到顶点色
                Debug.Log("写入到顶点色中");
                Color[] _colors = new Color[mesh2.vertexCount];
                Color[] _colors2 = new Color[mesh2.vertexCount];
                _colors2 = mesh2.colors;
                for (var j = 0; j < mesh2.vertexCount; j++)
                {
                    _colors[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, _colors2[j].a);
                }
                mesh2.colors = _colors;
                break;
        }

        //创建文件夹路径
        string DeletePath = Application.dataPath + "/SmoothNormalTools";
        Debug.Log(DeletePath);
        //判断文件夹路径是否存在
        if (!Directory.Exists(DeletePath))
        {  //创建
            Directory.CreateDirectory(DeletePath);
        }
        //刷新
        AssetDatabase.Refresh();


        mesh2.name = mesh2.name + "_SMNormal";
        Debug.Log(mesh2.vertexCount);
        AssetDatabase.CreateAsset(mesh2, "Assets/SmoothNormalTools/" + mesh2.name + ".asset");

    }
}