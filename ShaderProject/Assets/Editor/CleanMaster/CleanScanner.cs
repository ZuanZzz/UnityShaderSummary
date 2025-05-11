using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public static class CleanScanner
{
    private static readonly string[] validExtensions = new[] {
        ".png", ".jpg", ".jpeg", ".tga", ".psd",
        ".prefab", ".fbx", ".obj", ".mat", ".shader",
        ".mp3", ".wav", ".ogg", ".anim", ".controller",
        ".asset", ".unity"
    };

    public static List<string> ScanUnusedAssets()
    {
        // 获取所有资源
        string[] allAssets = AssetDatabase.FindAssets("");

        // 获取所有场景和预制体路径
        string[] scenePaths = AssetDatabase.FindAssets("t:Scene")
            .Select(AssetDatabase.GUIDToAssetPath).ToArray();
        string[] prefabPaths = AssetDatabase.FindAssets("t:Prefab")
            .Select(AssetDatabase.GUIDToAssetPath).ToArray();

        // 合并场景和预制体路径作为根资源
        string[] rootAssets = scenePaths.Concat(prefabPaths).ToArray();

        // 收集所有被使用的资源
        var usedAssets = new HashSet<string>();
        foreach (var rootAsset in rootAssets)
        {
            try
            {
                var deps = AssetDatabase.GetDependencies(rootAsset, true);
                foreach (var dep in deps)
                {
                    usedAssets.Add(dep);
                }
            }
            catch (System.Exception e)
            {
                Debug.LogError($"处理资源依赖时出错: {rootAsset}, 错误: {e.Message}");
            }
        }

        // 添加Resources文件夹中的资源（这些可能通过代码动态加载）
        string[] resourcesAssets = AssetDatabase.FindAssets("", new[] { "Assets/Resources" });
        foreach (var guid in resourcesAssets)
        {
            usedAssets.Add(AssetDatabase.GUIDToAssetPath(guid));
        }

        // 查找未使用的资源
        List<string> unused = new List<string>();
        foreach (var guid in allAssets)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);

            // 跳过文件夹和无效扩展
            if (AssetDatabase.IsValidFolder(path)) continue;
            string ext = Path.GetExtension(path).ToLower();
            if (!validExtensions.Contains(ext)) continue;

            // 跳过编辑器脚本
            if (path.Contains("/Editor/")) continue;

            if (!usedAssets.Contains(path))
                unused.Add(path);
        }

        return unused;
    }

    public static long GetFileSize(string path)
    {
        try
        {
            return new FileInfo(path).Length;
        }
        catch (System.Exception e)
        {
            Debug.LogError($"获取文件大小时出错: {path}, 错误: {e.Message}");
            return 0;
        }
    }

    public static string GetAssetType(string path)
    {
        try
        {
            var obj = AssetDatabase.LoadMainAssetAtPath(path);
            return obj != null ? obj.GetType().Name : "Unknown";
        }
        catch (System.Exception e)
        {
            Debug.LogError($"获取资源类型时出错: {path}, 错误: {e.Message}");
            return "Error";
        }
    }

    // 获取资源的依赖关系
    public static string[] GetDependencies(string path, bool recursive = true)
    {
        try
        {
            return AssetDatabase.GetDependencies(path, recursive);
        }
        catch (System.Exception e)
        {
            Debug.LogError($"获取依赖关系时出错: {path}, 错误: {e.Message}");
            return new string[0];
        }
    }
}
