// Copyright (c) 2026 actimov2. Licensed under MIT.

using UnrealBuildTool;
using System.Collections.Generic;

public class HostProjectEditorTarget : TargetRules
{
	public HostProjectEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("HostProject");
	}
}
