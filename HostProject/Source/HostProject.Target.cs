// Copyright (c) 2026 actimov2. Licensed under MIT.

using UnrealBuildTool;
using System.Collections.Generic;

public class HostProjectTarget : TargetRules
{
	public HostProjectTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Latest;
		ExtraModuleNames.Add("HostProject");
	}
}
