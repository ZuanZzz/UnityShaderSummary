using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public class CleanerWindow : EditorWindow
{
    private List<string> unusedAssets = new List<string>();
    private Vector2 scrollPos;
    private bool showDependencies = false;
    private string selectedAsset = "";
    private Dictionary<string, bool> assetFoldouts = new Dictionary<string, bool>();
    private bool isScanning = false;

    [MenuItem("Tools/Clean Master")]
    public static void ShowWindow()
    {
        GetWindow<CleanerWindow>("Clean Master");
    }

    private void OnGUI()
    {
        GUILayout.Label("🎯 未使用资源扫描器", EditorStyles.boldLabel);
        GUILayout.Space(10);

        EditorGUI.BeginDisabledGroup(isScanning);
        if (GUILayout.Button("开始扫描未使用资源"))
        {
            StartScan();
        }
        EditorGUI.EndDisabledGroup();

        GUILayout.Space(10);

        if (isScanning)
        {
            EditorGUILayout.HelpBox("正在扫描中，请稍候...", MessageType.Info);
            Repaint();
        }
        else if (unusedAssets.Count > 0)
        {
            DrawUnusedAssetsList();
            DrawExportOptions();
        }
    }

    private void StartScan()
    {
        isScanning = true;
        EditorApplication.delayCall += () =>
        {
            try
            {
                unusedAssets.Clear(); // 清空上一次的结果
                unusedAssets = CleanScanner.ScanUnusedAssets();
                Debug.Log($"共找到 {unusedAssets.Count} 个未使用资源");
            }
            catch (System.Exception e)
            {
                Debug.LogError($"扫描过程中出错: {e.Message}\n{e.StackTrace}");
            }
            finally
            {
                isScanning = false;
                Repaint();
            }
        };
    }

    private void DrawUnusedAssetsList()
    {
        GUILayout.Label($"未使用资源列表（共 {unusedAssets.Count} 个）", EditorStyles.boldLabel);

        // 添加搜索框
        GUILayout.BeginHorizontal();
        GUILayout.Label("搜索:", GUILayout.Width(50));
        GUI.SetNextControlName("SearchField");
        string searchText = EditorGUILayout.TextField(GUI.GetNameOfFocusedControl() == "SearchField" ? "" : "输入资源名称...");
        GUILayout.EndHorizontal();

        scrollPos = EditorGUILayout.BeginScrollView(scrollPos, GUILayout.Height(300));

        long totalSize = 0;
        var filteredAssets = unusedAssets;

        // 如果有搜索文本，过滤资源
        if (!string.IsNullOrEmpty(searchText) && searchText != "输入资源名称...")
        {
            filteredAssets = unusedAssets.Where(a => Path.GetFileName(a).ToLower().Contains(searchText.ToLower())).ToList();
        }

        foreach (var asset in filteredAssets)
        {
            var type = CleanScanner.GetAssetType(asset);
            var size = CleanScanner.GetFileSize(asset);
            totalSize += size;

            // 确保字典中有这个资产的条目
            if (!assetFoldouts.ContainsKey(asset))
            {
                assetFoldouts[asset] = false;
            }

            GUILayout.BeginHorizontal();

            // 显示折叠箭头
            assetFoldouts[asset] = EditorGUILayout.Foldout(assetFoldouts[asset], "", true);

            // 显示资源信息
            if (GUILayout.Button($"{Path.GetFileName(asset)} - {type} - {size / 1024f:F1} KB", EditorStyles.label))
            {
                // 选择并高亮资源
                Selection.activeObject = AssetDatabase.LoadMainAssetAtPath(asset);
                EditorGUIUtility.PingObject(Selection.activeObject);
                selectedAsset = asset;
            }

            // 添加删除按钮
            if (GUILayout.Button("删除", GUILayout.Width(50)))
            {
                if (EditorUtility.DisplayDialog("确认删除", $"确定要删除资源 {Path.GetFileName(asset)} 吗？", "确定", "取消"))
                {
                    AssetDatabase.DeleteAsset(asset);
                    unusedAssets.Remove(asset);
                    GUIUtility.ExitGUI();
                }
            }

            GUILayout.EndHorizontal();

            // 如果折叠框展开，显示依赖关系
            if (assetFoldouts[asset])
            {
                EditorGUI.indentLevel++;

                EditorGUILayout.LabelField("资源路径:", asset);

                var dependencies = CleanScanner.GetDependencies(asset, false);
                if (dependencies.Length > 0)
                {
                    EditorGUILayout.LabelField("直接依赖:", EditorStyles.boldLabel);
                    foreach (var dep in dependencies)
                    {
                        if (dep != asset) // 不显示自身
                        {
                            EditorGUILayout.BeginHorizontal();
                            GUILayout.Space(20);
                            if (GUILayout.Button(Path.GetFileName(dep), EditorStyles.label))
                            {
                                Selection.activeObject = AssetDatabase.LoadMainAssetAtPath(dep);
                                EditorGUIUtility.PingObject(Selection.activeObject);
                            }
                            EditorGUILayout.EndHorizontal();
                        }
                    }
                }
                else
                {
                    EditorGUILayout.LabelField("没有依赖其他资源");
                }

                EditorGUI.indentLevel--;
            }
        }

        EditorGUILayout.EndScrollView();

        EditorGUILayout.LabelField($"总大小: {totalSize / (1024f * 1024f):F2} MB");
    }

    private void DrawExportOptions()
    {
        GUILayout.Space(10);

        GUILayout.BeginHorizontal();
        if (GUILayout.Button("导出.unitypackage（保留原结构）"))
        {
            ExportUnusedAssets(unusedAssets);
        }

        if (GUILayout.Button("移动到 Assets/Unused 并导出.unitypackage"))
        {
            MoveAssetsToUnusedFolder(unusedAssets);
            ExportUnusedAssets(new List<string> { "Assets/Unused" });
        }
        GUILayout.EndHorizontal();

        if (GUILayout.Button("全部删除未使用资源"))
        {
            if (EditorUtility.DisplayDialog("确认删除", $"确定要删除所有 {unusedAssets.Count} 个未使用资源吗？此操作不可撤销！", "确定", "取消"))
            {
                DeleteUnusedAssets();
            }
        }
    }

    private void ExportUnusedAssets(List<string> assetPaths)
    {
        try
        {
            string exportPath = EditorUtility.SaveFilePanel("导出未使用资源包", "", "UnusedAssets.unitypackage", "unitypackage");
            if (!string.IsNullOrEmpty(exportPath))
            {
                AssetDatabase.ExportPackage(assetPaths.ToArray(), exportPath, ExportPackageOptions.Interactive | ExportPackageOptions.Recurse);
                Debug.Log("导出完成: " + exportPath);
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"导出资源时出错: {e.Message}");
            EditorUtility.DisplayDialog("导出错误", $"导出资源时出错: {e.Message}", "确定");
        }
    }

    private void MoveAssetsToUnusedFolder(List<string> assets)
    {
        try
        {
            if (!AssetDatabase.IsValidFolder("Assets/Unused"))
            {
                AssetDatabase.CreateFolder("Assets", "Unused");
            }

            foreach (var asset in assets)
            {
                string fileName = Path.GetFileName(asset);
                string baseName = Path.GetFileNameWithoutExtension(asset);
                string extension = Path.GetExtension(asset);
                string newPath = $"Assets/Unused/{fileName}";

                // 处理文件名冲突
                int counter = 1;
                while (File.Exists(newPath))
                {
                    newPath = $"Assets/Unused/{baseName}_{counter}{extension}";
                    counter++;
                }

                var error = AssetDatabase.MoveAsset(asset, newPath);
                if (!string.IsNullOrEmpty(error))
                {
                    Debug.LogWarning($"移动失败：{asset} → {newPath}，原因：{error}");
                }
            }

            AssetDatabase.Refresh();
            Debug.Log("移动完成，已放入 Assets/Unused");
        }
        catch (System.Exception e)
        {
            Debug.LogError($"移动资源时出错: {e.Message}");
            EditorUtility.DisplayDialog("移动错误", $"移动资源时出错: {e.Message}", "确定");
        }
    }

    private void DeleteUnusedAssets()
    {
        int count = 0;
        List<string> failedAssets = new List<string>();

        foreach (var asset in unusedAssets.ToArray())
        {
            try
            {
                if (AssetDatabase.DeleteAsset(asset))
                {
                    count++;
                    unusedAssets.Remove(asset);
                }
                else
                {
                    failedAssets.Add(asset);
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError($"删除资源时出错: {asset}, 错误: {e.Message}");
                failedAssets.Add(asset);
            }
        }

        AssetDatabase.Refresh();

        if (failedAssets.Count > 0)
        {
            Debug.LogWarning($"有 {failedAssets.Count} 个资源删除失败");
            foreach (var asset in failedAssets)
            {
                Debug.LogWarning($"删除失败: {asset}");
            }
        }

        Debug.Log($"成功删除 {count} 个未使用资源");
    }
}
