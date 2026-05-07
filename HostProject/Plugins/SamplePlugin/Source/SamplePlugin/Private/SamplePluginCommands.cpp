// Copyright (c) 2026 actimov2. Licensed under MIT.

#include "SamplePluginCommands.h"

#define LOCTEXT_NAMESPACE "FSamplePluginModule"

void FSamplePluginCommands::RegisterCommands()
{
	UI_COMMAND(
		SayHelloCommand,
		"Say Hello",
		"Click to say hello — proof that the plugin is loaded and working.",
		EUserInterfaceActionType::Button,
		FInputChord());
}

#undef LOCTEXT_NAMESPACE
