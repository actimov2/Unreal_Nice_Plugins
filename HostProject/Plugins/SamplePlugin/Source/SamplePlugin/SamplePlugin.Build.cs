// Copyright (c) 2026 actimov2. Licensed under MIT.

using UnrealBuildTool;

public class SamplePlugin : ModuleRules
{
	public SamplePlugin(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = ModuleRules.PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicIncludePaths.AddRange(new string[] { });
		PrivateIncludePaths.AddRange(new string[] { });

		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core"
		});

		PrivateDependencyModuleNames.AddRange(new string[]
		{
			"CoreUObject",
			"Engine",
			"Slate",
			"SlateCore",
			"UnrealEd",
			"ToolMenus",
			"InputCore",
			"EditorFramework",
			"Projects"
		});

		DynamicallyLoadedModuleNames.AddRange(new string[] { });
	}
}
